#!/bin/bash

# Скрипт для генерации всех вариантов иконок
# Использование: ./generate_icons.sh

echo "Генерация иконок для всех вариантов..."

# Список вариантов (кроме main - она уже сгенерирована)
variants=("amber" "dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

for variant in "${variants[@]}"; do
  echo ""
  echo "Генерация иконок для варианта: $variant"

  # Создаем временный конфиг для flutter_launcher_icons
  cat > "flutter_launcher_icons_${variant}.yaml" <<EOF
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon_${variant}.png"
  adaptive_icon_background: "#0f172a"
  adaptive_icon_foreground: "assets/icon_${variant}.png"
  remove_alpha_ios: false
EOF

  # Генерируем иконки
  dart run flutter_launcher_icons -f "flutter_launcher_icons_${variant}.yaml"

  # Переименовываем сгенерированные файлы
  echo "Переименование файлов для $variant..."

  for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    src_dir="android/app/src/main/res/mipmap-${density}"

    if [ -f "${src_dir}/ic_launcher.png" ]; then
      mv "${src_dir}/ic_launcher.png" "${src_dir}/ic_launcher_${variant}.png"
      echo "  ✓ mipmap-${density}/ic_launcher_${variant}.png"
    fi

    # Удаляем foreground если есть (не нужны для альтернативных иконок)
    rm -f "${src_dir}/ic_launcher_foreground.png" 2>/dev/null
  done

  # Удаляем временный конфиг
  rm "flutter_launcher_icons_${variant}.yaml"
done

echo ""
echo "✅ Генерация завершена!"
echo ""
echo "Следующие шаги:"
echo "1. Откройте android/app/src/main/AndroidManifest.xml"
echo "2. Добавьте activity-alias для каждого варианта (см. DYNAMIC_ICONS_SETUP.md)"
echo "3. Запустите flutter run для проверки"
