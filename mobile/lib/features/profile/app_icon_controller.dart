import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';

import 'data/app_icon_variant.dart';

const _kAppIconKey = 'app_icon_variant';

/// Провайдер текущей иконки приложения
final appIconControllerProvider =
    StateNotifierProvider<AppIconController, AppIconVariant>((ref) {
  return AppIconController();
});

class AppIconController extends StateNotifier<AppIconVariant> {
  AppIconController() : super(AppIconVariant.main) {
    _loadSavedIcon();
  }

  Future<void> _loadSavedIcon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kAppIconKey);
      state = AppIconVariant.fromId(savedId);
    } catch (e) {
      // Игнорируем ошибки загрузки
    }
  }

  Future<bool> setIcon(AppIconVariant variant) async {
    try {
      // Устанавливаем иконку
      // Для iOS передаем имя из Assets (AppIcon, AppIcon-amber и т.д.)
      // Для Android используется activity-alias из AndroidManifest
      if (variant == AppIconVariant.main) {
        // Возвращаем к дефолтной иконке
        await FlutterDynamicIcon.setAlternateIconName(null);
      } else {
        // Устанавливаем альтернативную иконку
        await FlutterDynamicIcon.setAlternateIconName(variant.id);
      }

      // Сохраняем выбор
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAppIconKey, variant.id);

      state = variant;
      return true;
    } catch (e) {
      // Сохраняем локально даже при ошибке для отображения в UI
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kAppIconKey, variant.id);
        state = variant;
      } catch (_) {}
      return false;
    }
  }

  Future<String?> getCurrentIconName() async {
    try {
      return await FlutterDynamicIcon.getAlternateIconName();
    } catch (e) {
      return null;
    }
  }
}
