const crypto = require('crypto');

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function normalizeJoinCode(code) {
  return (code ?? '').toString().trim().toUpperCase();
}

function generateJoinCode(length = 8) {
  const len = Math.max(6, Math.min(12, Number(length) || 8));
  const bytes = crypto.randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i += 1) {
    out += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return out;
}

module.exports = {
  normalizeJoinCode,
  generateJoinCode
};
