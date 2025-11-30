class Stats {
  final double totalRevenue;
  final int totalBookings;
  final double occupancyPercent; // 0..100
  final List<int> last7Days; // e.g. bookings per day

  Stats({
    required this.totalRevenue,
    required this.totalBookings,
    required this.occupancyPercent,
    required this.last7Days,
  }) : assert(last7Days.length == 7, 'last7Days must contain 7 entries');

  Stats copyWith({
    double? totalRevenue,
    int? totalBookings,
    double? occupancyPercent,
    List<int>? last7Days,
  }) {
    return Stats(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalBookings: totalBookings ?? this.totalBookings,
      occupancyPercent: occupancyPercent ?? this.occupancyPercent,
      last7Days: last7Days ?? this.last7Days,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRevenue': totalRevenue,
      'totalBookings': totalBookings,
      'occupancyPercent': occupancyPercent,
      'last7Days': last7Days,
    };
  }

  factory Stats.fromMap(Map<String, dynamic> map) {
    return Stats(
      totalRevenue: (map['totalRevenue'] as num).toDouble(),
      totalBookings: map['totalBookings'] as int,
      occupancyPercent: (map['occupancyPercent'] as num).toDouble(),
      last7Days: List<int>.from(map['last7Days'] as List),
    );
  }

  @override
  String toString() => 'Stats(revenue: $totalRevenue, bookings: $totalBookings, occupancy: $occupancyPercent)';
}
