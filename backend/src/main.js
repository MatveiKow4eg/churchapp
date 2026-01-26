// Load environment variables.
// In production you can point ENV_PATH to an absolute .env file.
// Locally (or if ENV_PATH is not set) dotenv will load backend/.env automatically if present.
require('dotenv').config({ path: process.env.ENV_PATH });

const { app } = require('./app');

const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.listen(PORT, '0.0.0.0', () => {
  // 0.0.0.0 — чтобы можно было обращаться с устройств в локальной сети (при необходимости)
  console.log(`Server is listening on http://localhost:${PORT}`);
});
