const { HttpError } = require('./taskService');

// Hugging Face Inference API (FLAN-T5 base)
// Backend-only token via env.
const HF_MODEL = process.env.HF_MODEL || 'HuggingFaceTB/SmolLM3-3B';
const HF_API_URL = process.env.HF_BASE_URL || 'https://router.huggingface.co/v1/chat/completions';

const DEFAULT_TIMEOUT_MS = 15000;
const DEFAULT_RETRIES = 1;

function normalizeType(type) {
  return type === 'title' || type === 'description' ? type : null;
}

function buildPrompt({ text, type }) {
  const safeText = (text ?? '').toString().trim();

  // TITLE — коротко, одно предложение
  if (type === 'title') {
    return [
      'ТОЛЬКО БИБЛЕЙСКИЙ',
      'Ты редактор названий заданий для подросткового приложения.',
      'Перепиши ТОЛЬКО название: сделай его коротким, понятным и привлекательным.',
      'НЕЛЬЗЯ: добавлять новые требования или менять смысл.',
      'Стиль: коротко, 2–6 слов, без кавычек.',
      'Верни только название.',
      '',
      `Название: ${safeText}`
    ].join('\n');
  }

  // DESCRIPTION — раскрыто, интересно
  return [
    'ТОЛЬКО БИБЛЕЙСКИЙ',
    'Ты редактор заданий для мобильного приложения (для подростков).',
    'Перепиши описание так, чтобы оно было понятным, вдохновляющим и чуть более раскрытым.',
    'Можно: добавить 1–2 коротких предложения, которые помогают лучше понять смысл задания.',
    'НЕЛЬЗЯ: добавлять новые требования, шаги, ограничения, сроки, цифры или детали.',
    'Стиль: дружелюбно, просто, живо. 2–4 предложения. Без списков и без эмодзи.',
    'Верни только улучшенный текст.',
    '',
    `Описание: ${safeText}`
  ].join('\n');
}

function cleanModelOutput(s) {
  if (typeof s !== 'string') return '';

  // remove model thinking tags
  s = s.replace(/<\/?think>/gi, '');

  let out = s
    // normalize common “smart quotes”
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/[\u00AB\u00BB]/g, '"')
    .trim();

  // Remove wrapping quotes repeatedly (model sometimes returns nested quotes)
  for (let i = 0; i < 3; i++) {
    if (out.startsWith('"') && out.endsWith('"') && out.length >= 2) {
      out = out.slice(1, -1).trim();
    } else {
      break;
    }
  }

  // Remove common prefixes if model returns them.
  out = out
    .replace(/^(title|название|description|описание)\s*[:\-]\s*/i, '')
    .trim();

  // Remove bullet prefix if any
  out = out.replace(/^[\-•\*]+\s*/g, '').trim();

  // Collapse excessive whitespace
  out = out.replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim();

  return out;
}

function isRetryableNetworkError(e) {
  // node fetch timeouts => AbortError
  if (e && typeof e === 'object' && e.name === 'AbortError') return true;

  // generic network-ish errors
  const msg = (e?.message ?? '').toString().toLowerCase();
  return (
    msg.includes('network') ||
    msg.includes('socket') ||
    msg.includes('ecconn') ||
    msg.includes('econn') ||
    msg.includes('timeout') ||
    msg.includes('fetch failed')
  );
}

async function callHfOnce({ prompt, timeoutMs = DEFAULT_TIMEOUT_MS }) {
  const token = process.env.HF_TOKEN;
  if (!token) {
    throw new HttpError(500, 'HF_TOKEN_MISSING', 'HF_TOKEN is not configured');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const resp = await fetch(HF_API_URL, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
body: JSON.stringify({
  model: HF_MODEL,
  messages: [
    {
      role: 'system',
      content: 'Ты редактор заданий. Переписывай текст яснее и грамотнее. СТРОГО не добавляй новых требований и деталей. Верни только итоговый текст без пояснений.'
    },
    { role: 'user', content: prompt }
  ],
  temperature: 0.2
})
    });

    const raw = await resp.text();

    if (resp.status === 429) {
      throw new HttpError(429, 'RATE_LIMIT', 'RATE_LIMIT');
    }

    if (!resp.ok) {
      throw new HttpError(502, 'HF_INFERENCE_FAILED', 'HF_INFERENCE_FAILED');
    }

    let data;
    try {
      data = JSON.parse(raw);
    } catch (_) {
      throw new HttpError(502, 'HF_BAD_RESPONSE', 'HF_BAD_RESPONSE');
    }

    // Typical response: [{ generated_text: "..." }]
const generatedText =
  typeof data?.choices?.[0]?.message?.content === 'string'
    ? data.choices[0].message.content
    : null;

    if (!generatedText || generatedText.trim().length === 0) {
      throw new HttpError(502, 'HF_EMPTY_OUTPUT', 'Hugging Face returned empty output');
    }

    return generatedText;
  } catch (e) {
    if (e && typeof e === 'object' && e.name === 'AbortError') {
      throw new HttpError(504, 'HF_TIMEOUT', 'HF_TIMEOUT');
    }
    throw e;
  } finally {
    clearTimeout(timeout);
  }
}

async function callHf({ prompt, timeoutMs = DEFAULT_TIMEOUT_MS, retries = DEFAULT_RETRIES }) {
  let attempt = 0;
  // retries means: number of extra attempts after the first
  const maxAttempts = 1 + Math.max(0, retries);

  while (attempt < maxAttempts) {
    try {
      return await callHfOnce({ prompt, timeoutMs });
    } catch (e) {
      attempt += 1;

      // No retry for non-network errors
      if (!isRetryableNetworkError(e) || attempt >= maxAttempts) {
        throw e;
      }
    }
  }

  // Should never reach
  throw new HttpError(502, 'HF_INFERENCE_FAILED', 'HF_INFERENCE_FAILED');
}

// Public API
// - accepts text + type ('title'|'description')
// - returns clean improved string
async function improveTaskText({ text, type, timeoutMs }) {
  const normalizedType = normalizeType(type);
  if (!normalizedType) {
    throw new HttpError(400, 'INVALID_TYPE', 'type must be "title" | "description"');
  }

  const safeText = (text ?? '').toString().trim();
  if (!safeText) {
    throw new HttpError(400, 'EMPTY_TEXT', 'EMPTY_TEXT');
  }

  const prompt = buildPrompt({ text: safeText, type: normalizedType });
  const generated = await callHf({ prompt, timeoutMs });
  const cleaned = cleanModelOutput(generated);

  if (!cleaned) {
    throw new HttpError(502, 'HF_EMPTY_OUTPUT', 'Model output is empty after cleaning');
  }

  return cleaned;
}

module.exports = {
  improveTaskText,
  HF_MODEL
};
