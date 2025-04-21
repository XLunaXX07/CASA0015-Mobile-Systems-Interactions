import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/walk_session.dart';
import '../../services/firebase_service.dart';
import '../../services/walk_service.dart';
import 'walk_details_screen.dart';

class WalkHistoryScreen extends StatefulWidget {
  const WalkHistoryScreen({super.key});

  @override
  State<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends State<WalkHistoryScreen> {
  bool _isLoading = true;
  List<WalkSession> _walkSessions = [];
  late WalkService _walkService;

  @override
  void initState() {
    super.initState();
    _initializeWalkService();
  }

  Future<void> _initializeWalkService() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _walkService = WalkService(firebaseService, context);
// Get current user
    final currentUser = firebaseService.getCurrentUser();
    if (currentUser != null) {
      // Load user profile
      final userProfile = await firebaseService.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        // Initialize walk service
        await _walkService.initialize(userProfile);
      }
    }
    await _loadWalkHistory();
  }

  Future<void> _loadWalkHistory() async {
    setState(() {
      _isLoading = true;
    });

    _walkSessions = await _walkService.getPastWalkSessions();
    print(_walkSessions.toString());
    setState(() {
      _isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalkHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _walkSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No walk history',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start walking to track your routes',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _walkSessions.length,
                  itemBuilder: (context, index) {
                    final session = _walkSessions[index];
                    final startDate = DateFormat('MMM dd, yyyy').format(session.startTime);
                    final startTime = DateFormat('hh:mm a').format(session.startTime);
                    final hasEmergencyEvents = session.emergencyEvents.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalkDetailsScreen(
                                walkSession: session,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_walk,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Walk on $startDate',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (session.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Started at $startTime',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      label: 'Distance',
                                      value: _formatDistance(session.distanceCovered),
                                      icon: Icons.straighten,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      label: 'Duration',
                                      value: _formatDuration(session.duration),
                                      icon: Icons.timer,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasEmergencyEvents) ...[
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${session.emergencyEvents.length} emergency ${session.emergencyEvents.length == 1 ? 'event' : 'events'} detected',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
