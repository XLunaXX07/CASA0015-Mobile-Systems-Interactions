import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';

class EmergencyUtils {
  // static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  // static Future<void> initializeNotifications() async {
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
  //     requestAlertPermission: true,
  //     requestBadgePermission: true,
  //     requestSoundPermission: true,
  //     onDidReceiveLocalNotification: (id, title, body, payload) async {
  //       // Handle iOS notification
  //     },
  //   );

  //   final InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsIOS,
  //   );

  //   await _notificationsPlugin.initialize(
  //     initializationSettings,
  //     onDidReceiveNotificationResponse: (NotificationResponse details) async {
  //       // Handle notification tap
  //     },
  //   );
  // }

  // static Future<void> showEmergencyNotification({
  //   required String title,
  //   required String body,
  // }) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     'emergency_channel',
  //     'Emergency Notifications',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     playSound: true,
  //     enableVibration: true,
  //     sound: RawResourceAndroidNotificationSound('emergency_alarm'),
  //   );

  //   const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //     sound: 'emergency_alarm.aiff',
  //   );

  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: iOSPlatformChannelSpecifics,
  //   );

  //   await _notificationsPlugin.show(
  //     0,
  //     title,
  //     body,
  //     platformChannelSpecifics,
  //   );
  // }

  static Future<bool> callEmergencyContact(EmergencyContact contact) async {
    final Uri callUri = Uri(
      scheme: 'tel',
      path: contact.phoneNumber,
    );

    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendSMSToEmergencyContacts({
    required List<EmergencyContact> contacts,
    required String message,
    required LatLng location,
  }) async {
    bool allSucceeded = true;
    final String locationLink = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    final String fullMessage = '$message\nMy location: $locationLink';

    for (final contact in contacts) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {
          'body': fullMessage,
        },
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          allSucceeded = false;
        }
      } catch (e) {
        allSucceeded = false;
      }
    }

    return allSucceeded;
  }

  static Future<void> triggerSOS({
    required List<EmergencyContact> contacts,
    required LatLng location,
    required String userName,
  }) async {
    // Show notification
    // await showEmergencyNotification(
    //   title: 'SOS Activated',
    //   body: 'Emergency contacts are being notified of your situation.',
    // );

    // Send SMS to all emergency contacts
    final message = 'EMERGENCY: $userName has triggered an SOS alert and may need help!';
    await sendSMSToEmergencyContacts(
      contacts: contacts,
      message: message,
      location: location,
    );

    // Call the first emergency contact if available
    if (contacts.isNotEmpty) {
      await callEmergencyContact(contacts.first);
    }
  }

  static Future<void> handleFallDetection({
    required List<EmergencyContact> contacts,
    required LatLng location,
    required String userName,
  }) async {
    // Show notification
    // await showEmergencyNotification(
    //   title: 'Fall Detected',
    //   body: 'Are you okay? Emergency contacts will be notified if no response.',
    // );

    // After a delay, notify emergency contacts if no response
    final message = 'ALERT: $userName may have fallen. Their location is attached.';
    await sendSMSToEmergencyContacts(
      contacts: contacts,
      message: message,
      location: location,
    );
  }

  static Future<void> handleInactivityDetection({
    required List<EmergencyContact> contacts,
    required LatLng location,
    required String userName,
  }) async {
    // Show notification
    // await showEmergencyNotification(
    //   title: 'Inactivity Detected',
    //   body: 'Are you okay? No movement detected for some time.',
    // );

    // After a delay, notify emergency contacts if no response
    await Future.delayed(const Duration(seconds: 30), () async {
      final message = 'ALERT: $userName hasn\'t moved for an extended period. They may need assistance.';
      await sendSMSToEmergencyContacts(
        contacts: contacts,
        message: message,
        location: location,
      );
    });
  }
}
