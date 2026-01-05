# Backend (Node.js + Express + Prisma + PostgreSQL)

MVP локального сервера без бизнес-сущностей.

## Требования
- Node.js (LTS)
- PostgreSQL (локально или через Docker)

## Конфигурация
1) Создайте локальный env:
- `cp .env.example .env`

2) Убедитесь, что `DATABASE_URL` указывает на вашу PostgreSQL.

3) Укажите JWT_SECRET в .env (обязательно для auth).

## Установка
- `npm i`

## Prisma
- Генерация клиента:
  - `npm run prisma:generate`

- Миграции (dev):
  - `npm run prisma:migrate`

## Запуск
- `npm run dev`

## Проверка
- Healthcheck:
  - `curl http://localhost:3000/health`

- Пример валидации (Zod):
  - `curl "http://localhost:3000/echo?text=hello"`
  - Ошибка валидации:
    - `curl "http://localhost:3000/echo?text="`

## Auth

### Register
```
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Ivan",
    "lastName": "Ivanov",
    "age": 16,
    "city": "Moscow"
  }'
```
Ответ: `{ token, user }`

### Me
```
# Подставьте полученный token
TOKEN=eyJ...

curl http://localhost:3000/auth/me \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `{ user, church?, balance? }`

## Churches

### Create church (ADMIN/SUPERADMIN)
```
# Нужен JWT токен пользователя с ролью ADMIN или SUPERADMIN
TOKEN=eyJ...

curl -X POST http://localhost:3000/churches \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Church",
    "city": "Moscow"
  }'
```
Ответ: `201 { church: { id, name, city, createdAt } }`

## Tasks

### List tasks (any authenticated user with churchId)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl "http://localhost:3000/tasks?activeOnly=true&limit=30&offset=0" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { items: [...], limit, offset, total }`

### Create task (ADMIN/SUPERADMIN)
```
# 1) Получите JWT токен админа (логин)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

# 2) Создайте задание
curl -X POST http://localhost:3000/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Read a chapter",
    "description": "Read one chapter of the Gospel and write 2 insights",
    "category": "SPIRITUAL",
    "pointsReward": 10
  }'
```
Ответ: `201 { task: { id, title, description, category, pointsReward, isActive, createdAt } }`

Важно: `churchId` не передаётся с клиента — он берётся из JWT (req.user.churchId).
Если у админа нет `churchId` → `409 { error: { code: "NO_CHURCH", ... } }`.

### Update task (PATCH) (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа (логин)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

TASK_ID=cj...

curl -X PATCH http://localhost:3000/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Read 2 chapters",
    "pointsReward": 15,
    "isActive": true
  }'
```
Ответ: `200 { task: { id, title, description, category, pointsReward, isActive, createdAt } }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }` — невалидное тело
- `400 { error: { code: "EMPTY_PATCH", ... } }` — если не передано ни одного допустимого поля
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Deactivate task (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа (логин)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

TASK_ID=cj...

curl -X PATCH http://localhost:3000/tasks/$TASK_ID/deactivate \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { task: { id, title, description, category, pointsReward, isActive:false, createdAt } }`

Ошибки:
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Create submission (request task approval) (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...
TASK_ID=cj...

curl -X POST http://localhost:3000/submissions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "'$TASK_ID'",
    "commentUser": "I have completed the task"
  }'
```
Ответ: `201 { submission: { id, status, taskId, userId, churchId, commentUser, createdAt } }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }` — если user.status=BANNED
- `404 { error: { code: "TASK_NOT_FOUND", ... } }` — если task не найден
- `409 { error: { code: "NO_CHURCH", ... } }` — если в JWT нет churchId
- `409 { error: { code: "CONFLICT", ... } }` — если submission уже существует (userId, taskId)

### List my submissions (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl "http://localhost:3000/submissions/mine?status=PENDING&limit=30&offset=0&sort=new" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { items: [...], limit, offset, total }`

### List pending submissions (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа (churchId берётся из JWT)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

curl "http://localhost:3000/submissions/pending?limit=30&offset=0&sort=new" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { items: [...], limit, offset, total }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Approve submission (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

SUBMISSION_ID=cj...

curl -X POST http://localhost:3000/submissions/$SUBMISSION_ID/approve \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "commentAdmin": "Approved, good job"
  }'
```
Ответ: `200 { submission: { id, status, decidedAt, decidedById, rewardPointsApplied, commentAdmin? }, balance }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "CONFLICT", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Reject submission (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

SUBMISSION_ID=cj...

curl -X POST http://localhost:3000/submissions/$SUBMISSION_ID/reject \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "commentAdmin": "Rejected: insufficient proof"
  }'
```
Ответ: `200 { submission: { id, status, decidedAt, decidedById, commentAdmin?, rewardPointsApplied } }`

Примечание: при reject `rewardPointsApplied` устанавливается в `0`.

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "CONFLICT", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Shop items list (any authenticated user with churchId)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl "http://localhost:3000/shop/items?activeOnly=true&limit=30&offset=0&type=COSMETIC" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { items: [...], limit, offset, total }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `409 { error: { code: "NO_CHURCH", message: "User has no church selected" } }`

### Create shop item (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

curl -X POST http://localhost:3000/shop/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cool Badge",
    "description": "A shiny badge",
    "type": "BADGE",
    "pricePoints": 25
  }'
```
Ответ: `201 { item: { id, name, description, type, pricePoints, isActive, createdAt } }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`
- `409 { error: { code: "CONFLICT", ... } }` — если item с таким name уже существует в этой церкви

### Update shop item (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

ITEM_ID=cj...

curl -X PATCH http://localhost:3000/shop/items/$ITEM_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pricePoints": 30,
    "isActive": true
  }'
```
Ответ: `200 { item: { id, name, description, type, pricePoints, isActive, createdAt } }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `400 { error: { code: "EMPTY_PATCH", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`
- `409 { error: { code: "CONFLICT", ... } }` — если name конфликтует (unique)

### Deactivate shop item (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

ITEM_ID=cj...

curl -X PATCH http://localhost:3000/shop/items/$ITEM_ID/deactivate \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { item: { id, name, description, type, pricePoints, isActive:false, createdAt } }`

Ошибки:
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`

### Purchase shop item (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...
ITEM_ID=cj...

curl -X POST http://localhost:3000/shop/purchase \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "itemId": "'$ITEM_ID'"
  }'
```
Ответ: `200 { item: { id, name, pricePoints, type }, balance, inventory }`

Пример ошибки (insufficient points):
- `409 { error: { code: "CONFLICT", message: "Insufficient points" } }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `404 { error: { code: "NOT_FOUND", ... } }`
- `409 { error: { code: "NO_CHURCH", ... } }`
- `409 { error: { code: "CONFLICT", ... } }` — inactive / already owned / insufficient

### My inventory (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl http://localhost:3000/me/inventory \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { items: [...], total }`

Ошибки:
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `409 { error: { code: "NO_CHURCH", message: "User has no church selected" } }`

### My monthly stats (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl "http://localhost:3000/stats/me?month=2026-01" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { month, tasksApprovedCount, pointsEarned, pointsSpent, netPoints, currentBalance, topCategories? }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }` — если month невалидный
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `409 { error: { code: "NO_CHURCH", message: "User has no church selected" } }`

### Church monthly stats (ADMIN/SUPERADMIN)
```
# Нужен JWT токен админа
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$ADMIN_EMAIL'",
    "password": "'$ADMIN_PASSWORD'"
  }' | node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).token")

curl "http://localhost:3000/stats/church?month=2026-01" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { month, activeUsersCount, approvedSubmissionsCount, pendingSubmissionsCount, totalPointsEarned, totalPointsSpent, topUsers, topTasks? }`

Примечание: `pendingSubmissionsCount` считается как текущее количество заявок со статусом PENDING (без фильтра по месяцу).

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `403 { error: { code: "FORBIDDEN", ... } }`
- `409 { error: { code: "NO_CHURCH", message: "User has no church selected" } }`

### Leaderboard (any authenticated user)
```
# Нужен JWT токен пользователя, который вступил в церковь (churchId в JWT)
TOKEN=eyJ...

curl "http://localhost:3000/leaderboard?month=2026-01&limit=20&offset=0&includeMe=true" \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { month, items: [{ rank, user, netPoints }], limit, offset, total, me? }`

Ошибки:
- `400 { error: { code: "VALIDATION_ERROR", ... } }`
- `401 { error: { code: "UNAUTHORIZED", ... } }`
- `409 { error: { code: "NO_CHURCH", message: "User has no church selected" } }`

### Join church (any authenticated user)
```
# Нужен JWT токен обычного пользователя
TOKEN=eyJ...
CHURCH_ID=cj...

curl -X POST http://localhost:3000/churches/$CHURCH_ID/join \
  -H "Authorization: Bearer $TOKEN"
```
Ответ: `200 { token, user, church }`

Важно: после успешного join клиент должен сохранить новый `token`,
потому что `churchId` внутри JWT обновился.
