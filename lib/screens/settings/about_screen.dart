import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('About App'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Icon(Icons.store, size: 50, color: Color(0xFF1EBB5E)),
            ),
            SizedBox(height: 16),
            Text('GateE Merchant'.tr(context),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.01 (uatatta)'.tr(context),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildAboutItem(context, Icons.description, 'Terms of Service'.tr(context)),
                  Divider(height: 1),
                  _buildAboutItem(context, Icons.privacy_tip, 'Privacy Policy'.tr(context)),
                  Divider(height: 1),
                  _buildAboutItem(context, Icons.gavel, 'Legal Information'.tr(context)),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('© 2026 Atta Inc. All rights reserved.'.tr(context),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title Coming Soon!'.tr(context))),
        );
      },
    );
  }
}
