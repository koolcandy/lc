import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/seat_status.dart';
import '../data/services/api_service.dart';
import '../utils/seat_utils.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String date;
  final String beginTime;
  final String endTime;

  const SeatSelectionScreen({
    super.key,
    required this.date,
    required this.beginTime,
    required this.endTime,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  late List<_SeatGroup> _seatGroups;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _seatGroups = [];
    _fetchSeats();
  }

  Future<void> _fetchSeats() async {
    try {
      final seats = await ApiService().querySeatStatus(
        date: widget.date,
        beginTime: widget.beginTime,
        endTime: widget.endTime,
        floor: '', // 查询所有楼层
      );

      setState(() {
        _seatGroups = _groupSeats(_applySeatAnomalies(seats));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 分组逻辑 - 返回不可变的列表
  List<_SeatGroup> _groupSeats(List<SeatStatus> seats) {
    final Map<String, List<SeatStatus>> grouped = {};

    // 初始化 SeatUtils 定义的所有区域
    for (var area in SeatUtils.seatAreaCharts) {
      grouped[area.name] = [];
    }
    grouped['其他'] = [];

    for (var seat in seats) {
      final areaName = SeatUtils.getSpaceArea(seat.spaceName);
      if (grouped.containsKey(areaName)) {
        grouped[areaName]!.add(seat);
      } else {
        grouped['其他']!.add(seat);
      }
    }

    // 对每个分组内的座位排序：空闲优先，其次按自然字符串顺序
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        // 空闲(0)优先，其次占用
        final statusCmp = (a.status == 0 ? 0 : 1).compareTo(
          b.status == 0 ? 0 : 1,
        );
        if (statusCmp != 0) return statusCmp;
        return _naturalCompare(a.spaceName, b.spaceName);
      });
    }

    // 按区域定义的顺序输出分组，"其他"置于最后；排除空分组
    final List<String> areaOrder = [
      ...SeatUtils.seatAreaCharts.map((e) => e.name),
      '其他',
    ];

    final List<_SeatGroup> result = [];
    for (final areaName in areaOrder) {
      final seatsInGroup = grouped[areaName];
      if (seatsInGroup != null && seatsInGroup.isNotEmpty) {
        result.add(
          _SeatGroup(name: areaName, seats: List.unmodifiable(seatsInGroup)),
        );
      }
    }

    return result;
  }

  // 处理异常座位：
  // - 过滤不可预约的 045-1/045-2/108-1/108-2
  // - 仅保留 796-1 与 799-1，直接忽略 797 与 800
  List<SeatStatus> _applySeatAnomalies(List<SeatStatus> seats) {
    const Set<String> toIgnore = {
      '045-1',
      '045-2',
      '108-1',
      '108-2',
      '797',
      '800',
    };

    // 过滤不可预约与需要忽略的座位，仅保留 796-1 与 799-1（还有其他正常座位）
    return seats.where((s) => !toIgnore.contains(s.spaceName)).toList();
  }

  // 自然字符串比较（数字序列按数值比较，非数字按字母比较）
  int _naturalCompare(String a, String b) {
    final ra = _tokenize(a);
    final rb = _tokenize(b);
    final len = ra.length < rb.length ? ra.length : rb.length;
    for (var i = 0; i < len; i++) {
      final ta = ra[i];
      final tb = rb[i];
      final isNumA = _isNumeric(ta);
      final isNumB = _isNumeric(tb);
      if (isNumA && isNumB) {
        final na = int.parse(ta);
        final nb = int.parse(tb);
        final cmp = na.compareTo(nb);
        if (cmp != 0) return cmp;
      } else {
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;
      }
    }
    return ra.length.compareTo(rb.length);
  }

  List<String> _tokenize(String s) {
    final List<String> tokens = [];
    final buffer = StringBuffer();
    bool? lastIsDigit;
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final isDigit =
          c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57; // '0'..'9'
      if (lastIsDigit == null) {
        buffer.write(c);
        lastIsDigit = isDigit;
      } else if (lastIsDigit == isDigit) {
        buffer.write(c);
      } else {
        tokens.add(buffer.toString());
        buffer.clear();
        buffer.write(c);
        lastIsDigit = isDigit;
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  bool _isNumeric(String s) {
    if (s.isEmpty) return false;
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
      if (!isDigit) return false;
    }
    return true;
  }

  Future<void> _handleSeatClick(SeatStatus seat) async {
    if (seat.status != 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该座位已被占用')));
      // TODO: 这里可以拓展：点击已占用座位显示具体占用时间段 (SeatTimeStatus)
      return;
    }

    // 弹出确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认预约'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日期: ${widget.date}'),
            Text('时间: ${widget.beginTime} - ${widget.endTime}'),
            const SizedBox(height: 8),
            Text(
              '座位: ${seat.spaceName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认预约'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _makeAppointment(seat);
    }
  }

  Future<void> _makeAppointment(SeatStatus seat) async {
    try {
      // 显示 loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService().makeAppointment(
        spaceName: seat.spaceName,
        date: widget.date,
        beginTime: widget.beginTime,
        endTime: widget.endTime,
      );

      // 关闭 loading
      if (mounted) Navigator.pop(context);

      // 成功提示并返回首页
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('预约成功！'), backgroundColor: Colors.green),
        );
        context.go('/'); // 回到首页
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // 关闭 loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '预约失败: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 需要调用父类的 build

    return Scaffold(
      appBar: AppBar(title: const Text('选择座位')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : CustomScrollView(
              slivers: [
                for (final group in _seatGroups) ...[
                  // 区域标题 - 使用 SliverToBoxAdapter
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.grey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '空闲 ${group.available} / 总计 ${group.total}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 座位网格 - 使用 SliverGrid 实现懒加载
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 1.0,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SeatItemWidget(
                          seat: group.seats[index],
                          onTap: _handleSeatClick,
                        ),
                        childCount: group.seats.length,
                      ),
                    ),
                  ),
                ],
                // 底部间距
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
    );
  }
}

/// 座位分组数据模型 - 不可变的数据结构
class _SeatGroup {
  final String name;
  final List<SeatStatus> seats;

  _SeatGroup({required this.name, required this.seats});

  int get available => seats.where((s) => s.status == 0).length;
  int get total => seats.length;
}

/// 单个座位 UI 组件 - 使用 RepaintBoundary 隔离重绘
class _SeatItemWidget extends StatelessWidget {
  final SeatStatus seat;
  final Function(SeatStatus) onTap;

  const _SeatItemWidget({required this.seat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = seat.status == 0;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(seat),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isAvailable ? Colors.white : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAvailable ? Colors.green : Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  seat.spaceName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.black87 : Colors.red.shade300,
                  ),
                ),
                if (!isAvailable)
                  const Text(
                    '占用',
                    style: TextStyle(fontSize: 10, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// （已不再需要显示代理，因 797/800 直接忽略）
