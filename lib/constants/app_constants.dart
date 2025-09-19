/// Application-wide constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'FoodDriver Pro';
  static const String appVersion = '1.0.0';
  
  // Location Settings
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const double geofenceRadiusMeters = 50.0;
  static const double locationAccuracyThreshold = 10.0; // meters
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Order States
  static const List<String> orderStateLabels = [
    'Not Started',
    'On the way to Restaurant',
    'At Restaurant',
    'Picked Up',
    'At Customer',
    'Delivered',
  ];
  
  // Mock Data
  static const String defaultEmail = 'driver@example.com';
  static const String defaultPassword = 'password123';
  
  // Error Messages
  static const String locationPermissionDenied = 'Location permission is required for this app to function properly.';
  static const String locationServiceDisabled = 'Please enable location services to continue.';
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
}
