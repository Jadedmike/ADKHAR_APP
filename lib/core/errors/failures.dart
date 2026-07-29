abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Read/Write Failure occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}
