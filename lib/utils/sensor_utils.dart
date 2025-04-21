import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class SensorUtils {
  // Constants for fall detection
  static const double fallThreshold = 30.0; // acceleration threshold in m/s^2
  static const double inactivityThreshold = 0.5; // minimal movement threshold
  static const int inactivityTimeThresholdSeconds = 180; // 3 minutes

  // Stream controllers
  static final StreamController<bool> _fallDetectedController = StreamController<bool>.broadcast();
  static final StreamController<bool> _inactivityDetectedController = StreamController<bool>.broadcast();

  // Public streams
  static Stream<bool> get onFallDetected => _fallDetectedController.stream;
  static Stream<bool> get onInactivityDetected => _inactivityDetectedController.stream;

  // Private variables
  static bool _isMonitoring = false;
  static DateTime? _lastSignificantMovement;
  static Timer? _inactivityTimer;
  static StreamSubscription? _accelerometerSubscription;

  // Start monitoring for falls and inactivity
  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _lastSignificantMovement = DateTime.now();
    DateTime? _lastFallDetectionTime; // 新增：记录最后一次跌倒时间

    // Cancel existing subscription if any
    _accelerometerSubscription?.cancel();

    // Subscribe to accelerometer events
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate magnitude of acceleration
      double accelerationMagnitude = _calculateAccelerationMagnitude(event);

      // Check for fall (带冷却时间限制)
      if (accelerationMagnitude > fallThreshold) {
        final now = DateTime.now();
        // 如果从未检测过跌倒，或距离上次检测超过1分钟
        if (_lastFallDetectionTime == null || now.difference(_lastFallDetectionTime!) > Duration(minutes: 1)) {
          print("[Fall Detection] Fall detected (Cooling down for 1 minute)");
          _lastFallDetectionTime = now; // 更新最后一次触发时间
          _fallDetectedController.add(true);
        } else {
          print("[Fall Detection] Suppressed - Within cooldown period");
        }
      }

      // Check for activity (原逻辑不变)
      if (accelerationMagnitude > inactivityThreshold) {
        _lastSignificantMovement = DateTime.now();
      }
    });

    // Setup inactivity timer
    _setupInactivityTimer();
    print("startMonitoring");
  }

  static void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _inactivityTimer?.cancel();
    _accelerometerSubscription = null;
    _inactivityTimer = null;
  }

  static void _setupInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lastSignificantMovement == null) return;

      final now = DateTime.now();
      final difference = now.difference(_lastSignificantMovement!);

      if (difference.inSeconds > inactivityTimeThresholdSeconds) {
        _inactivityDetectedController.add(true);
      }
    });
  }

  static double _calculateAccelerationMagnitude(AccelerometerEvent event) {
    // Calculate the magnitude of the acceleration vector (sqrt(x² + y² + z²))
    return sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  }

  // Cleanup resources
  static void dispose() {
    stopMonitoring();
    _fallDetectedController.close();
    _inactivityDetectedController.close();
  }
}
