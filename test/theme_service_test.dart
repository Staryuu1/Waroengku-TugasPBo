import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waroengku/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme service stores and restores dark mode', () async {
    SharedPreferences.setMockInitialValues({});

    final service = ThemeService.instance;
    await service.init();

    expect(service.themeMode, ThemeMode.system);

    await service.setThemeMode(ThemeMode.dark);
    expect(service.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
