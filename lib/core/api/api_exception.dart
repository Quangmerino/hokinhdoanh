class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({
    required this.message,
    this.statusCode = 500,
  });

  @override
  String toString() => message;
}
