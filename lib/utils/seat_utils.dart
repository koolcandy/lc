enum SpaceStatus {
  available(0),
  occupied(1);

  final int value;
  const SpaceStatus(this.value);
  
  static SpaceStatus fromValue(int value) {
    return value == 1 ? occupied : available;
  }
}

class SeatArea {
  final int start;
  final int end;
  final String name;
  final String type;

  const SeatArea(this.start, this.end, this.name, this.type);
}

class SeatUtils {
  static const double seatItemHeight = 64.0;
  static const double sectionHeaderHeight = 46.0;

  static const List<SeatArea> seatAreaCharts = [
    SeatArea(1, 204, 'J区', '多人座'),
    SeatArea(205, 268, 'A区', '单人座'),
    SeatArea(269, 368, 'B区', '单人座'),
    SeatArea(369, 416, 'D区', '单人座'),
    SeatArea(417, 476, 'C区', '单人座'),
    SeatArea(477, 616, 'I区', '多人座'),
    SeatArea(617, 640, 'F区', '沙发座'),
    SeatArea(641, 736, 'H区', '多人座、沙发座'),
    SeatArea(737, 758, 'G区', '多人座'),
    SeatArea(759, 804, 'E区', '多人座'),
    SeatArea(805, 837, 'K区', '多人座'),
    SeatArea(838, 870, 'L区', '多人座'),
    SeatArea(871, 919, 'M区', '多人座'),
  ];

  static String convertSpaceName(String spaceName) {
    final int? spaceNumber = int.tryParse(spaceName);
    if (spaceNumber == null) return spaceName;

    if (spaceNumber >= 205 && spaceNumber <= 476) {
      return '$spaceName\n单人座';
    } else if (spaceNumber >= 617 && spaceNumber <= 620) {
      return '$spaceName\n沙发 #1';
    } else if (spaceNumber >= 621 && spaceNumber <= 624) {
      return '$spaceName\n沙发 #2';
    } else if (spaceNumber >= 625 && spaceNumber <= 628) {
      return '$spaceName\n沙发 #3';
    } else if (spaceNumber >= 629 && spaceNumber <= 632) {
      return '$spaceName\n沙发 #4';
    } else if (spaceNumber >= 633 && spaceNumber <= 636) {
      return '$spaceName\n沙发 #5';
    } else if (spaceNumber >= 637 && spaceNumber <= 640) {
      return '$spaceName\n沙发 #6';
    } else if (spaceNumber >= 641 && spaceNumber <= 646) {
      return '$spaceName\n沙发 #7';
    } else if (spaceNumber >= 647 && spaceNumber <= 652) {
      return '$spaceName\n沙发 #8';
    } else if (spaceNumber >= 653 && spaceNumber <= 658) {
      return '$spaceName\n沙发 #9';
    } else if (spaceNumber >= 659 && spaceNumber <= 664) {
      return '$spaceName\n沙发 #10';
    }
    
    return spaceName;
  }

  static String getSpaceArea(String spaceName) {
    final mainNumberStr = spaceName.split('-')[0];
    final int? spaceNumber = int.tryParse(mainNumberStr);
    
    if (spaceNumber == null) return '其他';

    try {
      final area = seatAreaCharts.firstWhere(
        (area) => spaceNumber >= area.start && spaceNumber <= area.end,
      );
      return area.name;
    } catch (e) {
      return '其他';
    }
  }
}