#!/bin/bash

# Скрипт для исправления iOS иконок - удаление альфа-канала и добавление фона

echo "Исправление iOS иконок - удаление прозрачности..."

# Проверяем наличие ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick не установлен!"
    echo "Установите с помощью: brew install imagemagick"
    exit 1
fi

ASSETS_DIR="ios/Runner/Assets.xcassets"
ICONS_SOURCE="assets"
BACKGROUND_COLOR="#0f172a"

# Список вариантов
variants=("amber" "dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

# Функция для создания иконки без альфа-канала
create_icon_no_alpha() {
    local variant=$1
    local icon_set_dir="${ASSETS_DIR}/AppIcon-${variant}.appiconset"
    local source_icon="${ICONS_SOURCE}/icon_${variant}.png"

    if [ ! -f "${source_icon}" ]; then
        echo "⚠️  Файл ${source_icon} не найден, пропускаем..."
        return
    fi

    echo "Обработка ${variant}..."

    # Функция для создания иконки с фоном
    create_sized_icon() {
        local size=$1
        local output=$2
        # Создаем квадратный фон нужного размера
        # Затем накладываем иконку поверх
        convert -size "${size}x${size}" xc:"${BACKGROUND_COLOR}" \
            \( "${source_icon}" -resize "${size}x${size}" \) \
            -gravity center \
            -composite \
            -alpha off \
            -type TrueColor \
            -define png:color-type=2 \
            "${output}"
    }

    # Генерируем все размеры
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

    echo "  ✓ ${variant} исправлен"
}

# Обрабатываем каждый вариант
for variant in "${variants[@]}"; do
    create_icon_no_alpha "$variant"
done

echo ""
echo "✅ Иконки исправлены!"
echo ""
echo "Теперь запустите приложение заново:"
echo "  flutter clean"
echo "  flutter run"
