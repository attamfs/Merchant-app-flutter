import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../settings/account_screen.dart';
import '../settings/language_screen.dart';
import '../settings/system_config_screen.dart';
import '../settings/about_screen.dart';
import '../settings/support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.person,
                    title: 'Account',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.settings_system_daydream,
                    title: 'System Configuration',
                    iconColor: Colors.blue[600],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemConfigScreen())),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.info,
                    title: 'About App',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.message,
                    title: 'Support',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'uatatta 1.01',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature Settings Coming Soon!')),
    );
  }
}
