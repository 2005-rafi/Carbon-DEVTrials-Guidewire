class ApiException implements Exception {
  final String userFriendlyMessage;
  final int? statusCode;
  final String? technicalMessage;

  const ApiException(
    this.userFriendlyMessage, {
    this.statusCode,
    this.technicalMessage,
  });

  String get message => userFriendlyMessage;

  @override
  String toString() {
    final technical = technicalMessage == null || technicalMessage!.isEmpty
        ? 'n/a'
        : technicalMessage;
    return 'ApiException(statusCode: $statusCode, userMessage: $userFriendlyMessage, technical: $technical)';
  }
}
