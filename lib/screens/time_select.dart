import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';

class TimeSelectScreen extends StatefulWidget {
  const TimeSelectScreen({super.key});

  @override
  State<TimeSelectScreen> createState() => _TimeSelectScreenState();
}

class _TimeSelectScreenState extends State<TimeSelectScreen> {
  late List<DateTime> _dates;
  late List<String> _timeSlots;
  late DateTime _selectedDate;
  
  String? _beginTime;
  String? _endTime;

  @override
  void initState() {
    super.initState();
    _dates = AppDateUtils.getFutureDates(7);
    _selectedDate = _dates.first;
    _timeSlots = AppDateUtils.generateTimeSlots();
  }

  // 核心逻辑：处理时间点击
  void _handleTimeSelection(String time) {
    if (AppDateUtils.isTimePast(_selectedDate, time)) return;

    // 检查是否超过4小时限制 (如果已经选了开始时间)
    if (_beginTime != null && _endTime == null) {
       final diff = AppDateUtils.calculateHoursDifference(_beginTime!, time);
       if (diff > 4) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('不能预约超过4小时')));
         return;
       }
    }

    setState(() {
      if (_beginTime == null && _endTime == null) {
        _beginTime = time;
      } else if (_beginTime != null && _endTime == null) {
        if (time.compareTo(_beginTime!) < 0) {
          // 点了比开始时间更早的 -> 变成新的开始时间
          _beginTime = time;
        } else if (time.compareTo(_beginTime!) > 0) {
          // 点了比开始时间晚的 -> 变成结束时间
          _endTime = time;
        } else {
          // 点了同一个 -> 取消
          _beginTime = null;
        }
      } else {
        // 都有了 -> 重置，重新选开始
        _beginTime = time;
        _endTime = null;
      }
    });
  }

  // 获取单个时间块的状态颜色
  Color _getTimeCardColor(String time) {
    final isPast = AppDateUtils.isTimePast(_selectedDate, time);
    if (isPast) return Colors.grey.shade300;

    final isSelected = time == _beginTime || time == _endTime;
    if (isSelected) return Theme.of(context).primaryColor;

    if (_beginTime != null && _endTime != null) {
      if (time.compareTo(_beginTime!) > 0 && time.compareTo(_endTime!) < 0) {
        return Theme.of(context).primaryColor.withOpacity(0.2); // 中间段
      }
    }

    return Colors.white; // 默认
  }
  
  // 文字颜色
  Color _getTimeTextColor(String time) {
    final isPast = AppDateUtils.isTimePast(_selectedDate, time);
    if (isPast) return Colors.grey;
    final isSelected = time == _beginTime || time == _endTime;
    return isSelected ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择时间段')),
      body: Column(
        children: [
          // 1. 日期选择横向列表
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = date == _selectedDate;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _beginTime = null;
                      _endTime = null;
                    });
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE', 'zh_CN').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("请选择起止时间 (最大4小时)", style: TextStyle(color: Colors.grey)),
          ),

          // 2. 时间网格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.0, // 宽是高的2倍
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final time = _timeSlots[index];
                return GestureDetector(
                  onTap: () => _handleTimeSelection(time),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getTimeCardColor(time),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTimeCardColor(time) == Colors.white 
                            ? Colors.grey.shade300 
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: _getTimeTextColor(time),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 底部栏
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('yyyy年MM月dd日').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _beginTime != null && _endTime != null 
                              ? "$_beginTime - $_endTime"
                              : "请选择时间段",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (_beginTime != null && _endTime != null) 
                        ? () {
                            // 导航到选座页，传递参数
                            context.push(
                              '/available_seats',
                              extra: {
                                'date': AppDateUtils.formatDate(_selectedDate),
                                'beginTime': _beginTime,
                                'endTime': _endTime,
                              }
                            );
                          } 
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('下一步'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}