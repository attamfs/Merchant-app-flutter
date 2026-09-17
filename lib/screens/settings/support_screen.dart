import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class SupportScreen extends StatelessWidget {
  SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Support'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _buildSupportItem(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat'.tr(context),
                subtitle: 'Chat with our support team'.tr(context),
              ),
              Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.smart_toy_outlined,
                title: 'Atta Chat (AI)'.tr(context),
                subtitle: 'Get instant answers from AI'.tr(context),
                iconColor: Color(0xFF1EBB5E),
              ),
              Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.phone_in_talk_outlined,
                title: 'Voice Support'.tr(context),
                subtitle: 'Call our support center'.tr(context),
              ),
              Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Us'.tr(context),
                subtitle: 'support@atta.com',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title Coming Soon!'.tr(context))),
        );
      },
    );
  }
}
