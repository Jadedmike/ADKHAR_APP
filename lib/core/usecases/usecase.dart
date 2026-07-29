import '../errors/failures.dart';

/// Abstract interface for all use cases in the application.
/// [T] represents the success output type.
/// [Params] represents the parameters required to execute the usecase.
abstract class UseCase<T, Params> {
  Future<Result<Failure, T>> call(Params params);
}

/// Helper class for usecases that do not require any input parameters.
class NoParams {
  const NoParams();
}

/// A lightweight, functional representation of a value that can be either a success or a failure.
abstract class Result<F, S> {
  const Result();

  R fold<R>(R Function(F failure) onFailure, R Function(S success) onSuccess);
}

class Success<F, S> extends Result<F, S> {
  final S value;
  const Success(this.value);

  @override
  R fold<R>(R Function(F failure) onFailure, R Function(S success) onSuccess) {
    return onSuccess(value);
  }
}

class FailureResult<F, S> extends Result<F, S> {
  final F failure;
  const FailureResult(this.failure);

  @override
  R fold<R>(R Function(F failure) onFailure, R Function(S success) onSuccess) {
    return onFailure(failure);
  }
}
