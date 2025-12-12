// lib/data/models/appointment.dart

class Appointment {
  final String id;
  final String spaceName;
  final String date;       // 格式: yyyy-MM-dd
  final String beginTime;  // 格式: HH:mm
  final String endTime;    // 格式: HH:mm
  final int auditStatus;   // 2-待签到/已签到, 3-已取消, 4-已完成
  final bool sign;         // true-已签到
  final String floor;
  final String campusNumber;
  
  // 构造函数
  const Appointment({
    required this.id,
    required this.spaceName,
    required this.date,
    required this.beginTime,
    required this.endTime,
    required this.auditStatus,
    required this.sign,
    this.floor = '',
    this.campusNumber = '',
  });

  // 工厂方法：从 JSON 创建对象
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      spaceName: json['spaceName']?.toString() ?? '未知座位',
      date: json['date']?.toString() ?? '',
      beginTime: json['beginTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      auditStatus: json['auditStatus'] is int 
          ? json['auditStatus'] 
          : int.tryParse(json['auditStatus']?.toString() ?? '0') ?? 0,
      sign: json['sign'] == true || json['sign'] == 'true', // 兼容布尔和字符串
      floor: json['floor']?.toString() ?? '',
      campusNumber: json['campusNumber']?.toString() ?? '',
    );
  }

  /// 是否可以签到
  bool get canSignIn {
    if (auditStatus != 2 || sign) return false;

    try {
      final now = DateTime.now();
      // 解析日期和时间
      final startDateTime = _parseDateTime(date, beginTime);
      final endDateTime = _parseDateTime(date, endTime);
      
      // 签到时间窗口：开始前15分钟 到 结束时间之前
      final checkInStart = startDateTime.subtract(const Duration(minutes: 15));

      return now.isAfter(checkInStart) && now.isBefore(endDateTime);
    } catch (e) {
      return false;
    }
  }

  /// 是否是即将开始的预约
  bool get isUpcoming {
    if (auditStatus != 2) return false;
    try {
      final now = DateTime.now();
      final startDateTime = _parseDateTime(date, beginTime);
      final checkInStart = startDateTime.subtract(const Duration(minutes: 15));
      return now.isBefore(checkInStart);
    } catch (e) {
      return false;
    }
  }

  /// 是否已过期（未签到且时间已过）
  bool get isExpired {
    if (auditStatus != 2 || sign) return false;
    try {
      final now = DateTime.now();
      final endDateTime = _parseDateTime(date, endTime);
      return now.isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  /// 获取状态显示的文本
  String get statusText {
    if (auditStatus == 3) return '已取消';
    if (auditStatus == 4) return '已完成';
    
    if (auditStatus == 2) {
      if (sign) return '已签到';
      if (isUpcoming) return '未开始';
      if (isExpired) return '未签到'; // 或者叫“已违约”
      return '待签到';
    }
    
    return '未知状态';
  }

  // 辅助函数：解析时间字符串
  DateTime _parseDateTime(String dateStr, String timeStr) {
    String cleanTime = timeStr.length == 5 ? '$timeStr:00' : timeStr;
    return DateTime.parse('$dateStr $cleanTime');
  }
}