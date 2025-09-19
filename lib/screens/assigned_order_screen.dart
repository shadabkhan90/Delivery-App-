import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/distance_utils.dart';
import '../services/order_repository.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ok = await _locationService.ensurePermission();
      if (!ok) {
        setState(() {
          _errorMessage = AppConstants.locationPermissionDenied;
          _isLoading = false;
        });
        return;
      }

      _positionSub = _locationService.getPositionStream().listen(
        (pos) {
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
            _isLoading = false;
            _errorMessage = null;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Location error: ${error.toString()}';
            _isLoading = false;
          });
        },
      );

      _tenSecondTicker = Timer.periodic(AppConstants.locationUpdateInterval, (
        _,
      ) async {
        if (_currentPosition != null) {
          final p = _currentPosition!;
          final timestamp = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(DateTime.now());
          // ignore: avoid_print
          print(
            '[LocationUpdate $timestamp] lat=${p.latitude.toStringAsFixed(5)}, lng=${p.longitude.toStringAsFixed(5)}, acc=${p.accuracy.toStringAsFixed(1)}m',
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize location: ${e.toString()}';
        _isLoading = false;
      });
    }
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

  Future<void> _startTrip() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _state = TripState.started;
        _isLoading = false;
      });
      _showSnack('Trip started! Navigate to restaurant.', isSuccess: true);
    }
  }

  Future<void> _arrivedAtRestaurant() async {
    if (_currentPosition == null) {
      _showSnack('Location not available. Please wait...', isError: true);
      return;
    }

    final within = DistanceUtils.isWithinRadius(
      currentLat: _currentPosition!.latitude,
      currentLng: _currentPosition!.longitude,
      targetLat: widget.order.restaurantLat,
      targetLng: widget.order.restaurantLng,
      radiusMeters: AppConstants.geofenceRadiusMeters,
    );

    if (within) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _state = TripState.arrivedRestaurant;
          _isLoading = false;
        });
        _showSnack(
          'Arrived at restaurant! Please collect the order.',
          isSuccess: true,
        );
      }
    } else {
      _showSnack(
        'You are ${_distanceToRestaurant?.toStringAsFixed(0) ?? '?'}m away from restaurant. Please get closer.',
        isError: true,
      );
    }
  }

  Future<void> _pickedUp() async {
    if (_state == TripState.arrivedRestaurant) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _state = TripState.pickedUp;
          _isLoading = false;
        });
        _showSnack(
          'Order ${widget.order.id} picked up! Navigate to customer.',
          isSuccess: true,
        );
      }
    }
  }

  Future<void> _arrivedAtCustomer() async {
    if (_currentPosition == null) {
      _showSnack('Location not available. Please wait...', isError: true);
      return;
    }

    final within = DistanceUtils.isWithinRadius(
      currentLat: _currentPosition!.latitude,
      currentLng: _currentPosition!.longitude,
      targetLat: widget.order.customerLat,
      targetLng: widget.order.customerLng,
      radiusMeters: AppConstants.geofenceRadiusMeters,
    );

    if (within) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _state = TripState.arrivedCustomer;
          _isLoading = false;
        });
        _showSnack(
          'Arrived at customer location! Please deliver the order.',
          isSuccess: true,
        );
      }
    } else {
      _showSnack(
        'You are ${_distanceToCustomer?.toStringAsFixed(0) ?? '?'}m away from customer. Please get closer.',
        isError: true,
      );
    }
  }

  Future<void> _delivered() async {
    if (_state == TripState.arrivedCustomer) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _state = TripState.delivered;
          _isLoading = false;
        });

        final repo = context.read<OrderRepository>();
        repo.addDelivered(widget.order);
        _showSnack(
          'Order ${widget.order.id} delivered successfully! 🎉',
          isSuccess: true,
        );
      }
    }
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isSuccess)
              const Icon(Icons.check_circle, color: Colors.white, size: 20)
            else if (isError)
              const Icon(Icons.error, color: Colors.white, size: 20)
            else
              const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : isError
            ? AppTheme.errorColor
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        margin: const EdgeInsets.all(AppTheme.defaultPadding),
      ),
    );
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.id}'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history),
            tooltip: 'Order History',
          ),
        ],
      ),
      floatingActionButton: _state == TripState.delivered
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : _nextActionForState(),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(_nextLabel()),
            ),
      body: _errorMessage != null
          ? _buildErrorState(context)
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  _buildOrderSummaryCard(context, order)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.1, end: 0),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Progress Indicator
                  _buildProgressIndicator(context)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Restaurant Card
                  _buildLocationCard(
                        context,
                        icon: Icons.restaurant,
                        title: order.restaurantName,
                        subtitle: 'Restaurant',
                        coordinates:
                            '${order.restaurantLat.toStringAsFixed(5)}, ${order.restaurantLng.toStringAsFixed(5)}',
                        distance: _distanceToRestaurant,
                        onNavigate: () => _navigateTo(
                          order.restaurantLat,
                          order.restaurantLng,
                          order.restaurantName,
                        ),
                        isActive: _state.index >= TripState.started.index,
                      )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: isTablet ? 16 : 12),

                  // Customer Card
                  _buildLocationCard(
                        context,
                        icon: Icons.person_pin_circle,
                        title: order.customerName,
                        subtitle: 'Customer',
                        coordinates:
                            '${order.customerLat.toStringAsFixed(5)}, ${order.customerLng.toStringAsFixed(5)}',
                        distance: _distanceToCustomer,
                        onNavigate: () => _navigateTo(
                          order.customerLat,
                          order.customerLng,
                          order.customerName,
                        ),
                        isActive: _state.index >= TripState.pickedUp.index,
                      )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Current Location Card
                  _buildCurrentLocationCard(context)
                      .animate(delay: 800.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Completed State Action
                  if (_state == TripState.delivered)
                    _buildCompletedActions(context)
                        .animate(delay: 1000.ms)
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                        ),

                  SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Location Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Amount: ₹${order.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStateColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStateColor(context)),
                  ),
                  child: Text(
                    _stateLabel(_state),
                    style: TextStyle(
                      color: _getStateColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressStep(context, 'Start', TripState.started, 0),
                _buildProgressLine(
                  context,
                  _state.index >= TripState.started.index,
                ),
                _buildProgressStep(
                  context,
                  'Restaurant',
                  TripState.arrivedRestaurant,
                  1,
                ),
                _buildProgressLine(
                  context,
                  _state.index >= TripState.arrivedRestaurant.index,
                ),
                _buildProgressStep(context, 'Picked', TripState.pickedUp, 2),
                _buildProgressLine(
                  context,
                  _state.index >= TripState.pickedUp.index,
                ),
                _buildProgressStep(
                  context,
                  'Customer',
                  TripState.arrivedCustomer,
                  3,
                ),
                _buildProgressLine(
                  context,
                  _state.index >= TripState.arrivedCustomer.index,
                ),
                _buildProgressStep(context, 'Done', TripState.delivered, 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(
    BuildContext context,
    String label,
    TripState state,
    int index,
  ) {
    final isActive = _state.index >= state.index;
    final isCurrent = _state == state;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
          ),
          child: Center(
            child: isActive
                ? Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(BuildContext context, bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String coordinates,
    required double? distance,
    required VoidCallback onNavigate,
    required bool isActive,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isActive ? onNavigate : null,
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    coordinates,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (distance != null) ...[
                  Icon(
                    Icons.social_distance,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(0)}m',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Location',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _currentPosition != null
                            ? 'GPS Active'
                            : _isLoading
                            ? 'Getting location...'
                            : 'Location unavailable',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _currentPosition != null
                              ? AppTheme.successColor
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentPosition != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Delivered!',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                      ),
                      Text(
                        'Great job! Order ${widget.order.id} has been successfully delivered.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/history'),
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/order');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(BuildContext context) {
    switch (_state) {
      case TripState.notStarted:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
      case TripState.started:
      case TripState.arrivedRestaurant:
      case TripState.pickedUp:
      case TripState.arrivedCustomer:
        return Theme.of(context).colorScheme.primary;
      case TripState.delivered:
        return AppTheme.successColor;
    }
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool active;
  const _StepChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: active
          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      side: active
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
