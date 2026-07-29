/// Contract for checking network connectivity.
/// Concrete implementation (using e.g., internet_connection_checker or connectivity_plus)
/// should be placed in core/network/network_info_impl.dart when dependencies are chosen.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
