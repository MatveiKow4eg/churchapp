 const { DateTime } = require('luxon');

// Server stays in UTC, but all "business day/month" calculations must be in Estonia time.
const APP_TZ = 'Europe/Tallinn';

/**
 * Returns UTC Date objects for the start/end of a given day in APP_TZ.
 *
 * @param {import('luxon').DateTime} [date] - Luxon DateTime already set to APP_TZ.
 */
function dayRangeUtc(date = DateTime.now().setZone(APP_TZ)) {
  const start = date.startOf('day').toUTC().toJSDate();
  const end = date.endOf('day').toUTC().toJSDate();
  return { start, end };
}

/**
 * Returns UTC Date objects for the start/end of the given month in APP_TZ.
 *
 * @param {string} monthStr - 'YYYY-MM'
 */
function monthRangeUtc(monthStr /* '2026-02' */) {
  if (!monthStr) throw new Error('monthStr is required');

  const dt = DateTime.fromFormat(monthStr, 'yyyy-MM', { zone: APP_TZ });
  if (!dt.isValid) throw new Error('Invalid month format. Expected YYYY-MM');

  const start = dt.startOf('month').toUTC().toJSDate();
  const end = dt.endOf('month').toUTC().toJSDate();
  return { start, end };
}

/**
 * Like monthRangeUtc, but returns [start, end) with end being the start of next month.
 * Useful for Prisma filters using lt.
 *
 * @param {string} monthStr - 'YYYY-MM'
 */
function monthRangeUtcExclusiveEnd(monthStr) {
  if (!monthStr) throw new Error('monthStr is required');

  const dt = DateTime.fromFormat(monthStr, 'yyyy-MM', { zone: APP_TZ });
  if (!dt.isValid) throw new Error('Invalid month format. Expected YYYY-MM');

  const start = dt.startOf('month').toUTC().toJSDate();
  const end = dt.plus({ months: 1 }).startOf('month').toUTC().toJSDate();
  return { start, end };
}

module.exports = { APP_TZ, dayRangeUtc, monthRangeUtc, monthRangeUtcExclusiveEnd };
