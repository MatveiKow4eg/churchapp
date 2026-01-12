/// Helpers to display task categories in a user-friendly Russian form.
///
/// Backend typically returns uppercase enum-like category values.
/// We keep this mapping centralized to ensure consistent UI.
String localizeTaskCategory(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return v;

  switch (v.toUpperCase()) {
    case 'SPIRITUAL':
      return 'Духовное';
    case 'SERVICE':
      return 'Служение / помощь';
    case 'COMMUNITY':
      return 'Сообщество / общение';
    case 'CREATIVITY':
      return 'Творчество';
    case 'REFLECTION':
      return 'Рассуждение';
    case 'OTHER':
      return 'Другое';
    default:
      // If backend already returns Russian (or an unknown category), keep as-is.
      return v;
  }
}
