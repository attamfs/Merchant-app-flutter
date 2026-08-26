import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _buildLanguageItem('English', 'en', isRtl: false),
              const Divider(height: 1),
              _buildLanguageItem('العربية', 'ar', isRtl: true),
              const Divider(height: 1),
              _buildLanguageItem('हिंदी', 'hi', isRtl: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String name, String code, {required bool isRtl}) {
    final isSelected = _selectedLanguage == code;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
        // Real implementation would save this setting and notify providers
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Language preference saved locally for now.')),
        );
      },
    );
  }
}
