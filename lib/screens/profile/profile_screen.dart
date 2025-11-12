
import 'package:flutter/material.dart';

// All localization and provider logic has been removed.

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final String fullName = userData?['fullName'] as String? ?? 'John Doe';
    final String email = userData?['email'] as String? ?? 'john.doe@example.com';
    final String mobile = userData?['mobile'] as String? ?? '+1234567890';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Profile', // Reverted to a hardcoded string
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildProfileHeader(fullName, email, context),
          const SizedBox(height: 24),
          _buildInfoCard(mobile),
          const SizedBox(height: 24),
          // The settings card has been removed.
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String email, BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String mobile) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.green[700]),
              title: const Text('Mobile', style: TextStyle(fontFamily: 'Poppins')),
              subtitle: Text(mobile, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text('Logout', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[400],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
