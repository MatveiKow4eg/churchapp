#!/bin/bash
set -euo pipefail

# Генерация iOS AppIcon наборов (iPhone + iPad + ios-marketing) для альтернативных тем
# Требования: sips (встроен в macOS)

ASSETS_DIR="ios/Runner/Assets.xcassets"
ICONS_SOURCE="assets"
VARIANTS=("amber" "dark_cyan" "dark_gold" "dark_purple" "emerald" "indigo" "mono" "pink" "red" "sky")

log(){ echo "[icons] $1"; }

make_dir(){ mkdir -p "$1"; }

# sips resize helper (width == height)
resize_square(){
  local input="$1"; local size="$2"; local output="$3"
  sips -Z "$size" "$input" --out "$output" >/dev/null
}

write_contents_json(){
  local dir="$1"
  cat > "$dir/Contents.json" <<'JSON'
{
  "images" : [
    { "size" : "20x20",   "idiom" : "iphone", "filename" : "Icon-App-20x20@2x.png",               "scale" : "2x" },
    { "size" : "20x20",   "idiom" : "iphone", "filename" : "Icon-App-20x20@3x.png",               "scale" : "3x" },
    { "size" : "29x29",   "idiom" : "iphone", "filename" : "Icon-App-29x29@1x.png",               "scale" : "1x" },
    { "size" : "29x29",   "idiom" : "iphone", "filename" : "Icon-App-29x29@2x.png",               "scale" : "2x" },
    { "size" : "29x29",   "idiom" : "iphone", "filename" : "Icon-App-29x29@3x.png",               "scale" : "3x" },
    { "size" : "40x40",   "idiom" : "iphone", "filename" : "Icon-App-40x40@2x.png",               "scale" : "2x" },
    { "size" : "40x40",   "idiom" : "iphone", "filename" : "Icon-App-40x40@3x.png",               "scale" : "3x" },
    { "size" : "60x60",   "idiom" : "iphone", "filename" : "Icon-App-60x60@2x.png",               "scale" : "2x" },
    { "size" : "60x60",   "idiom" : "iphone", "filename" : "Icon-App-60x60@3x.png",               "scale" : "3x" },

    { "size" : "20x20",   "idiom" : "ipad",   "filename" : "Icon-App-20x20~ipad@1x.png",          "scale" : "1x" },
    { "size" : "20x20",   "idiom" : "ipad",   "filename" : "Icon-App-20x20~ipad@2x.png",          "scale" : "2x" },
    { "size" : "29x29",   "idiom" : "ipad",   "filename" : "Icon-App-29x29~ipad@1x.png",          "scale" : "1x" },
    { "size" : "29x29",   "idiom" : "ipad",   "filename" : "Icon-App-29x29~ipad@2x.png",          "scale" : "2x" },
    { "size" : "40x40",   "idiom" : "ipad",   "filename" : "Icon-App-40x40~ipad@1x.png",          "scale" : "1x" },
    { "size" : "40x40",   "idiom" : "ipad",   "filename" : "Icon-App-40x40~ipad@2x.png",          "scale" : "2x" },
    { "size" : "76x76",   "idiom" : "ipad",   "filename" : "Icon-App-76x76~ipad@1x.png",          "scale" : "1x" },
    { "size" : "76x76",   "idiom" : "ipad",   "filename" : "Icon-App-76x76~ipad@2x.png",          "scale" : "2x" },
    { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "Icon-App-83.5x83.5~ipad@2x.png",      "scale" : "2x" },

    { "size" : "1024x1024","idiom" : "ios-marketing", "filename" : "Icon-App-1024x1024@1x.png",   "scale" : "1x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON
}

gen_set(){
  local variant="$1"
  local src_png="${ICONS_SOURCE}/icon_${variant}.png"
  local set_dir="${ASSETS_DIR}/AppIcon-${variant}.appiconset"

  if [[ ! -f "$src_png" ]]; then
    log "⚠️  Пропущено ${variant}: не найден $src_png"
    return
  fi

  log "Генерация AppIcon-${variant}.appiconset из ${src_png}"
  make_dir "$set_dir"
  write_contents_json "$set_dir"

  # iPhone sizes
  resize_square "$src_png" 40  "$set_dir/Icon-App-20x20@2x.png"
  resize_square "$src_png" 60  "$set_dir/Icon-App-20x20@3x.png"
  resize_square "$src_png" 29  "$set_dir/Icon-App-29x29@1x.png"
  resize_square "$src_png" 58  "$set_dir/Icon-App-29x29@2x.png"
  resize_square "$src_png" 87  "$set_dir/Icon-App-29x29@3x.png"
  resize_square "$src_png" 80  "$set_dir/Icon-App-40x40@2x.png"
  resize_square "$src_png" 120 "$set_dir/Icon-App-40x40@3x.png"
  resize_square "$src_png" 120 "$set_dir/Icon-App-60x60@2x.png"
  resize_square "$src_png" 180 "$set_dir/Icon-App-60x60@3x.png"

  # iPad sizes
  resize_square "$src_png" 20  "$set_dir/Icon-App-20x20~ipad@1x.png"
  resize_square "$src_png" 40  "$set_dir/Icon-App-20x20~ipad@2x.png"
  resize_square "$src_png" 29  "$set_dir/Icon-App-29x29~ipad@1x.png"
  resize_square "$src_png" 58  "$set_dir/Icon-App-29x29~ipad@2x.png"
  resize_square "$src_png" 40  "$set_dir/Icon-App-40x40~ipad@1x.png"
  resize_square "$src_png" 80  "$set_dir/Icon-App-40x40~ipad@2x.png"
  resize_square "$src_png" 76  "$set_dir/Icon-App-76x76~ipad@1x.png"
  resize_square "$src_png" 152 "$set_dir/Icon-App-76x76~ipad@2x.png"
  resize_square "$src_png" 167 "$set_dir/Icon-App-83.5x83.5~ipad@2x.png"

  # App Store
  resize_square "$src_png" 1024 "$set_dir/Icon-App-1024x1024@1x.png"

  log "✓ Готово: AppIcon-${variant}.appiconset"
}

log "Старт генерации альтернативных iOS AppIcon"
for v in "${VARIANTS[@]}"; do
  gen_set "$v"
done
log "Генерация завершена"
