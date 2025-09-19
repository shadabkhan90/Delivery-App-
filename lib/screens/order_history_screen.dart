import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_repository.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<OrderRepository>();
    final orders = repo.deliveredOrders;
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: orders.isEmpty
          ? const Center(child: Text('No delivered orders yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      'Order ${o.id} - ₹${o.amount.toStringAsFixed(2)}',
                    ),
                    subtitle: Text('${o.restaurantName} → ${o.customerName}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: orders.length,
            ),
    );
  }
}
