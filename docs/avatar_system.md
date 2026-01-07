# Avatar System v1

## 1) Purpose

- Единый контракт `AvatarConfig` для Flutter / Backend / Unity.
- Подготовка под интеграцию Ready Player Me без переписывания API (добавление новых полей/версий без поломки v1).
- Безопасное хранение в БД: валидируемая JSON-структура, ограничение размера, отсутствие ссылок/URL на внешние ассеты (только стабильные IDs).
- Ready Player Me используется как внешний редактор/источник 3D-модели, но наш контракт хранит также игровые слоты/предметы.

## 2) AvatarConfig v1 (Contract)

`AvatarConfig` — пользовательская конфигурация внешнего вида (персонализация), хранимая и передаваемая как JSON.

### 2.1 JSON schema (логическое описание)

- `version`: **number**
  - **Всегда `1`** для данной версии контракта.

- `body`: **object** (обязательное)
  - `type`: **string** (обязательное)
    - Enum: `slim | normal | athletic | strong`
  - `height`: **number** (обязательное)
    - Диапазон: `0..1` (включительно)
    - Рекомендуемая точность: до 2–3 знаков после запятой.
  - `weight`: **number** (обязательное)
    - Диапазон: `0..1` (включительно)
    - Рекомендуемая точность: до 2–3 знаков после запятой.

- `skinTone`: **string** (обязательное)
  - String ID тона кожи (например: `tone_05`).

- `hair`: **object** (обязательное)
  - `style`: **string** (обязательное)
    - String ID прически (например: `hair_01`).
  - `color`: **string** (обязательное)
    - HEX-цвет
    - Допустимые форматы: `#RGB` или `#RRGGBB`
    - Регистр не важен.

- `face`: **object** (обязательное)
  - `preset`: **string** (обязательное)
    - String ID пресета лица (например: `face_01`).

- `wear`: **object** (обязательное)
  - `top?`: **string** (опционально)
  - `bottom?`: **string** (опционально)
  - `shoes?`: **string** (опционально)
  - `accessory?`: **string** (опционально)

- `external?`: **object** (опционально)
  - `provider`: **string** (обязательное если задан `external`)
    - Enum: `readyplayerme`
  - `avatarUrl`: **string** (обязательное если задан `external`)
    - URL на аватар/3D-модель у провайдера (Ready Player Me).

### 2.2 Size limit

Ограничение размера полезной нагрузки и хранения:

- `JSON.stringify(config).length <= 20000` (≤ 20KB)

Рекомендации:
- Не добавлять массивы произвольной длины.
- Не добавлять бинарные данные/URL на ассеты.

### 2.3 Minimal AvatarConfig example

```json
{
  "version": 1,
  "body": { "type": "normal", "height": 0.7, "weight": 0.5 },
  "skinTone": "tone_05",
  "hair": { "style": "hair_01", "color": "#2b1b0e" },
  "face": { "preset": "face_01" },
  "wear": {
    "top": "top_hoodie_black_v1",
    "bottom": "bottom_jeans_blue_v1",
    "shoes": "shoes_sneakers_white_v1"
  }
}
```

## 3) Slots & Rules

### 3.1 Slots

Слоты — это категории взаимозаменяемых элементов (items), которые применяются поверх базовой модели.

- `hair` — прическа (в `hair.style`, не в `wear`)
- `top` — верхняя одежда (в `wear.top`)
- `bottom` — нижняя часть (в `wear.bottom`)
- `shoes` — обувь (в `wear.shoes`)
- `accessory` — аксессуар (в `wear.accessory`)

### 3.2 Rules

- Поля `wear.*` **опциональны**.
  - Если поле слота не задано (`undefined`/отсутствует), клиент **использует дефолты** (локально определенные дефолтные itemId для данного слота и bodyType).

- Если `itemId` неизвестен клиенту (нет в локальном/полученном каталоге), то:
  - клиент **игнорирует** такой `itemId` и применяет **fallback** (дефолт или “ничего” для аксессуаров — по правилам клиента).

- В контракте **нет** ссылок на Unity/меши/материалы/путь к ресурсам движка.
  - Только стабильные, переносимые IDs (например `top_hoodie_black_v1`).
  - Связывание ID → ассеты — ответственность конкретного клиента (Flutter/Unity) через `AvatarCatalog`.

## 4) AvatarCatalog v1 (Contract)

`AvatarCatalog` — справочник, который позволяет клиенту понять, какие значения допустимы для `skinTone`, `hair.style` и `wear.*`, а также отобразить UI (названия, иконки, цены, совместимость).

### 4.1 JSON structure

- `version`: **number**
  - Всегда `1` для каталога v1.

- `skinTones`: **array** of objects
  - `id`: **string**
  - `displayName`: **string**
  - `isActive`: **boolean** (если `false`, элемент не должен предлагаться пользователю, но может встречаться в старых конфигах)

- `hairStyles`: **array** of objects
  - `id`: **string**
  - `displayName`: **string**
  - `allowRecolor`: **boolean** (если `false`, клиент может игнорировать `hair.color` или принудительно ставить фиксированный цвет)
  - `isActive`: **boolean**

- `items`: **array** of objects
  - `slot`: **string**
    - Enum: `top | bottom | shoes | accessory`
  - `itemId`: **string** (уникальный в рамках каталога)
  - `displayName`: **string**
  - `iconPath`: **string**
    - Путь/ключ иконки на стороне клиента (или относительно CDN/asset-bundle). Это UI-артефакт, не ссылка на Unity-меши.
  - `isActive`: **boolean**
  - `pricePoints`: **number**
    - Цена в условных поинтах/баллах (целое число, >= 0).
  - `compat`: **object**
    - `bodyTypes`: **array of strings**
      - Поддерживаемые типы тела: `slim | normal | athletic | strong`

### 4.2 Minimal AvatarCatalog example

```json
{
  "version": 1,
  "skinTones": [
    { "id": "tone_03", "displayName": "Warm 03", "isActive": true },
    { "id": "tone_05", "displayName": "Neutral 05", "isActive": true },
    { "id": "tone_08", "displayName": "Cool 08", "isActive": true }
  ],
  "hairStyles": [
    { "id": "hair_01", "displayName": "Short", "allowRecolor": true, "isActive": true },
    { "id": "hair_02", "displayName": "Curly", "allowRecolor": true, "isActive": true },
    { "id": "hair_03", "displayName": "Buzz", "allowRecolor": false, "isActive": true }
  ],
  "items": [
    {
      "slot": "top",
      "itemId": "top_hoodie_black_v1",
      "displayName": "Hoodie (Black)",
      "iconPath": "icons/wear/top_hoodie_black_v1.png",
      "isActive": true,
      "pricePoints": 0,
      "compat": { "bodyTypes": ["slim", "normal", "athletic", "strong"] }
    },
    {
      "slot": "top",
      "itemId": "top_tshirt_white_v1",
      "displayName": "T-Shirt (White)",
      "iconPath": "icons/wear/top_tshirt_white_v1.png",
      "isActive": true,
      "pricePoints": 50,
      "compat": { "bodyTypes": ["slim", "normal", "athletic", "strong"] }
    },
    {
      "slot": "bottom",
      "itemId": "bottom_jeans_blue_v1",
      "displayName": "Jeans (Blue)",
      "iconPath": "icons/wear/bottom_jeans_blue_v1.png",
      "isActive": true,
      "pricePoints": 0,
      "compat": { "bodyTypes": ["slim", "normal", "athletic", "strong"] }
    },
    {
      "slot": "bottom",
      "itemId": "bottom_shorts_gray_v1",
      "displayName": "Shorts (Gray)",
      "iconPath": "icons/wear/bottom_shorts_gray_v1.png",
      "isActive": true,
      "pricePoints": 30,
      "compat": { "bodyTypes": ["slim", "normal", "athletic", "strong"] }
    }
  ]
}
```

## 5) Versioning & Migration Plan

- **v1 сохраняется как есть**: сервер хранит полученный v1-конфиг без модификации (после валидации), и может отдавать его клиентам.

- При появлении **v2**:
  - сервер **принимает v1 и v2** (оба валидируются согласно своим контрактам);
  - сервер **отдаёт всегда последнюю версию** (например v2), даже если в БД лежит v1;
  - миграция выполняется **“на чтении”** (lazy migration): при выдаче конфига применяется функция `upgrade(config)` (v1 → v2). Опционально результат можно сохранять обратно в БД в фоне.

- Неизвестные поля (forward compatibility): выбранный подход
  - Сервер при сохранении/чтении **не удаляет неизвестные поля** и хранит их как часть JSON (если укладывается в лимит 20KB).
  - Клиенты должны **игнорировать неизвестные поля**.
  - Валидатор на сервере должен работать в режиме: проверяем известные обязательные поля и типы, но допускаем дополнительные ключи (чтобы не ломать будущие расширения).

## 6) Definition of Done

- [x] Файл `docs/avatar_system.md` создан.
- [x] Есть пример `AvatarConfig`.
- [x] Есть пример `AvatarCatalog`.
- [x] Слоты и правила описаны.
- [x] Описан план версионирования/миграций.
