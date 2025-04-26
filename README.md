# Walk_Guardian

## 📱 Project Overview

**Walk Guardian** is a simple mobile application designed to help users feel safer when walking alone. It allows you to track your location in real time, keep a record of your journeys, and quickly send an alert to emergency contacts if needed. Built using Flutter, the app focuses on ease of use and essential safety features, providing a reliable way to stay connected and protected during solo walks, especially at night or in unfamiliar areas.
---

## ✨ Key Features

- **🧭 Real-Time Location Tracking**  
  Displays and monitors the user’s current GPS location on a map.

- **📍 Journey Monitoring**  
  Logs walking routes and duration, highlighting any emergencies during the walk.

- **🆘 Emergency SOS Button**  
  A long-press SOS button sends location alerts to a pre-set emergency contact.

- **📇 Emergency Contacts Management**  
  Add, edit, or delete trusted contacts for emergency notifications.

- **👤 User Profile**  
  Stores user info such as name, email, and phone number, assisting responders.

---

## 🧠 Technologies Used

- **Framework**: Flutter (Dart)
- **APIs**:
  - Google Maps API
  - Firebase Firestore
- **Device Sensors**:
  - GPS
  - Motion (Accelerometer/Gyroscope – planned)
- **Supported Platforms**: Android & iOS

---

## 🧭 User Journey

1. **Launch the app** – see current location via Google Maps.
2. **Tap "Start Walking"** – journey begins, tracking distance and time.
3. **Hold SOS** – if the user feels unsafe, they can send alerts instantly.
4. **End walk** – view walk summary and emergency events in the History tab.
5. **Set contacts & profile** – via dedicated screens in the app.

---

## 🚀 Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

14:31 93% 

GitHub - AbhinpsaKar/casa0015-mobile  
github.com  

README  

https://stackoverflow.com/questions/41436639/does-sharedpreferences-get-shaered-across-user  

## Build instructions  
1. Download the android project from the below github link  
[https://github.com/XLunaXX07/CASA0015-Mobile-Systems-Interactions](https://github.com/XLunaXX07/CASA0015-Mobile-Systems-Interactions)  
3. Rename project to mine_project.  
4. set your HERE SDK credentials to  
[https://github.com/XLunaXX07/CASA0015-Mobile-Systems-Interactions/android/app/src/main/AndroidManifest.xml](https://github.com/XLunaXX07/CASA0015-Mobile-Systems-Interactions/android/app/src/main/AndroidManifest.xml)
6. Unzip the HERE SDK for flutter and copy inside plugins folder in your project.  
Project: shared_numbers/are-sdk → mine_numbering/here_sdk  
7. Listen the below dependencies for this project:  
  cupertino_icons: ^1.0.6
  location: ^5.0.3
  geolocator: ^10.1.0
  flutter_polyline_points: ^2.1.0
  sensors_plus: ^4.0.2
  provider: ^6.1.1
  flutter_spinkit: ^5.2.0
  fluttertoast: ^8.2.4
  shared_preferences: ^2.2.2
  permission_handler: ^11.0.1
  intl: ^0.18.1
  url_launcher: ^6.2.2
  flutter_local_notifications: ^16.2.0
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  google_maps_flutter: ^2.12.1
8. Start an emulator or SIMULATOR and execute flutter run from the app's directory - or run the app from within your IDE.
