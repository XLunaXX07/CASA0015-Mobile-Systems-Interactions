import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/user_model.dart';
import '../models/walk_session.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user profile in Firestore
        await _createUserProfile(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
        );

        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('错误代码: ${e.code}'); // 例如: internal-error
      debugPrint('错误详情: ${e.message}'); // 例如: An internal error has occurred...
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('错误代码: ${e.code}'); // 例如: internal-error
      debugPrint('错误详情: ${e.message}'); // 例如: An internal error has occurred...
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User Profile
  Future<void> _createUserProfile({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    await _firestore.collection('users').doc(id).set({
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'emergencyContacts': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<void> addEmergencyContact(String userId, EmergencyContact contact) async {
    final user = await getUserProfile(userId);

    if (user != null) {
      final updatedContacts = [...user.emergencyContacts, contact];

      await _firestore.collection('users').doc(userId).update({
        'emergencyContacts': updatedContacts.map((e) => e.toMap()).toList(),
      });
    }
  }

  Future<void> removeEmergencyContact(String userId, String phoneNumber) async {
    final user = await getUserProfile(userId);

    if (user != null) {
      final updatedContacts =
          user.emergencyContacts.where((contact) => contact.phoneNumber != phoneNumber).toList();

      await _firestore.collection('users').doc(userId).update({
        'emergencyContacts': updatedContacts.map((e) => e.toMap()).toList(),
      });
    }
  }

  // Walk Sessions
  Future<String> startWalkSession(String userId) async {
    final docRef = _firestore.collection('walkSessions').doc();

    final walkSession = WalkSession(
      id: docRef.id,
      userId: userId,
      startTime: DateTime.now(),
      isActive: true,
    );

    await docRef.set(walkSession.toMap());
    return docRef.id;
  }

  Future<void> updateWalkSession(WalkSession session) async {
    await _firestore.collection('walkSessions').doc(session.id).update(
          session.toMap(),
        );
  }

  Future<void> endWalkSession(String sessionId) async {
    await _firestore.collection('walkSessions').doc(sessionId).update({
      'endTime': DateTime.now().millisecondsSinceEpoch,
      'isActive': false,
    });
  }

  Future<void> addLocationToWalkSession(String sessionId, LatLng location) async {
    final doc = await _firestore.collection('walkSessions').doc(sessionId).get();

    if (doc.exists) {
      final session = WalkSession.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });

      final updatedPath = [...session.path, location];

      // Calculate new distance
      final distance = session.path.isNotEmpty
          ? session.distanceCovered + _calculateDistance(session.path.last, location)
          : 0.0;

      await _firestore.collection('walkSessions').doc(sessionId).update({
        'path': updatedPath
            .map((loc) => {
                  'latitude': loc.latitude,
                  'longitude': loc.longitude,
                })
            .toList(),
        'distanceCovered': distance,
        'durationMillis': DateTime.now().difference(session.startTime).inMilliseconds,
      });
    }
  }

  Future<void> addEmergencyEvent(
    String sessionId,
    EmergencyType type,
    LatLng location,
  ) async {
    final doc = await _firestore.collection('walkSessions').doc(sessionId).get();

    if (doc.exists) {
      final session = WalkSession.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });

      final emergencyEvent = EmergencyEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: type,
        location: location,
      );

      final updatedEvents = [...session.emergencyEvents, emergencyEvent];

      await _firestore.collection('walkSessions').doc(sessionId).update({
        'emergencyEvents': updatedEvents.map((e) => e.toMap()).toList(),
      });
    }
  }

  Future<List<WalkSession>> getUserWalkSessions(String userId) async {
    try {
      print(3);
      final snapshot = await _firestore
          .collection('walkSessions')
          .where('userId', isEqualTo: userId)
          //.orderBy('startTime', descending: true)
          .get();
      // 遍历所有文档并打印每个文档的完整数据（包含字段和值）
      snapshot.docs.forEach((doc) {
        print(doc.data()); // 直接打印文档的 Map 数据
        // 如果需要更美观的格式，使用 jsonEncode
        print(jsonEncode(doc.data()));
      });
      return snapshot.docs
          .map((doc) => WalkSession.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<WalkSession?> getActiveWalkSession(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('walkSessions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WalkSession.fromMap({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id,
        });
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Helpers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    final double lat1Rad = _degreesToRadians(point1.latitude);
    final double lat2Rad = _degreesToRadians(point2.latitude);
    final double deltaLatRad = _degreesToRadians(point2.latitude - point1.latitude);
    final double deltaLngRad = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}
