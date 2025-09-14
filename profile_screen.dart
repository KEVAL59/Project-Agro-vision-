import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Removed unnecessary import

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consistent font family
    const String font = 'Poppins';

    return Scaffold(
      backgroundColor: Colors.black,
      // Use a custom app bar for a more integrated look
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontFamily: font, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Profile Header ---
            _buildProfileHeader(font),
            const SizedBox(height: 40),

            // --- User Details Section ---
            _buildInfoSection(
              title: 'Personal Information',
              font: font,
              children: [
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: 'Agro Vision User',
                  font: font,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'user@agrovision.com',
                  font: font,
                ),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Mobile Number',
                  value: '0987654321',
                  font: font,
                ),
                _buildInfoTile( // Added City/Location Tile
                  icon: Icons.location_city_outlined,
                  label: 'City',
                  value: 'Placeholder City',
                  font: font,
                ),
                _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member Since',
                  value: 'Sep 2025',
                  font: font,
                  showDivider: false, // No divider for the last item
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- App Settings Section ---
            _buildInfoSection(
              title: 'Settings & Support',
              font: font,
              children: [
                _buildActionTile(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    font: font,
                    onTap: (){ /* Navigate to Settings Screen */ }
                ),
                _buildActionTile(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    font: font,
                    onTap: (){ /* Navigate to Help Screen */ }
                ),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  font: font,
                  onTap: (){ /* Show Terms and Conditions */ },
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- Logout Button ---
            _buildLogoutButton(context, font),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildProfileHeader(String font) {
    return Column(
      children: [
        // Circular profile avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.shade300,
              width: 3,
            ),
          ),
          child: const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.person,
              size: 70,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Agro Vision User',
          style: TextStyle(
            fontFamily: font,
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Placeholder City', // Updated to reflect city
          style: TextStyle(
            fontFamily: font,
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required String font, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
                fontFamily: font,
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required String font,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 24),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontFamily: font, color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(fontFamily: font, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 64.0), // Align with text
            child: Divider(color: Colors.grey[800], height: 1),
          ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String font,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[400]),
          title: Text(label, style: TextStyle(fontFamily: font, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 72.0),
            child: Divider(color: Colors.grey[800], height: 1),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, String font) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(
          'Log Out',
          style: TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Add logout logic here
          // For now, just pop back to the previous screen (likely dashboard or login)
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400.withAlpha(204),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
