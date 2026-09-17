import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class SystemConfigScreen extends StatelessWidget {
  SystemConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('System Configuration'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _buildConfigItem('App Name'.tr(context), 'Merchant App'.tr(context)),
              Divider(height: 1),
              _buildConfigItem('Version'.tr(context), '1.0.0'),
              Divider(height: 1),
              _buildConfigItem('Build Number'.tr(context), '1001'),
              Divider(height: 1),
              _buildConfigItem('Environment'.tr(context), 'UAT'.tr(context)),
              Divider(height: 1),
              _buildConfigItem('Database Connection'.tr(context), 'Connected'.tr(context), isSuccess: true),
              Divider(height: 1),
              _buildConfigItem('Payment Gateway'.tr(context), 'Configured'.tr(context), isSuccess: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Padding(
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
