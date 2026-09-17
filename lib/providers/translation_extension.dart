import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'translation_provider.dart';

extension TranslationExtension on String {
  String tr(BuildContext context) {
    return context.watch<TranslationProvider>().t(this, defaultEn: this);
  }

  String trRead(BuildContext context) {
    return context.read<TranslationProvider>().t(this, defaultEn: this);
  }
}
