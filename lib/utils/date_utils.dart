import 'package:intl/intl.dart';

class AppDateUtils {
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';

  /// 获取未来几天的日期列表
  static List<DateTime> getFutureDates(int days) {
    final now = DateTime.now();
    // 如果当前时间超过 22:00，从明天开始算
    final startDate = now.hour >= 22 ? now.add(const Duration(days: 1)) : now;
    
    return List.generate(days, (index) {
      return startDate.add(Duration(days: index));
    });
  }

  /// 生成时间段 (08:00 - 22:30)
  static List<String> generateTimeSlots() {
    final slots = <String>[];
    int hour = 8;
    int minute = 0;

    while (hour < 23 || (hour == 22 && minute == 30)) {
      final h = hour.toString().padLeft(2, '0');
      final m = minute.toString().padLeft(2, '0');
      slots.add('$h:$m');

      minute += 30;
      if (minute == 60) {
        hour += 1;
        minute = 0;
      }
    }
    return slots;
  }

  /// 计算两个时间字符串 (HH:mm) 的小时差
  static double calculateHoursDifference(String start, String end) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day, 
      int.parse(start.split(':')[0]), int.parse(start.split(':')[1]));
    final endDate = DateTime(now.year, now.month, now.day, 
      int.parse(end.split(':')[0]), int.parse(end.split(':')[1]));
      
    return endDate.difference(startDate).inMinutes / 60.0;
  }

  /// 检查时间是否已过去
  static bool isTimePast(DateTime selectedDate, String timeStr) {
    final now = DateTime.now();
    // 比较日期
    final isToday = selectedDate.year == now.year && 
                    selectedDate.month == now.month && 
                    selectedDate.day == now.day;
    
    if (!isToday) return false;

    // 如果是今天，比较时间
    final currentMinutes = now.hour * 60 + now.minute;
    final targetParts = timeStr.split(':');
    final targetMinutes = int.parse(targetParts[0]) * 60 + int.parse(targetParts[1]);

    // 原逻辑：时间过去了吗？保留一点缓冲？这里严格比较
    return currentMinutes > targetMinutes;
  }

  static String formatDate(DateTime date, [String? pattern]) {
    return DateFormat(pattern ?? dateFormat, 'zh_CN').format(date);
  }
}