# Настройка иконки приложения

## Шаг 1: Конвертация SVG в PNG

Ваша иконка находится в `assets/icon.svg`. Её нужно конвертировать в PNG формат.

### Способ 1: Онлайн конвертер (самый простой)
1. Откройте https://svgtopng.com/ или https://cloudconvert.com/svg-to-png
2. Загрузите файл `assets/icon.svg`
3. Установите размер **1024x1024 пикселей**
4. Скачайте результат и сохраните как `mobile/assets/icon.png`

### Способ 2: Figma/Sketch/Adobe Illustrator
1. Откройте `assets/icon.svg` в графическом редакторе
2. Экспортируйте как PNG с размером 1024x1024px
3. Сохраните как `mobile/assets/icon.png`

### Способ 3: Командная строка (требует установки rsvg)
```bash
# Установите librsvg (если есть brew)
brew install librsvg

# Конвертируйте
rsvg-convert -w 1024 -h 1024 assets/icon.svg -o assets/icon.png
```

## Шаг 2: Создание foreground иконки для Android Adaptive Icons

Для Android нужна отдельная foreground иконка (без фона):

1. Создайте копию SVG без фонового rect
2. Конвертируйте в PNG 1024x1024
3. Сохраните как `mobile/assets/icon_foreground.png`

**Пример SVG для foreground** (сохраните как `assets/icon_foreground.svg`):
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <!-- Кольцо прогресса -->
  <circle cx="256" cy="256" r="180" fill="none" stroke="#1e3a5f" stroke-width="8"/>
  <circle cx="256" cy="256" r="180" fill="none" stroke="#06b6d4" stroke-width="8"
          stroke-linecap="round" stroke-dasharray="848" stroke-dashoffset="212"
          transform="rotate(-90 256 256)"/>

  <!-- Крест -->
  <g fill="#f8fafc">
    <rect x="240" y="152" width="32" height="208" rx="4"/>
    <rect x="168" y="224" width="176" height="32" rx="4"/>
  </g>
</svg>
```

## Шаг 3: Установка зависимостей и генерация иконок

```bash
cd mobile

# Установите зависимости
flutter pub get

# Сгенерируйте иконки для всех платформ
dart run flutter_launcher_icons
```

## Шаг 4: Проверка

После генерации иконки будут автоматически размещены в:
- **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Проверьте работу:
```bash
flutter run
```

## Текущая конфигурация

В `pubspec.yaml` настроено:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  adaptive_icon_background: "#0f172a"
  adaptive_icon_foreground: "assets/icon_foreground.png"
```

- `image_path` - основная иконка для iOS и legacy Android
- `adaptive_icon_foreground` - передний слой для Android 8+
- `adaptive_icon_background` - цвет фона (#0f172a - ваш темно-синий)

## Дополнительные настройки (опционально)

Если хотите разные иконки для разных платформ:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.png"
  image_path_android: "assets/icon_android.png"
  image_path_ios: "assets/icon_ios.png"
```

Для веб-версии добавьте:
```yaml
  web:
    generate: true
    image_path: "assets/icon.png"
```
