enum FetchExceptionType {
  noTeam,
  wrongYear,
  noConnection,
  other,
}

class FetchException implements Exception {
  final String uiMessage;

  final FetchExceptionType fetchExceptionType;

  const FetchException(this.uiMessage, this.fetchExceptionType);

  @override
  String toString() => uiMessage;
}
