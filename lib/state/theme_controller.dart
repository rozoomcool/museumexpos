import 'package:flutter/material.dart';

/// Тёмная тема по умолчанию: экспонаты снимались на тёмном фоне, 3D-сцена
/// тоже тёмная. Светлая оставлена для яркого зала.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode != ThemeMode.light;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
