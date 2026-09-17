import 'package:flutter/material.dart';
import '../home/my_store_screen.dart';
import '../auth/forgot_pin_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Account'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.store,
                title: 'My Store'.tr(context),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyStoreScreen()),
                  );
                },
              ),
              Divider(height: 1),
              _buildSettingsItem(
                icon: Icons.password,
                title: 'Reset PIN'.tr(context),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPinScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
