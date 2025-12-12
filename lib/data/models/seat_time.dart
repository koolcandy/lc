class TimeSlot {
  final int index;
  final String timeText; // 例如 "08:00"
  final int occupy; // 0: 未占用, 1: 已占用
  final bool isChecked; // true: 已预约, false: 未预约

  const TimeSlot({
    required this.index,
    required this.timeText,
    required this.occupy,
    this.isChecked = false,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      index: json['index'] ?? 0,
      timeText: json['timeText'] ?? '',
      occupy: json['occupy'] ?? 0,
      isChecked: json['isChecked'] ?? false,
    );
  }

  bool get isAvailable => occupy == 0;
}

class SeatTimeStatus {
  final int spaceId;
  final String date;
  final List<TimeSlot> timeSlots;

  const SeatTimeStatus({
    required this.spaceId,
    required this.date,
    required this.timeSlots,
  });

  factory SeatTimeStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final list = data['timeDiamondList'] as List? ?? [];

    return SeatTimeStatus(
      spaceId: data['spaceId'] ?? 0,
      date: data['date'] ?? '',
      timeSlots: list.map((e) => TimeSlot.fromJson(e)).toList(),
    );
  }
}
