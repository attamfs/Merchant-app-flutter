import 'package:flutter/material.dart';

class SystemConfigScreen extends StatelessWidget {
  const SystemConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('System Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _buildConfigItem('App Name', 'Merchant App'),
              const Divider(height: 1),
              _buildConfigItem('Version', '1.0.0'),
              const Divider(height: 1),
              _buildConfigItem('Build Number', '1001'),
              const Divider(height: 1),
              _buildConfigItem('Environment', 'UAT'),
              const Divider(height: 1),
              _buildConfigItem('Database Connection', 'Connected', isSuccess: true),
              const Divider(height: 1),
              _buildConfigItem('Payment Gateway', 'Configured', isSuccess: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]),
          ),
          Row(
            children: [
              if (isSuccess)
                const Padding(
                  padding: EdgeInsets.only(right: 6.0),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: isSuccess ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
