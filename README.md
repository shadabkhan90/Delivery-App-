# Driver App – Intern Assignment

Basic driver app that simulates a food delivery flow: login, view one assigned order, navigate via Google Maps, enforce geofenced steps (50 m), and show live location updates (every 10s, also printed to console as if sending to server).

## Tech
- Flutter (null-safety)
- Packages: `geolocator`, `url_launcher`

## Setup
1. Flutter SDK installed and configured for Android/iOS.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Android: Ensure Google Play services and location are enabled on device/emulator.
4. iOS: Use a real device or a simulator with location simulation enabled.

## Run
```bash
flutter run
```

## Dummy Login
- Email: any non-empty
- Password: any non-empty

## Flow
1. Login → Assigned Order screen.
2. See order details and your live location (lat/lng) plus distances to restaurant and customer.
3. Buttons enforce order state machine:
   - Start Trip → Arrived at Restaurant → Picked Up → Arrived at Customer → Delivered
   - “Arrived at Restaurant” allowed only within 50 m of restaurant.
   - “Arrived at Customer” allowed only within 50 m of customer.
   - UI shows distance like “Distance to Restaurant: 75 m”. If not within range, a snackbar shows how far you are.
4. Navigation: use buttons to open Google Maps directions to restaurant or customer.
5. Location updates: every ~10s. Updates are also printed to console as simulated “sending to server”.

## Files of Interest
- `lib/models/order.dart`: Order model.
- `lib/services/location_service.dart`: Permissions and location stream.
- `lib/services/distance_utils.dart`: Haversine distance and geofence check.
- `lib/screens/login_screen.dart`: Mock login.
- `lib/screens/assigned_order_screen.dart`: UI, state machine, geofence logic, navigation, console updates.

## Platform Permissions
- Android: `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` declared in `android/app/src/main/AndroidManifest.xml`.
- iOS: `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

## Assumptions
- Only one order is assigned and pre-seeded in `lib/main.dart`.
- Geofence threshold is 50 meters (straight-line distance).
- Google Maps app or browser can handle direction intents.

## Notes
- Code is modular with simple services and utilities.
- State is managed locally within the `AssignedOrderScreen` for clarity.
