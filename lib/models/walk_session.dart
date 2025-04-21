import 'package:google_maps_flutter/google_maps_flutter.dart';

class WalkSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LatLng> path;
  final double distanceCovered; // in meters
  final Duration duration;
  final bool isActive;
  final List<EmergencyEvent> emergencyEvents;

  WalkSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.path = const [],
    this.distanceCovered = 0.0,
    this.duration = Duration.zero,
    this.isActive = true,
    this.emergencyEvents = const [],
  });

  factory WalkSession.fromMap(Map<String, dynamic> map) {
    return WalkSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime']) : null,
      path: map['path'] != null
          ? List<LatLng>.from(map['path']?.map((x) => LatLng(x['latitude'], x['longitude'])))
          : [],
      distanceCovered: map['distanceCovered']?.toDouble() ?? 0.0,
      duration: Duration(milliseconds: map['durationMillis'] ?? 0),
      isActive: map['isActive'] ?? false,
      emergencyEvents: map['emergencyEvents'] != null
          ? List<EmergencyEvent>.from(map['emergencyEvents']?.map((x) => EmergencyEvent.fromMap(x)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'path': path
          .map((location) => {
                'latitude': location.latitude,
                'longitude': location.longitude,
              })
          .toList(),
      'distanceCovered': distanceCovered,
      'durationMillis': duration.inMilliseconds,
      'isActive': isActive,
      'emergencyEvents': emergencyEvents.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(), // 使用 ISO 8601 标准格式
      'endTime': endTime?.toIso8601String(), // 可空字段用 ?.
      'path': path
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'distanceCovered': distanceCovered,
      'duration': duration.inMilliseconds, // 或者 duration.toString()
      'isActive': isActive,
      //'emergencyEvents': emergencyEvents.map((e) => e.toJson()).toList(),
    };
  }

  WalkSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<LatLng>? path,
    double? distanceCovered,
    Duration? duration,
    bool? isActive,
    List<EmergencyEvent>? emergencyEvents,
  }) {
    return WalkSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      path: path ?? this.path,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      emergencyEvents: emergencyEvents ?? this.emergencyEvents,
    );
  }
}

class EmergencyEvent {
  final String id;
  final DateTime timestamp;
  final EmergencyType type;
  final LatLng location;
  final bool resolved;
  final String? notes;

  EmergencyEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.location,
    this.resolved = false,
    this.notes,
  });

  factory EmergencyEvent.fromMap(Map<String, dynamic> map) {
    return EmergencyEvent(
      id: map['id'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: EmergencyType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => EmergencyType.sos,
      ),
      location: LatLng(
        map['location']['latitude'] ?? 0.0,
        map['location']['longitude'] ?? 0.0,
      ),
      resolved: map['resolved'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString(),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'resolved': resolved,
      'notes': notes,
    };
  }
}

enum EmergencyType {
  sos,
  fall,
  inactivity,
}
