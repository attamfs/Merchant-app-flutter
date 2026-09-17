import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_provider.dart';

class TranslationProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  Map<String, dynamic> _translations = {};
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  TranslationProvider() {
    _fetchTranslations();
  }

  void updateLanguage(LanguageProvider languageProvider) {
    if (_currentLanguage != languageProvider.currentLanguage) {
      _currentLanguage = languageProvider.currentLanguage;
      notifyListeners();
    }
  }

  void _fetchTranslations() {
    try {
      FirebaseFirestore.instance.collection('translations').snapshots().listen((snapshot) {
        final Map<String, dynamic> newTranslations = {};
        for (var doc in snapshot.docs) {
          newTranslations[doc.id] = doc.data();
        }
        _translations = newTranslations;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('Error fetching translations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  String t(String key, {String? defaultEn}) {
    if (_translations.containsKey(key)) {
      final item = _translations[key];
      if (item is Map<String, dynamic>) {
        if (item.containsKey(_currentLanguage) && item[_currentLanguage] != null && item[_currentLanguage].toString().trim().isNotEmpty) {
          return item[_currentLanguage].toString();
        }
        if (item.containsKey('en') && item['en'] != null && item['en'].toString().trim().isNotEmpty) {
          return item['en'].toString();
        }
      }
    } else {
      // Auto-upload missing key to Firestore
      _uploadMissingKey(key, defaultEn ?? key);
      // Add locally to prevent redundant uploads
      _translations[key] = {'en': defaultEn ?? key};
    }
    return defaultEn ?? key;
  }

  Future<void> _uploadMissingKey(String key, String fallbackEn) async {
    try {
      // Avoid uploading empty or null keys
      if (key.trim().isEmpty) return;
      
      final docRef = FirebaseFirestore.instance.collection('translations').doc(key);
      await docRef.set({
        'en': fallbackEn,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error uploading missing translation key: $e');
    }
  }
}
