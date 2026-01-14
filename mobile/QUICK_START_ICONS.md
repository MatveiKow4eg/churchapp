# Быстрый старт: Динамические иконки

## ✅ Что уже сделано

1. **UI добавлен** - в настройках появилась секция "Иконка приложения" с горизонтальной прокруткой вариантов
2. **Код готов** - контроллер и модель данных созданы, поддержка 11 вариантов иконок
3. **Пакет установлен** - `flutter_dynamic_icon: ^2.1.0` добавлен и загружен
4. **Основная иконка** - `icon_main.png` уже сгенерирована для Android и iOS

## 📋 Что нужно сделать вам

### Быстрый тест (минимальная настройка)

Для быстрого тестирования функционала достаточно настроить 1-2 дополнительные иконки:

#### Шаг 1: iOS (1 альтернативная иконка для теста)

1. Сгенерируйте иконки для `icon_amber.png` через https://www.appicon.co/
2. Создайте папку `ios/Runner/Assets.xcassets/AppIcon-amber.appiconset/`
3. Скопируйте туда все PNG + Contents.json
4. Откройте `ios/Runner/Info.plist` и добавьте в конец (перед `</dict></plist>`):

```xml
<key>CFBundleIcons</key>
<dict>
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>amber</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-amber</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
    </dict>
</dict>
```

#### Шаг 2: Android (1 альтернативная иконка для теста)

1. Сгенерируйте иконки для `icon_amber.png`
2. Скопируйте в `android/app/src/main/res/`:
   - `mipmap-mdpi/ic_launcher_amber.png`
   - `mipmap-hdpi/ic_launcher_amber.png`
   - `mipmap-xhdpi/ic_launcher_amber.png`
   - `mipmap-xxhdpi/ic_launcher_amber.png`
   - `mipmap-xxxhdpi/ic_launcher_amber.png`

3. Откройте `android/app/src/main/AndroidManifest.xml` и добавьте внутри `<application>`:

```xml
<activity-alias
    android:name=".MainActivityAmber"
    android:enabled="false"
    android:icon="@mipmap/ic_launcher_amber"
    android:targetActivity=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity-alias>
```

#### Шаг 3: Тест

```bash
flutter run
```

Откройте Настройки → Иконка приложения → выберите "Янтарная".

### Полная настройка

Для всех 11 вариантов следуйте подробной инструкции в [DYNAMIC_ICONS_SETUP.md](DYNAMIC_ICONS_SETUP.md).

## 🎨 Доступные варианты иконок

1. **Основная** (`icon_main.png`) - уже установлена ✅
2. **Янтарная** (`icon_amber.png`)
3. **Темно-бирюзовая** (`icon_dark_cyan.png`)
4. **Темно-золотая** (`icon_dark_gold.png`)
5. **Темно-фиолетовая** (`icon_dark_purple.png`)
6. **Изумрудная** (`icon_emerald.png`)
7. **Индиго** (`icon_indigo.png`)
8. **Монохромная** (`icon_mono.png`)
9. **Розовая** (`icon_pink.png`)
10. **Красная** (`icon_red.png`)
11. **Небесная** (`icon_sky.png`)

## 🔧 Структура кода

**Модель данных**: [lib/features/profile/data/app_icon_variant.dart](lib/features/profile/data/app_icon_variant.dart)
**Контроллер**: [lib/features/profile/app_icon_controller.dart](lib/features/profile/app_icon_controller.dart)
**UI**: [lib/features/profile/presentation/settings_screen.dart:264-386](lib/features/profile/presentation/settings_screen.dart)

## 📱 Как работает

1. Пользователь выбирает иконку в настройках
2. `AppIconController` вызывает `FlutterDynamicIcon.setAlternateIconName()`
3. Для iOS передается имя AppIcon set (например, "amber")
4. Для Android активируется/деактивируется нужный activity-alias
5. Выбор сохраняется в SharedPreferences
6. При следующем запуске приложения иконка остается выбранной

## ⚠️ Ограничения

- **iOS**: Показывает системный диалог при смене иконки (нельзя отключить)
- **Android**: Требует перезапуск launcher для применения (автоматически)
- **Минимальные версии**:
  - iOS 10.3+
  - Android 5.0+ (API 21+)

## 🚀 Упрощенный вариант

Если не хотите настраивать все 11 вариантов, просто уменьшите список в `app_icon_variant.dart`:

```dart
enum AppIconVariant {
  main('main', 'Основная', 'icon_main.png'),
  amber('amber', 'Янтарная', 'icon_amber.png'),
  // Закомментируйте остальные
}
```

Тогда в UI будет только 2 варианта.
