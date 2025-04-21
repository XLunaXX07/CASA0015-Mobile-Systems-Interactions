import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _isLoading = true;
  late UserModel _user;
  List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final currentUser = firebaseService.getCurrentUser();
    
    if (currentUser != null) {
      final userProfile = await firebaseService.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        setState(() {
          _user = userProfile;
          _contacts = userProfile.emergencyContacts;
          _isLoading = false;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && 
                  phoneController.text.trim().isNotEmpty) {
                _addContact(
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  relationshipController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addContact(String name, String phone, String relationship) async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final contact = EmergencyContact(
      name: name,
      phoneNumber: phone,
      relationship: relationship,
    );
    
    await firebaseService.addEmergencyContact(_user.id, contact);
    await _loadContacts();
  }
  
  Future<void> _removeContact(EmergencyContact contact) async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    await firebaseService.removeEmergencyContact(_user.id, contact.phoneNumber);
    await _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Your emergency contacts will be notified when you trigger an SOS alert or when our system detects a potential emergency.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add at least one emergency contact for better safety.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.contacts,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No emergency contacts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add emergency contacts to notify in case of emergencies',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showAddContactDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Contact'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  contact.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(contact.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact.phoneNumber),
                                  if (contact.relationship.isNotEmpty)
                                    Text(
                                      contact.relationship,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: contact.relationship.isNotEmpty,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeContact(contact),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _contacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddContactDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 