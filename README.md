# Flutter Driver App - Food Delivery Driver Application

A comprehensive Flutter application that simulates the food delivery driver workflow with real-time location tracking, geofencing, and Google Maps integration.

## 📱 Features

### 🔐 Authentication
- **Mock Login Screen**: Simple email and password authentication (no backend required)
- Clean Material Design UI with form validation

### 📋 Order Management
- **Assigned Order Screen**: Displays complete order details including:
  - Order ID
  - Restaurant name and coordinates
  - Customer name and coordinates
  - Order amount
- **Order History**: Track completed deliveries

### 🚗 Delivery Flow (State Machine)
Complete order lifecycle with visual progress tracking:
1. **Start Trip** → Begin delivery journey
2. **Arrived at Restaurant** → Driver reaches pickup location
3. **Picked Up** → Order collected from restaurant
4. **Arrived at Customer** → Driver reaches delivery location
5. **Delivered** → Order successfully completed

### 🎯 Geofencing
- **50-meter radius validation** for both restaurant and customer locations
- Real-time distance calculation using Haversine formula
- Visual feedback showing current distance to target locations
- Prevents state progression unless within required proximity

### 🗺️ Navigation Integration
- **Google Maps Integration**: One-tap navigation to restaurant and customer locations
- Opens external Google Maps app with turn-by-turn directions
- Supports driving mode for optimal route planning

### 📍 Location Services
- **Real-time Location Tracking**: Updates every 10 seconds
- **Current Position Display**: Shows driver's live coordinates
- **Console Logging**: Simulates server communication (bonus feature)
- **Permission Handling**: Automatic location permission requests

## 🛠️ Technical Stack

### Dependencies
- **Flutter**: ^3.9.2 (with null safety)
- **geolocator**: ^13.0.1 - Location services and GPS tracking
- **url_launcher**: ^6.3.1 - Google Maps integration
- **provider**: ^6.1.2 - State management

### Architecture
- **Modular Design**: Clean separation of concerns
- **Service Layer**: Dedicated services for location, distance calculations, and order management
- **State Management**: Provider pattern for reactive UI updates
- **Material Design 3**: Modern, accessible UI components

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point and routing
├── models/
│   └── order.dart           # Order data model
├── screens/
│   ├── login_screen.dart    # Authentication screen
│   ├── assigned_order_screen.dart  # Main delivery interface
│   └── order_history_screen.dart   # Completed orders history
├── services/
│   ├── location_service.dart    # GPS and location management
│   ├── distance_utils.dart     # Geofencing and distance calculations
│   └── order_repository.dart   # Order state management
└── widgets/                  # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Physical device or emulator with location services

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd shadabkhan_asessment
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
- Ensure location permissions are granted
- Enable GPS/location services
- Test on physical device for accurate location tracking

#### iOS
- Add location usage descriptions in `Info.plist`
- Grant location permissions when prompted

## 📱 Usage Guide

### 1. Login
- Enter any email and password (mock authentication)
- Tap "Login" to proceed to order screen

### 2. Order Management
- View assigned order details
- Check current distance to restaurant/customer
- Monitor delivery progress through visual step indicators

### 3. Delivery Process
- **Start Trip**: Begin the delivery journey
- **Navigate**: Use Google Maps for turn-by-turn directions
- **Arrived at Restaurant**: Only available when within 50m of restaurant
- **Picked Up**: Confirm order collection
- **Arrived at Customer**: Only available when within 50m of customer
- **Delivered**: Complete the delivery

### 4. Location Tracking
- Real-time location updates every 10 seconds
- Distance calculations to restaurant and customer
- Console logging for development/debugging

## 🔧 Configuration

### Location Settings
- Update interval: 10 seconds (configurable in `LocationService`)
- Geofence radius: 50 meters (configurable in `DistanceUtils`)
- Location accuracy: Best available

### Order Data
Default order configuration in `main.dart`:
```dart
Order(
  id: 'ORD123',
  restaurantName: 'Pizza Palace',
  restaurantLat: 28.6139,
  restaurantLng: 77.2090,
  customerName: 'John Doe',
  customerLat: 28.6200,
  customerLng: 77.2200,
  amount: 499.0,
)
```

## 🧪 Testing

### Manual Testing
1. **Location Services**: Verify GPS tracking and permission handling
2. **Geofencing**: Test 50m radius validation at restaurant and customer locations
3. **Navigation**: Confirm Google Maps integration works correctly
4. **State Machine**: Verify proper order flow progression
5. **UI/UX**: Test responsive design and accessibility

### Console Output
Monitor location updates in console:
```
[SendToServer] lat=28.61390, lng=77.20900
[LocationUpdate 2024-01-15T10:30:00.000Z] lat=28.61390, lng=77.20900, acc=5m
```

## 📋 Requirements Compliance

✅ **Login (Mock)**: Simple email/password authentication  
✅ **Assigned Order Screen**: Complete order details display  
✅ **Order Flow State Machine**: 5-step delivery process  
✅ **Geofence Check**: 50m radius validation for locations  
✅ **Navigation**: Google Maps integration  
✅ **Location Updates**: 10-second intervals with console logging  
✅ **Flutter Null Safety**: Modern Dart/Flutter practices  
✅ **Allowed Packages**: geolocator, url_launcher, provider  
✅ **Modular Code**: Clean, readable, maintainable architecture  

## 🎯 Key Features Demonstrated

- **Real-time Location Tracking**: GPS integration with permission handling
- **Geofencing**: Proximity-based state validation
- **External App Integration**: Google Maps navigation
- **State Management**: Reactive UI with Provider pattern
- **Material Design 3**: Modern, accessible user interface
- **Modular Architecture**: Separation of concerns and reusable components

## 📄 License

This project is created for educational/assessment purposes.

## 👨‍💻 Developer

**Shadab Khan**  
Flutter Developer Assessment Project

---

*Built with ❤️ using Flutter*