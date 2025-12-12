class SeatStatus {
  final int id;
  final String spaceName;
  final int status; // 0: 空闲, 1: 预约中, 2: 使用中
  final String floor;

  const SeatStatus({
    required this.id,
    required this.spaceName,
    required this.status,
    required this.floor,
  });

  factory SeatStatus.fromJson(Map<String, dynamic> json) {
    return SeatStatus(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      spaceName: json['spaceName']?.toString() ?? '',
      status: json['spaceStatus'] is int 
          ? json['spaceStatus'] 
          : int.tryParse(json['spaceStatus']?.toString() ?? '0') ?? 0,
      floor: json['floor']?.toString() ?? '',
    );
  }
  
  // 辅助 getter，方便 UI 使用
  bool get isAvailable => status == 0;
  bool get isOccupied => status != 0;
}