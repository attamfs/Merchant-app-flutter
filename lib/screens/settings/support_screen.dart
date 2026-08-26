import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
              ),
              const Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.smart_toy_outlined,
                title: 'Atta Chat (AI)',
                subtitle: 'Get instant answers from AI',
                iconColor: const Color(0xFF1EBB5E),
              ),
              const Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.phone_in_talk_outlined,
                title: 'Voice Support',
                subtitle: 'Call our support center',
              ),
              const Divider(height: 1),
              _buildSupportItem(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Us',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title Coming Soon!')),
        );
      },
    );
  }
}
