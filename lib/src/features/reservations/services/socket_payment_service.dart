import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/config/app_config.dart';
import '../models/booking_status.dart';

/// Handles Libelula socket subscription lifecycle.
class SocketPaymentService {
  SocketPaymentService({this.baseUrl});

  final String? baseUrl;
  io.Socket? _socket;
  bool get isConnected => _socket?.connected == true;

  /// Connects to the socket backend.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final root = (baseUrl ?? AppConfig.apiBaseUrl)
        .replaceFirst(RegExp(r'/api/?$'), '');
    _socket = io.io(
      root,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .enableReconnection()
          .build(),
    );
    _socket!.connect();
  }

  /// Emits the standard subscription twice: "suscribirse-a-transaccion".
  void subscribeToTransaction(dynamic transactionId) {
    if (_socket == null) return;
    final payload = {'transaccionId': transactionId};
    _socket!.emit('suscribirse-a-transaccion', payload);
    _socket!.emit('suscribirse-a-transaccion', payload);
  }

  /// Registers handler for "pago-completado".
  void listenPaymentCompleted(void Function(PaymentCompletedEvent data) onData) {
    _socket?.on('pago-completado', (data) {
      if (data is Map) {
        onData(
          PaymentCompletedEvent(
            transactionId: data['transaccionId'] ?? data['id'],
            status: BookingStatus.fromBackend(data['estado']?.toString()),
            reservationId: (data['idReserva'] is String)
                ? int.tryParse(data['idReserva']) ?? 0
                : (data['idReserva'] ?? 0),
            externalPaymentId: data['idPagoExterno']?.toString(),
            amount: (data['monto'] is num)
                ? (data['monto'] as num).toDouble()
                : double.tryParse('${data['monto']}'),
          ),
        );
      }
    });
  }

  /// Closes the socket connection.
  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
  }
}

class PaymentCompletedEvent {
  const PaymentCompletedEvent({
    required this.transactionId,
    required this.status,
    required this.reservationId,
    this.externalPaymentId,
    this.amount,
  });

  final dynamic transactionId;
  final BookingStatus status;
  final int reservationId;
  final String? externalPaymentId;
  final double? amount;
}
