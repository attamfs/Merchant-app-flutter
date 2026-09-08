import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildLanguageItem(context, languageProvider, 'English', 'en'),
              _buildLanguageItem(context, languageProvider, 'العربية', 'ar'),
              _buildLanguageItem(context, languageProvider, 'हिंदी', 'hi'),
              _buildLanguageItem(context, languageProvider, 'اردو', 'ur'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, LanguageProvider provider, String label, String value) {
    final isSelected = provider.currentLanguage == value;
    return GestureDetector(
      onTap: () {
        provider.setLanguage(value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

