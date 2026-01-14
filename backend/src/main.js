require('dotenv').config({ path: '/var/www/churchapp/backend/.env' });


const { app } = require('./app');

const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.listen(PORT, '0.0.0.0', () => {
  // 0.0.0.0 — чтобы можно было обращаться с устройств в локальной сети (при необходимости)
  console.log(`Server is listening on http://localhost:${PORT}`);
});
