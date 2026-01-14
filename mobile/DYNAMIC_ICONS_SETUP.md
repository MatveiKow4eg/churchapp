# Настройка динамических иконок приложения

## Что сделано

✅ Добавлен UI для выбора иконок в настройках
✅ Создана модель данных с 11 вариантами иконок
✅ Добавлен контроллер для переключения иконок
✅ Установлен пакет `flutter_dynamic_icon`

## Что нужно сделать

### 1. Подготовка иконок

У вас уже есть PNG файлы в `mobile/assets/`:
- icon_main.png ✅
- icon_amber.png
- icon_dark_cyan.png
- icon_dark_gold.png
- icon_dark_purple.png
- icon_emerald.png
- icon_indigo.png
- icon_mono.png
- icon_pink.png
- icon_red.png
- icon_sky.png

Убедитесь, что все файлы имеют размер минимум 512x512, рекомендуется 1024x1024.

### 2. Генерация иконок для iOS

Для iOS нужно создать отдельные AppIcon sets для каждого варианта.

#### Вариант A: Ручная генерация (рекомендуется)

Используйте онлайн-генератор https://www.appicon.co/ или https://easyappicon.com/:

1. Загрузите каждую PNG иконку
2. Выберите платформу iOS
3. Скачайте сгенерированные Assets.xcassets
4. Для каждого варианта создайте папку в `ios/Runner/Assets.xcassets/`:
   - `AppIcon-amber.appiconset/`
   - `AppIcon-dark_cyan.appiconset/`
   - `AppIcon-dark_gold.appiconset/`
   - и т.д.
5. Скопируйте в каждую папку:
   - Все PNG файлы нужных размеров
   - Contents.json файл

#### Вариант B: Использование flutter_launcher_icons

Создайте отдельный конфиг для каждой иконки:

```yaml
# flutter_launcher_icons-amber.yaml
flutter_launcher_icons:
  android: false
  ios: true
  image_path: "assets/icon_amber.png"
  remove_alpha_ios: true
```

Запустите для каждого варианта:
```bash
dart run flutter_launcher_icons -f flutter_launcher_icons-amber.yaml
```

Затем вручную переименуйте папки в `ios/Runner/Assets.xcassets/` добавив суффикс:
- `AppIcon.appiconset` → `AppIcon-amber.appiconset`

### 3. Настройка Info.plist для iOS

Откройте `ios/Runner/Info.plist` и добавьте массив альтернативных иконок:

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
        <key>dark_cyan</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-dark_cyan</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>dark_gold</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-dark_gold</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>dark_purple</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-dark_purple</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>emerald</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-emerald</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>indigo</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-indigo</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>mono</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-mono</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>pink</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-pink</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>red</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-red</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>sky</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>AppIcon-sky</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
    </dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconFiles</key>
        <array>
            <string>AppIcon</string>
        </array>
    </dict>
</dict>
```

### 4. Настройка AndroidManifest.xml для Android

Откройте `android/app/src/main/AndroidManifest.xml` и добавьте activity-alias для каждой иконки **ПОСЛЕ** основной activity:

```xml
<application>
    <!-- Основная activity -->
    <activity
        android:name=".MainActivity"
        android:launchMode="singleTop"
        ...>
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity>

    <!-- Альтернативные иконки -->
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

    <activity-alias
        android:name=".MainActivityDarkCyan"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_dark_cyan"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityDarkGold"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_dark_gold"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityDarkPurple"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_dark_purple"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityEmerald"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_emerald"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityIndigo"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_indigo"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityMono"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_mono"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityPink"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_pink"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivityRed"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_red"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>

    <activity-alias
        android:name=".MainActivitySky"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_sky"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity-alias>
</application>
```

### 5. Генерация Android иконок

Для каждого варианта создайте иконки всех размеров:

```bash
# Используйте flutter_launcher_icons для каждого варианта
# Создайте временный конфиг:
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon_amber.png"
  adaptive_icon_background: "#0f172a"
  adaptive_icon_foreground: "assets/icon_amber.png"

# Сгенерируйте
dart run flutter_launcher_icons -f flutter_launcher_icons-amber.yaml

# Переименуйте сгенерированные файлы:
# ic_launcher.png → ic_launcher_amber.png во всех mipmap папках
```

Или вручную через онлайн-генераторы и скопируйте в:
- `android/app/src/main/res/mipmap-mdpi/ic_launcher_amber.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher_amber.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher_amber.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_amber.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_amber.png`

Повторите для всех вариантов.

### 6. Установка зависимостей

```bash
cd mobile
flutter pub get
```

### 7. Проверка работы

```bash
flutter run
```

Откройте настройки → Иконка приложения → Выберите любой вариант.

## Упрощенный вариант (только для тестирования)

Если хотите протестировать функционал без полной настройки:

1. Оставьте только основную иконку
2. Измените в коде количество вариантов на 1
3. Или создайте только 2-3 варианта для демо

## Автоматизация (опционально)

Создайте скрипт для автоматической генерации всех вариантов:

```bash
#!/bin/bash

variants=("amber" "dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

for variant in "${variants[@]}"; do
  echo "Generating icons for $variant..."

  # Создаем временный конфиг
  cat > "flutter_launcher_icons-$variant.yaml" <<EOF
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon_$variant.png"
  adaptive_icon_background: "#0f172a"
  adaptive_icon_foreground: "assets/icon_$variant.png"
  remove_alpha_ios: true
EOF

  # Генерируем
  dart run flutter_launcher_icons -f "flutter_launcher_icons-$variant.yaml"

  # Удаляем временный файл
  rm "flutter_launcher_icons-$variant.yaml"
done

echo "Done! Don't forget to rename generated assets manually."
```

## Структура после настройки

```
mobile/
├── assets/
│   ├── icon_main.png
│   ├── icon_amber.png
│   ├── icon_dark_cyan.png
│   └── ... (остальные иконки)
├── ios/
│   └── Runner/
│       ├── Info.plist (с CFBundleAlternateIcons)
│       └── Assets.xcassets/
│           ├── AppIcon.appiconset/
│           ├── AppIcon-amber.appiconset/
│           ├── AppIcon-dark_cyan.appiconset/
│           └── ... (остальные варианты)
└── android/
    └── app/
        └── src/
            └── main/
                ├── AndroidManifest.xml (с activity-alias)
                └── res/
                    ├── mipmap-mdpi/
                    │   ├── ic_launcher.png
                    │   ├── ic_launcher_amber.png
                    │   └── ... (остальные)
                    ├── mipmap-hdpi/
                    ├── mipmap-xhdpi/
                    ├── mipmap-xxhdpi/
                    └── mipmap-xxxhdpi/
```

## Полезные ссылки

- [flutter_dynamic_icon документация](https://pub.dev/packages/flutter_dynamic_icon)
- [iOS Alternate Icons гайд](https://developer.apple.com/documentation/uikit/uiapplication/2806818-setalternateiconname)
- [Android activity-alias документация](https://developer.android.com/guide/topics/manifest/activity-alias-element)
- [AppIcon генератор онлайн](https://www.appicon.co/)
