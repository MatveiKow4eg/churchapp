#!/bin/bash

# Скрипт для создания iOS AppIcon наборов
# Требует: sips (встроен в macOS для изменения размера изображений)

echo "Генерация iOS AppIcon наборов..."

ASSETS_DIR="ios/Runner/Assets.xcassets"
ICONS_SOURCE="assets"

# Список вариантов
variants=("amber" "dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

# Функция для создания AppIcon набора
create_appicon_set() {
    local variant=$1
    local icon_set_dir="${ASSETS_DIR}/AppIcon-${variant}.appiconset"

    echo "Создание ${icon_set_dir}..."
    mkdir -p "${icon_set_dir}"

    # Создаем Contents.json
    cat > "${icon_set_dir}/Contents.json" <<'EOF'
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

    # Генерируем иконки разных размеров с помощью ImageMagick
    local source_icon="${ICONS_SOURCE}/icon_${variant}.png"
    local BACKGROUND_COLOR="#0f172a"

    if [ ! -f "${source_icon}" ]; then
        echo "⚠️  Файл ${source_icon} не найден, пропускаем..."
        return
    fi

    echo "  Генерация иконок из ${source_icon}..."

    # Функция для создания иконки с фоном
    create_sized_icon() {
        local size=$1
        local output=$2
        convert -size "${size}x${size}" xc:"${BACKGROUND_COLOR}" \
            \( "${source_icon}" -resize "${size}x${size}" \) \
            -gravity center \
            -composite \
            -alpha off \
            -type TrueColor \
            -define png:color-type=2 \
            "${output}" 2>/dev/null
    }

    # iPhone размеры
    create_sized_icon 40 "${icon_set_dir}/Icon-App-20x20@2x.png"
    create_sized_icon 60 "${icon_set_dir}/Icon-App-20x20@3x.png"
    create_sized_icon 29 "${icon_set_dir}/Icon-App-29x29@1x.png"
    create_sized_icon 58 "${icon_set_dir}/Icon-App-29x29@2x.png"
    create_sized_icon 87 "${icon_set_dir}/Icon-App-29x29@3x.png"
    create_sized_icon 80 "${icon_set_dir}/Icon-App-40x40@2x.png"
    create_sized_icon 120 "${icon_set_dir}/Icon-App-40x40@3x.png"
    create_sized_icon 120 "${icon_set_dir}/Icon-App-60x60@2x.png"
    create_sized_icon 180 "${icon_set_dir}/Icon-App-60x60@3x.png"
    create_sized_icon 1024 "${icon_set_dir}/Icon-App-1024x1024@1x.png"

    echo "  ✓ Создано ${icon_set_dir}"
}

# Генерируем для каждого варианта
for variant in "${variants[@]}"; do
    create_appicon_set "$variant"
done

echo ""
echo "✅ Генерация iOS иконок завершена!"
echo ""
echo "Следующие шаги:"
echo "1. Info.plist уже настроен"
echo "2. Запустите: flutter run"
echo "3. Проверьте смену иконок в настройках"
