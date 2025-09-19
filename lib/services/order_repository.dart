import 'package:flutter/foundation.dart';
import '../models/order.dart';

/// Simple in-memory repository to store delivered orders for current app session.
class OrderRepository extends ChangeNotifier {
  final List<Order> _delivered = <Order>[];

  List<Order> get deliveredOrders => List.unmodifiable(_delivered);

  void addDelivered(Order order) {
    _delivered.add(order);
    notifyListeners();
  }
}
