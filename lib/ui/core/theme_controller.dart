import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, retro }

class ThemeController extends ChangeNotifier {
  ThemeController({this.preferences});

  static const _key = 'byte_task_theme_mode';
  SharedPreferences? preferences;
  AppThemeMode _mode = AppThemeMode.light;

  AppThemeMode get mode => _mode;

  Future<void> load() async {
    preferences ??= await SharedPreferences.getInstance();
    final saved = preferences!.getString(_key);
    _mode = AppThemeMode.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => AppThemeMode.light,
    );
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    preferences ??= await SharedPreferences.getInstance();
    await preferences!.setString(_key, mode.name);
  }
}
