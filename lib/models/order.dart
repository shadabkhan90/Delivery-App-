/// Model for Order details
class Order {
  final String id;
  final String restaurantName;
  final double restaurantLat;
  final double restaurantLng;
  final String customerName;
  final double customerLat;
  final double customerLng;
  final double amount;

  Order({
    required this.id,
    required this.restaurantName,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.customerName,
    required this.customerLat,
    required this.customerLng,
    required this.amount,
  });
}
