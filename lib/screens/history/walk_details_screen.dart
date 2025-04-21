import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/walk_session.dart';

class WalkDetailsScreen extends StatefulWidget {
  final WalkSession walkSession;

  const WalkDetailsScreen({
    super.key,
    required this.walkSession,
  });

  @override
  State<WalkDetailsScreen> createState() => _WalkDetailsScreenState();
}

class _WalkDetailsScreenState extends State<WalkDetailsScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.walkSession.path.isEmpty) return;

    print(widget.walkSession.toJson());

    // Add path polyline
    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId(widget.walkSession.id),
          points: widget.walkSession.path,
          color: Colors.blue,
          width: 5,
        ),
      };
    });

    // Add start and end markers
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: widget.walkSession.path.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      };

      // Add end marker only if the session is not active
      if (!widget.walkSession.isActive && widget.walkSession.path.length > 1) {
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: widget.walkSession.path.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
        );
      }

      // Add emergency event markers
      // for (var event in widget.walkSession.emergencyEvents) {
      //   _markers.add(
      //     Marker(
      //       markerId: MarkerId('emergency_${event.id}'),
      //       position: event.location,
      //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      //       infoWindow: InfoWindow(
      //         title: _getEmergencyTypeString(event.type),
      //         snippet: DateFormat('MMM dd, yyyy hh:mm a').format(event.timestamp),
      //       ),
      //     ),
      //   );
      // }
    });
  }

  String _getEmergencyTypeString(EmergencyType type) {
    switch (type) {
      case EmergencyType.sos:
        return 'SOS Alert';
      case EmergencyType.fall:
        return 'Fall Detected';
      case EmergencyType.inactivity:
        return 'Inactivity Detected';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (widget.walkSession.path.isNotEmpty) {
      // Calculate bounds
      double minLat = widget.walkSession.path.first.latitude;
      double maxLat = widget.walkSession.path.first.latitude;
      double minLng = widget.walkSession.path.first.longitude;
      double maxLng = widget.walkSession.path.first.longitude;

      for (final point in widget.walkSession.path) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // Add padding
      final padding = 0.02;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      // Set camera bounds
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50, // padding
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.walkSession;
    final startDate = DateFormat('EEEE, MMM dd, yyyy').format(session.startTime);
    final startTime = DateFormat('hh:mm a').format(session.startTime);
    final endTime =
        session.endTime != null ? DateFormat('hh:mm a').format(session.endTime!) : 'Ongoing';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Details'),
      ),
      body: Column(
        children: [
          // Map view
          Expanded(
            flex: 3,
            child: session.path.isEmpty
                ? const Center(
                    child: Text('No path data available'),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: session.path.first,
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    onMapCreated: _onMapCreated,
                  ),
          ),

          // Tab bar
          // Material(
          //   color: Colors.white,
          //   elevation: 4,
          //   child: TabBar(
          //     onTap: (index) {
          //       setState(() {
          //         _selectedTabIndex = index;
          //       });
          //     },
          //     labelColor: Colors.blue,
          //     unselectedLabelColor: Colors.grey,
          //     indicatorColor: Colors.blue,
          //     tabs: [
          //       const Tab(
          //         icon: Icon(Icons.info_outline),
          //         text: 'Details',
          //       ),
          //       Tab(
          //         icon: const Icon(Icons.warning_amber_outlined),
          //         text: 'Events (${session.emergencyEvents.length})',
          //       ),
          //     ],
          //   ),
          // ),

          // Tab content
          // Expanded(
          //   flex: 2,
          //   child: IndexedStack(
          //     index: _selectedTabIndex,
          //     children: [
          //       // Details tab
          //       SingleChildScrollView(
          //         padding: const EdgeInsets.all(16),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             // Date and time
          //             const Text(
          //               'Date & Time',
          //               style: TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //             const SizedBox(height: 8),
          //             ListTile(
          //               contentPadding: EdgeInsets.zero,
          //               leading: const Icon(Icons.calendar_today),
          //               title: const Text('Date'),
          //               subtitle: Text(startDate),
          //             ),
          //             ListTile(
          //               contentPadding: EdgeInsets.zero,
          //               leading: const Icon(Icons.access_time),
          //               title: const Text('Start Time'),
          //               subtitle: Text(startTime),
          //             ),
          //             ListTile(
          //               contentPadding: EdgeInsets.zero,
          //               leading: const Icon(Icons.timer_off),
          //               title: const Text('End Time'),
          //               subtitle: Text(endTime),
          //             ),

          //             const Divider(),

          //             // Statistics
          //             const Text(
          //               'Statistics',
          //               style: TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //             const SizedBox(height: 8),
          //             ListTile(
          //               contentPadding: EdgeInsets.zero,
          //               leading: const Icon(Icons.straighten),
          //               title: const Text('Distance'),
          //               subtitle: Text(_formatDistance(session.distanceCovered)),
          //             ),
          //             ListTile(
          //               contentPadding: EdgeInsets.zero,
          //               leading: const Icon(Icons.timer),
          //               title: const Text('Duration'),
          //               subtitle: Text(_formatDuration(session.duration)),
          //             ),
          //             if (session.duration.inSeconds > 0 && session.distanceCovered > 0)
          //               ListTile(
          //                 contentPadding: EdgeInsets.zero,
          //                 leading: const Icon(Icons.speed),
          //                 title: const Text('Average Speed'),
          //                 subtitle: Text(
          //                   '${(session.distanceCovered / session.duration.inSeconds * 3.6).toStringAsFixed(2)} km/h',
          //                 ),
          //               ),
          //           ],
          //         ),
          //       ),

          //       // Events tab
          //       session.emergencyEvents.isEmpty
          //           ? const Center(
          //               child: Text('No emergency events'),
          //             )
          //           : ListView.builder(
          //               itemCount: session.emergencyEvents.length,
          //               itemBuilder: (context, index) {
          //                 final event = session.emergencyEvents[index];
          //                 final eventTime = DateFormat('hh:mm a').format(event.timestamp);
          //                 final eventDate = DateFormat('MMM dd, yyyy').format(event.timestamp);

          //                 IconData eventIcon;
          //                 Color eventColor;

          //                 switch (event.type) {
          //                   case EmergencyType.sos:
          //                     eventIcon = Icons.sos;
          //                     eventColor = Colors.red;
          //                     break;
          //                   case EmergencyType.fall:
          //                     eventIcon = Icons.person_outline;
          //                     eventColor = Colors.orange;
          //                     break;
          //                   case EmergencyType.inactivity:
          //                     eventIcon = Icons.accessibility_new;
          //                     eventColor = Colors.amber;
          //                     break;
          //                 }

          //                 return ListTile(
          //                   leading: CircleAvatar(
          //                     backgroundColor: eventColor.withOpacity(0.2),
          //                     child: Icon(
          //                       eventIcon,
          //                       color: eventColor,
          //                     ),
          //                   ),
          //                   title: Text(
          //                     _getEmergencyTypeString(event.type),
          //                     style: const TextStyle(
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                   subtitle: Text('$eventDate at $eventTime'),
          //                   trailing: IconButton(
          //                     icon: const Icon(Icons.place),
          //                     onPressed: () {
          //                       // Focus the map on this event
          //                       _mapController.animateCamera(
          //                         CameraUpdate.newLatLngZoom(
          //                           event.location,
          //                           18,
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                 );
          //               },
          //             ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
