class Booking {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final String status; // e.g. pending, confirmed, cancelled
  final double price;
  final String location;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.status,
    required this.price,
    required this.location,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? date,
    String? status,
    double? price,
    String? location,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      status: status ?? this.status,
      price: price ?? this.price,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'date': date.toIso8601String(),
      'status': status,
      'price': price,
      'location': location,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      price: (map['price'] as num).toDouble(),
      location: map['location'] as String,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, userName: $userName, date: $date, status: $status, price: $price, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
