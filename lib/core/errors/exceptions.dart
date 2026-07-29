class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server Exception occurred']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache Exception occurred']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network Exception occurred']);

  @override
  String toString() => message;
}
