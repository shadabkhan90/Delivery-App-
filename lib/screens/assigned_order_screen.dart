import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/distance_utils.dart';
import '../services/order_repository.dart';

enum TripState {
  notStarted,
  started,
  arrivedRestaurant,
  pickedUp,
  arrivedCustomer,
  delivered,
}

class AssignedOrderScreen extends StatefulWidget {
  final Order order;
  const AssignedOrderScreen({super.key, required this.order});

  @override
  State<AssignedOrderScreen> createState() => _AssignedOrderScreenState();
}

class _AssignedOrderScreenState extends State<AssignedOrderScreen> {
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  TripState _state = TripState.notStarted;
  double? _distanceToRestaurant;
  double? _distanceToCustomer;
  Timer? _tenSecondTicker;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final ok = await _locationService.ensurePermission();
    if (!ok) return;

    _positionSub = _locationService.getPositionStream().listen((pos) {
      setState(() {
        _currentPosition = pos;
        _distanceToRestaurant = DistanceUtils.distanceMeters(
          startLat: pos.latitude,
          startLng: pos.longitude,
          endLat: widget.order.restaurantLat,
          endLng: widget.order.restaurantLng,
        );
        _distanceToCustomer = DistanceUtils.distanceMeters(
          startLat: pos.latitude,
          startLng: pos.longitude,
          endLat: widget.order.customerLat,
          endLng: widget.order.customerLng,
        );
      });
    });

    // Console updates ticker (bonus)
    _tenSecondTicker = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_currentPosition != null) {
        final p = _currentPosition!;
        // ignore: avoid_print
        print('[SendToServer] lat=${p.latitude}, lng=${p.longitude}');
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _tenSecondTicker?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  String _stateLabel(TripState s) {
    switch (s) {
      case TripState.notStarted:
        return 'Not Started';
      case TripState.started:
        return 'On the way to Restaurant';
      case TripState.arrivedRestaurant:
        return 'At Restaurant';
      case TripState.pickedUp:
        return 'Picked Up';
      case TripState.arrivedCustomer:
        return 'At Customer';
      case TripState.delivered:
        return 'Delivered';
    }
  }

  Future<void> _navigateTo(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _startTrip() {
    setState(() {
      _state = TripState.started;
    });
  }

  void _arrivedAtRestaurant() {
    if (_currentPosition == null) return;
    final within = DistanceUtils.isWithinRadius(
      currentLat: _currentPosition!.latitude,
      currentLng: _currentPosition!.longitude,
      targetLat: widget.order.restaurantLat,
      targetLng: widget.order.restaurantLng,
      radiusMeters: 50,
    );
    if (within) {
      setState(() {
        _state = TripState.arrivedRestaurant;
      });
    } else {
      _showSnack(
        'You are ${_distanceToRestaurant?.toStringAsFixed(0) ?? '?'} m away from restaurant',
      );
    }
  }

  void _pickedUp() {
    if (_state == TripState.arrivedRestaurant) {
      setState(() {
        _state = TripState.pickedUp;
      });
      _showSnack('Order ${widget.order.id}: picked up');
    }
  }

  void _arrivedAtCustomer() {
    if (_currentPosition == null) return;
    final within = DistanceUtils.isWithinRadius(
      currentLat: _currentPosition!.latitude,
      currentLng: _currentPosition!.longitude,
      targetLat: widget.order.customerLat,
      targetLng: widget.order.customerLng,
      radiusMeters: 50,
    );
    if (within) {
      setState(() {
        _state = TripState.arrivedCustomer;
      });
    } else {
      _showSnack(
        'You are ${_distanceToCustomer?.toStringAsFixed(0) ?? '?'} m away from customer',
      );
    }
  }

  void _delivered() {
    if (_state == TripState.arrivedCustomer) {
      setState(() {
        _state = TripState.delivered;
      });
      final repo = context.read<OrderRepository>();
      repo.addDelivered(widget.order);
      _showSnack('Order ${widget.order.id} delivered!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  VoidCallback? _nextActionForState() {
    switch (_state) {
      case TripState.notStarted:
        return _startTrip;
      case TripState.started:
        return _arrivedAtRestaurant;
      case TripState.arrivedRestaurant:
        return _pickedUp;
      case TripState.pickedUp:
        return _arrivedAtCustomer;
      case TripState.arrivedCustomer:
        return _delivered;
      case TripState.delivered:
        return null;
    }
  }

  String _nextLabel() {
    switch (_state) {
      case TripState.notStarted:
        return 'Start Trip';
      case TripState.started:
        return 'Arrived at Restaurant';
      case TripState.arrivedRestaurant:
        return 'Picked Up';
      case TripState.pickedUp:
        return 'Arrived at Customer';
      case TripState.arrivedCustomer:
        return 'Delivered';
      case TripState.delivered:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Order'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      floatingActionButton: _state == TripState.delivered
          ? null
          : FloatingActionButton.extended(
              onPressed: _nextActionForState(),
              icon: const Icon(Icons.arrow_forward),
              label: Text(_nextLabel()),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Order ${order.id}'),
                subtitle: Text('Amount: ₹${order.amount.toStringAsFixed(2)}'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text(order.restaurantName),
                    subtitle: Text(
                      '(${order.restaurantLat}, ${order.restaurantLng})',
                    ),
                    trailing: TextButton(
                      onPressed: () => _navigateTo(
                        order.restaurantLat,
                        order.restaurantLng,
                        order.restaurantName,
                      ),
                      child: const Text('Navigate'),
                    ),
                  ),
                  if (_distanceToRestaurant != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.social_distance, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Distance: ${_distanceToRestaurant!.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_pin_circle),
                    title: Text(order.customerName),
                    subtitle: Text(
                      '(${order.customerLat}, ${order.customerLng})',
                    ),
                    trailing: TextButton(
                      onPressed: () => _navigateTo(
                        order.customerLat,
                        order.customerLng,
                        order.customerName,
                      ),
                      child: const Text('Navigate'),
                    ),
                  ),
                  if (_distanceToCustomer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.social_distance, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Distance: ${_distanceToCustomer!.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text(
                    '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                  ),
                  subtitle: Text('State: ${_stateLabel(_state)}'),
                ),
              )
            else
              const ListTile(
                leading: Icon(Icons.my_location),
                title: Text('Fetching location...'),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StepChip(
                  label: 'Start',
                  active: _state.index >= TripState.started.index,
                ),
                _StepChip(
                  label: 'At Rest.',
                  active: _state.index >= TripState.arrivedRestaurant.index,
                ),
                _StepChip(
                  label: 'Picked',
                  active: _state.index >= TripState.pickedUp.index,
                ),
                _StepChip(
                  label: 'At Cust.',
                  active: _state.index >= TripState.arrivedCustomer.index,
                ),
                _StepChip(
                  label: 'Done',
                  active: _state.index >= TripState.delivered.index,
                ),
              ],
            ),
            const SizedBox(height: 72),
            if (_state == TripState.delivered)
              Center(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  child: const Text('View History'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool active;
  const _StepChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: active
          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
          : null,
      side: active
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}
