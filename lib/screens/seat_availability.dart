import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/seat_time.dart';
import '../data/services/api_service.dart';
import '../utils/seat_mapping.dart';
import '../utils/date_utils.dart';

class SeatAvailabilityScreen extends StatefulWidget {
  const SeatAvailabilityScreen({super.key});

  @override
  State<SeatAvailabilityScreen> createState() => _SeatAvailabilityScreenState();
}

class _SeatAvailabilityScreenState extends State<SeatAvailabilityScreen> {
  late List<DateTime> _dates;
  late DateTime _selectedDate;

  String? _selectedSpaceId;
  SeatTimeStatus? _seatTimeStatus;
  bool _isLoading = false;
  String? _error;

  // 座位搜索
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dates = AppDateUtils.getFutureDates(7);
    _selectedDate = _dates.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 搜索座位
  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {});
      return;
    }

    // 这里可以从 SeatMapping 中查找座位
    // 简化实现：直接尝试转换座位名称到座位 ID
    try {
      final spaceId = SeatMapping.convertSeatNameToId(query);
      setState(() {
        _selectedSpaceId = spaceId;
      });
    } catch (e) {
      setState(() {});
    }
  }

  // 获取座位预约情况
  Future<void> _fetchSeatAvailability() async {
    if (_selectedSpaceId == null || _selectedSpaceId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择座位')));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await ApiService().querySpaceAppointTime(
        spaceId: _selectedSpaceId!,
        date: AppDateUtils.formatDate(_selectedDate),
      );

      if (mounted) {
        setState(() {
          _seatTimeStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取座位预约情况失败: $_error')));
      }
    }
  }

  // 获取时间段的颜色
  Color _getTimeSlotColor(TimeSlot slot) {
    if (slot.occupy == 1) {
      // 已占用 - 灰色
      return Colors.grey.shade300;
    } else if (slot.isChecked) {
      // 未来时段但已被预约
      return Colors.orange.shade200;
    } else {
      // 可用 - 绿色
      return Colors.green.shade100;
    }
  }

  Color _getTimeSlotTextColor(TimeSlot slot) {
    if (slot.occupy == 1) {
      return Colors.grey;
    } else if (slot.isChecked) {
      return Colors.orange.shade800;
    } else {
      return Colors.green.shade800;
    }
  }

  String _getTimeSlotStatus(TimeSlot slot) {
    if (slot.occupy == 1) {
      return '使用中';
    } else if (slot.isChecked) {
      return '已预约';
    } else {
      return '可用';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('查看座位预约情况')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 座位搜索框
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '输入座位号 (如: 422, 549)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _handleSearch,
                onSubmitted: (_) => _fetchSeatAvailability(),
              ),
              const SizedBox(height: 16),

              // 日期选择
              if (_selectedSpaceId != null && _selectedSpaceId!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择查询日期',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final date = _dates[index];
                          final isSelected =
                              date.day == _selectedDate.day &&
                              date.month == _selectedDate.month &&
                              date.year == _selectedDate.year;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = date);
                              _fetchSeatAvailability();
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEE', 'zh_CN').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // 加载状态
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // 错误信息
              if (_error != null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // 时间段列表
              if (_seatTimeStatus != null && !_isLoading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '可用',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '已预约',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '使用中',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: _seatTimeStatus!.timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _seatTimeStatus!.timeSlots[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: _getTimeSlotColor(slot),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slot.timeText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _getTimeSlotTextColor(slot),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTimeSlotStatus(slot),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getTimeSlotTextColor(slot),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

              if (_seatTimeStatus == null &&
                  !_isLoading &&
                  _selectedSpaceId != null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '点击"查询"按钮获取座位信息',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _selectedSpaceId != null &&
              _selectedSpaceId!.isNotEmpty &&
              !_isLoading
          ? FloatingActionButton(
              onPressed: _fetchSeatAvailability,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
