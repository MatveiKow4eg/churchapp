class AppError implements Exception {
  const AppError({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}
