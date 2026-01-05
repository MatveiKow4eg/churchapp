# Monorepo: Node.js backend + Flutter mobile

Минимальный каркас репозитория для backend на Node.js и mobile на Flutter.

## Структура
- `backend/` — сервер Node.js
- `mobile/` — приложение Flutter
- `.env.example` — пример общих переменных (если применимо)

## Требования
- Node.js (LTS)
- Flutter SDK
- (опционально) Docker / Docker Compose — если будете поднимать инфраструктуру контейнерами

## Локальный запуск (кратко)

### 1) Настройка переменных окружения
- Backend:
  - Скопируйте пример:
    - `cp backend/.env.example backend/.env`
  - Заполните значения (секреты/URL/порты) локально.

- Mobile (опционально):
  - Если используете env-файл:
    - `cp mobile/.env.example mobile/.env`
  - Альтернатива: используйте `--dart-define`/flavors.

### 2) Запуск backend
1. Перейдите в `backend/`
2. Установите зависимости: `npm i`
3. Запуск dev: `npm run dev`

### 3) Запуск mobile
1. Перейдите в `mobile/`
2. Установите зависимости: `flutter pub get`
3. Запуск: `flutter run`

## Где лежат конфиги
- Общий пример переменных: `.env.example`
- Backend: `backend/.env.example`
- Mobile (опционально): `mobile/.env.example`

## Примечания
- Файлы `.env` не коммитятся. Используйте `.env.example` как шаблон.
