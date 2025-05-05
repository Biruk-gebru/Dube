import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final String _langPrefKey = 'languageCode';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String langCode = prefs.getString(_langPrefKey) ?? 'en';
      _locale = Locale(langCode);
      notifyListeners();
    } catch (e) {
      // Error handling without print
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langPrefKey, locale.languageCode);
    } catch (e) {
      // Error handling without print
    }
  }

  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'en' ? const Locale('am') : const Locale('en');
    await setLocale(newLocale);
  }
} 