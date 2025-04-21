import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final currentUser = firebaseService.getCurrentUser();

    if (currentUser != null) {
      final userProfile = await firebaseService.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        setState(() {
          _user = userProfile;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    await firebaseService.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showEditNameDialog() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _updateProfile(name: nameController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog() {
    if (_user == null) return;

    final phoneController = TextEditingController(text: _user!.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (phoneController.text.trim().isNotEmpty) {
                _updateProfile(phoneNumber: phoneController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile({String? name, String? phoneNumber}) async {
    if (_user == null) return;

    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    final updatedUser = UserModel(
      id: _user!.id,
      name: name ?? _user!.name,
      email: _user!.email,
      phoneNumber: phoneNumber ?? _user!.phoneNumber,
      emergencyContacts: _user!.emergencyContacts,
    );

    await firebaseService.updateUserProfile(updatedUser);
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text('Unable to load profile. Please try again.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue,
                              child: Text(
                                _user!.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _user!.email,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(_user!.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _showEditNameDialog,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(_user!.email),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone Number'),
                          subtitle: Text(_user!.phoneNumber),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _showEditPhoneDialog,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.contacts),
                          title: const Text('Emergency Contacts'),
                          subtitle: Text(
                            '${_user!.emergencyContacts.length} contacts added',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/emergency-contacts');
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sign Out'),
                          onTap: _signOut,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'WalkGuardian v1.0.0',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
