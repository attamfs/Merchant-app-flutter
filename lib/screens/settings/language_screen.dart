import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/translation_provider.dart';

class LanguageScreen extends StatelessWidget {
  LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TranslationProvider>().t;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t('Language', defaultEn: 'Language'), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

