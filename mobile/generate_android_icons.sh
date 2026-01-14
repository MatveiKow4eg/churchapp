#!/bin/bash

echo "Генерация Android иконок..."

variants=("dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

for variant in "${variants[@]}"; do
    echo "Генерация для $variant..."

    # Создаем временный конфиг
    cat > "temp_config.yaml" <<EOF
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon_${variant}.png"
  adaptive_icon_background: "#0f172a"
  adaptive_icon_foreground: "assets/icon_${variant}.png"
EOF

    # Генерируем
    dart run flutter_launcher_icons -f temp_config.yaml 2>&1 | grep -v "deprecated\|NoConfigFoundException" || true

    # Копируем и переименовываем
    for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
        src_dir="android/app/src/main/res/mipmap-${density}"
        if [ -f "${src_dir}/ic_launcher.png" ]; then
            cp "${src_dir}/ic_launcher.png" "${src_dir}/ic_launcher_${variant}.png"
        fi
    done

    rm -f temp_config.yaml
    echo "  ✓ $variant готов"
done

echo ""
echo "✅ Генерация Android иконок завершена!"
