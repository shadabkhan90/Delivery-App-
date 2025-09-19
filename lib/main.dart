import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/assigned_order_screen.dart';
import 'screens/order_history_screen.dart';
import 'models/order.dart';
import 'services/order_repository.dart';

void main() {
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderRepository(),
      child: MaterialApp(
        title: 'Driver App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/order': (context) => AssignedOrderScreen(
            order: Order(
              id: 'ORD123',
              restaurantName: 'Pizza Palace',
              restaurantLat: 28.6139,
              restaurantLng: 77.2090,
              customerName: 'John Doe',
              customerLat: 28.6200,
              customerLng: 77.2200,
              amount: 499.0,
            ),
          ),
          '/history': (context) => const OrderHistoryScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
