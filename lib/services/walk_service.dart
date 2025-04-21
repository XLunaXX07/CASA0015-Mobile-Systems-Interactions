import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/user_model.dart';
import '../models/walk_session.dart';
import '../utils/emergency_utils.dart';
import '../utils/location_utils.dart';
import '../utils/sensor_utils.dart';
import 'firebase_service.dart';

class WalkService {
  final FirebaseService _firebaseService;

  WalkSession? _currentSession;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _fallSubscription;
  StreamSubscription? _inactivitySubscription;

  final _walkSessionController = StreamController<WalkSession?>.broadcast();
  Stream<WalkSession?> get sessionStream => _walkSessionController.stream;

  UserModel? _currentUser;

  BuildContext context;

  WalkService(this._firebaseService, this.context);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  Future<void> initialize(UserModel user) async {
    _currentUser = user;

    // Check if there's an active session
    _currentSession = await _firebaseService.getActiveWalkSession(user.id);
    _walkSessionController.add(_currentSession);

    if (_currentSession != null) {
      // If there's an active session, resume tracking
      await startTracking();
    }
  }

  Future<bool> startWalking() async {
    if (_currentUser == null) return false;
    if (_currentSession != null) return true; // Already walking

    try {
      // Request location permission
      bool hasPermission = await LocationUtils.requestLocationPermission();
      if (!hasPermission) return false;

      // Get current location
      LatLng? currentLocation = await LocationUtils.getCurrentLocation();
      if (currentLocation == null) return false;

      // Create new walk session in Firebase
      String sessionId = await _firebaseService.startWalkSession(_currentUser!.id);

      // Initialize the session
      _currentSession = WalkSession(
        id: sessionId,
        userId: _currentUser!.id,
        startTime: DateTime.now(),
        path: [currentLocation],
        isActive: true,
      );

      _walkSessionController.add(_currentSession);

      // Start tracking location and sensors
      await startTracking();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> startTracking() async {
    if (_currentSession == null) return;

    // Start sensor monitoring for fall and inactivity detection
    SensorUtils.startMonitoring();

    // // Listen for fall detection
    // _fallSubscription = SensorUtils.onFallDetected.listen((isFall) async {
    //   if (isFall && _currentSession != null && _currentUser != null) {
    //     // Get current location
    //     LatLng? location = await LocationUtils.getCurrentLocation();
    //     if (location == null) return;

    //     // Add fall event to the session
    //     await _firebaseService.addEmergencyEvent(
    //       _currentSession!.id,
    //       EmergencyType.fall,
    //       location,
    //     );

    //     // Handle the fall detection
    //     await EmergencyUtils.handleFallDetection(
    //       contacts: _currentUser!.emergencyContacts,
    //       location: location,
    //       userName: _currentUser!.name,
    //     );

    //     // Update local session
    //     _updateCurrentSession();
    //   }
    // });

    _fallSubscription = SensorUtils.onFallDetected.listen((isFall) async {
      if (isFall && _currentSession != null && _currentUser != null) {
        LatLng? location = await LocationUtils.getCurrentLocation();
        if (location == null) return;

        bool? shouldAlert = await showEmergencyConfirmDialog(
          title: 'Danger Reminder',
          message: 'Send a message to the emergency contact person?',
        );

        if (shouldAlert == true) {
          await _firebaseService.addEmergencyEvent(
            _currentSession!.id,
            EmergencyType.fall,
            location,
          );
          await EmergencyUtils.handleFallDetection(
            contacts: _currentUser!.emergencyContacts,
            location: location,
            userName: _currentUser!.name,
          );
        }

        _updateCurrentSession();
      }
    });

    // Listen for inactivity detection
    _inactivitySubscription = SensorUtils.onInactivityDetected.listen((isInactive) async {
      if (isInactive && _currentSession != null && _currentUser != null) {
        // Get current location
        LatLng? location = await LocationUtils.getCurrentLocation();
        if (location == null) return;

        // Add inactivity event to the session
        await _firebaseService.addEmergencyEvent(
          _currentSession!.id,
          EmergencyType.inactivity,
          location,
        );

        // Handle the inactivity detection
        await EmergencyUtils.handleInactivityDetection(
          contacts: _currentUser!.emergencyContacts,
          location: location,
          userName: _currentUser!.name,
        );

        // Update local session
        _updateCurrentSession();
      }
    });

    // Listen for location updates
    _locationSubscription = LocationUtils.getLocationStream().listen((Position position) async {
      print('update location');
      if (_currentSession == null) return;

      // Convert Position to LatLng
      LatLng location = LatLng(position.latitude, position.longitude);

      // Add location to the walk session
      await _firebaseService.addLocationToWalkSession(_currentSession!.id, location);

      // Update the local session
      _updateCurrentSession();
    });
  }

  // 封装紧急确认弹窗组件
  Future<bool?> showEmergencyConfirmDialog({
    required String title,
    required String message,
  }) async {
    bool? result;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('confirm'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    ).then((value) => result = value);

    return result;
  }

  // void _showSendMessageDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Danger Reminder'),
  //       content: Text('Send a message to the emergency contact person?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //           child: const Text('confirm'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _updateCurrentSession() async {
    if (_currentSession == null) return;

    final updatedSession = await _firebaseService.getActiveWalkSession(_currentUser!.id);
    if (updatedSession != null) {
      _currentSession = updatedSession;
      _walkSessionController.add(_currentSession);
    }
  }

  Future<bool> stopWalking() async {
    if (_currentSession == null) return false;

    try {
      // End the walk session in Firebase
      await _firebaseService.endWalkSession(_currentSession!.id);

      // Stop tracking
      await stopTracking();

      // Clear the current session
      _currentSession = null;
      _walkSessionController.add(null);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopTracking() async {
    // Cancel location subscription
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Cancel sensor subscriptions
    await _fallSubscription?.cancel();
    _fallSubscription = null;

    await _inactivitySubscription?.cancel();
    _inactivitySubscription = null;

    // Stop sensor monitoring
    SensorUtils.stopMonitoring();
  }

  Future<bool> triggerSOS() async {
    if (_currentUser == null) return false;

    try {
      // Get current location
      LatLng? location = await LocationUtils.getCurrentLocation();
      if (location == null) return false;

      // If there's an active session, add SOS event
      if (_currentSession != null) {
        await _firebaseService.addEmergencyEvent(
          _currentSession!.id,
          EmergencyType.sos,
          location,
        );

        // Update the local session
        _updateCurrentSession();
      }

      // Trigger SOS actions
      await EmergencyUtils.triggerSOS(
        contacts: _currentUser!.emergencyContacts,
        location: location,
        userName: _currentUser!.name,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<WalkSession>> getPastWalkSessions() async {
    print(1);
    if (_currentUser == null) return [];
    print(2);

    return await _firebaseService.getUserWalkSessions(_currentUser!.id);
  }

  WalkSession? getCurrentSession() {
    return _currentSession;
  }

  void dispose() {
    stopTracking();
    _walkSessionController.close();
  }
}
