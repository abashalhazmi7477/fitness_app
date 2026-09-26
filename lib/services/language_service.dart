import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _key = 'app_language';

  static final ValueNotifier<Locale> locale =
      ValueNotifier(const Locale('ar'));

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_key) ?? 'ar';
    locale.value = Locale(language);
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language);
    locale.value = Locale(language);
  }

  static bool get isEnglish => locale.value.languageCode == 'en';

  static bool get isArabic => locale.value.languageCode == 'ar';

  static TextDirection get direction =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}
