import 'dart:io' show Platform;

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
      final variant = AppIconVariant.fromId(savedId);
      state = variant;

      // Не применяем иконку автоматически на iOS при входе в настройки.
      // На iOS системный диалог показывается при каждой установке alternate icon,
      // даже если значение не меняется, поэтому делаем это только по явному действию пользователя.
      if (Platform.isAndroid) {
        await FlutterDynamicIcon.setAlternateIconName(variant.androidActivityAlias);
      }
    } catch (e) {
      // Игнорируем ошибки загрузки/применения
    }
  }

  Future<bool> setIcon(AppIconVariant variant) async {
    try {
      // iOS: передаём ключ из Info.plist -> CFBundleAlternateIcons ("amber", ...)
      // Android: передаём имя activity-alias из AndroidManifest (".MainActivityAmber", ...)
      if (Platform.isIOS) {
        await FlutterDynamicIcon.setAlternateIconName(variant.iosIconName);
      } else if (Platform.isAndroid) {
        await FlutterDynamicIcon.setAlternateIconName(variant.androidActivityAlias);
      } else {
        // На остальных платформах просто меняем состояние/сохранение.
      }

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
