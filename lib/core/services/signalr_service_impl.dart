import 'package:tiak_passenger/core/services/signalr_service.dart';

@Deprecated('Use SignalRService from signalr_service.dart directly.')
class SignalRServiceImpl {
  SignalRServiceImpl() : _delegate = SignalRService();

  final SignalRService _delegate;

  Future<void> initialize() => _delegate.initialize();
  Future<void> connect() => _delegate.connect();
  Future<void> disconnect() => _delegate.disconnect();

  bool get isConnected => _delegate.isConnected;
}

