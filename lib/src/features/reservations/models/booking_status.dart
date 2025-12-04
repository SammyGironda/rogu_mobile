/// Possible states exposed by Libelula/ROGU for transactions.
enum BookingStatus {
  pendiente('PENDIENTE'),
  aprobada('APROBADA'),
  rechazada('RECHAZADA'),
  cancelada('CANCELADA');

  const BookingStatus(this.backendValue);
  final String backendValue;

  static BookingStatus fromBackend(String? value) {
    switch (value?.toUpperCase()) {
      case 'APROBADA':
        return BookingStatus.aprobada;
      case 'RECHAZADA':
        return BookingStatus.rechazada;
      case 'CANCELADA':
        return BookingStatus.cancelada;
      case 'PENDIENTE':
      default:
        return BookingStatus.pendiente;
    }
  }
}
