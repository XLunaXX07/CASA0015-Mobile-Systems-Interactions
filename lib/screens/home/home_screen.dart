import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/walk_session.dart';
import '../../services/firebase_service.dart';
import '../../services/walk_service.dart';
import '../../utils/location_utils.dart';
import '../contacts/emergency_contacts_screen.dart';
import '../history/walk_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  UserModel? _user;
  bool _isLoading = true;
  bool _isWalking = false;
  bool _isInitialized = false;

  // SOS button press timer
  Timer? _sosTimer;
  bool _isSOSPressed = false;
  final int _sosHoldDuration = 3; // seconds to hold for SOS activation
  int _sosPressedTime = 0;

  // Map settings
  final CameraPosition _defaultLocation = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 16,
  );
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Walk service reference
  late WalkService _walkService;

  LatLng? _initialLocation;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _walkService = WalkService(firebaseService, context);

    // Get current user
    final currentUser = firebaseService.getCurrentUser();

    print('currentUser: $currentUser');
    if (currentUser != null) {
      print('1');
      // Load user profile
      final userProfile = await firebaseService.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        print('2');
        setState(() {
          _user = userProfile;
        });

        // Initialize walk service
        await _walkService.initialize(userProfile);

        // Listen to walk session updates
        _walkService.sessionStream.listen((session) {
          setState(() {
            _isWalking = session != null;
          });
          _updateMapWithSession(session);
        });

        setState(() {
          _isInitialized = true;
        });
      }
    }

    // Check location permission and get current location
    bool hasPermission = await LocationUtils.requestLocationPermission();
    if (hasPermission) {
      _initialLocation = await LocationUtils.getCurrentLocation();
      print('Current Location: $_initialLocation');
      // if (currentLocation != null) {
      //   _updateCameraPosition(currentLocation);
      //   _addMarker(currentLocation, 'Current Location');
      // }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateCameraPosition(LatLng position) async {
    print('Map controller completed: ${_mapController.isCompleted}'); // 检查是否为 true
    if (_mapController.isCompleted) {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16,
          ),
        ),
      );
    }
  }

  void _addMarker(LatLng position, String title) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(title),
          position: position,
          infoWindow: InfoWindow(title: title),
        ),
      };
    });
  }

  void _updateMapWithSession(WalkSession? session) {
    if (session == null || session.path.isEmpty) {
      setState(() {
        _polylines = {};
      });
      return;
    }
    print(session.path);
    // Add path polyline
    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId(session.id),
          points: session.path,
          color: Colors.blue,
          width: 5,
        ),
      };
    });

    // Update current location marker
    final currentLocation = session.path.last;
    _addMarker(currentLocation, 'Current Location');
    _updateCameraPosition(currentLocation);
  }

  Future<void> _toggleWalking() async {
    if (_isWalking) {
      // Stop walking
      bool success = await _walkService.stopWalking();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walk ended')),
        );
      }
    } else {
      // Start walking
      bool success = await _walkService.startWalking();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walk started')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start walking. Please check permissions.')),
        );
      }
    }
  }

  void _onSOSPressed() {
    setState(() {
      _isSOSPressed = true;
      _sosPressedTime = 0;
    });

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosPressedTime++;
      });

      if (_sosPressedTime >= _sosHoldDuration) {
        _triggerSOS();
        _cancelSOSTimer();
      }
    });
  }

  void _onSOSReleased() {
    _cancelSOSTimer();
  }

  void _cancelSOSTimer() {
    _sosTimer?.cancel();
    _sosTimer = null;
    setState(() {
      _isSOSPressed = false;
      _sosPressedTime = 0;
    });
  }

  Future<void> _triggerSOS() async {
    if (_user == null) return;

    bool success = await _walkService.triggerSOS();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert Sent! Emergency contacts notified.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send SOS alert. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkGuardian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalkHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map
                GoogleMap(
                  initialCameraPosition: _defaultLocation,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller); // 在这里调用位置更新（确保控制器已就绪）
                    if (_initialLocation != null) {
                      _updateCameraPosition(_initialLocation!);
                      _addMarker(_initialLocation!, 'Current Location');
                    }
                  },
                ),

                // SOS Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        GestureDetector(
                          onLongPressStart: (_) => _onSOSPressed(),
                          onLongPressEnd: (_) => _onSOSReleased(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSOSPressed ? Colors.red.shade900 : Colors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isSOSPressed)
                          Text(
                            'Hold for ${_sosHoldDuration - _sosPressedTime}s',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            'Hold for SOS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Emergency Contacts Button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'contacts',
                    backgroundColor: Colors.orange,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.contacts),
                  ),
                ),

                // Walking Status
                if (_isInitialized && _isWalking)
                  Positioned(
                    bottom: 170,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tracking Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: !_isInitialized
          ? FloatingActionButton.extended(
              onPressed: _initializeApp,
              backgroundColor: Colors.grey,
              label: Text('refresh intnet'),
            )
          : FloatingActionButton.extended(
              onPressed: _toggleWalking,
              backgroundColor: _isWalking ? Colors.red : Colors.green,
              icon: Icon(_isWalking ? Icons.stop : Icons.directions_walk),
              label: Text(_isWalking ? 'Stop Walking' : 'Start Walking'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
