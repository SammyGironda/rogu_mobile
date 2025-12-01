class SedeCreateRequest {
  final int idPersonaD;
  final String nombre;
  final String descripcion;

  // Ubicación detallada
  final String country; // e.g., "Bolivia"
  final String countryCode; // e.g., "BO"
  final String stateProvince; // e.g., "La Paz"
  final String city; // e.g., "La Paz"
  final String district; // e.g., "San Miguel"
  final String addressLine; // e.g., "Av. Saavedra #2540 esq. Calle 18"
  final String postalCode; // e.g., "00000"
  final double latitude;
  final double longitude;
  final String timezone; // e.g., "America/La_Paz"

  // Contacto y políticas
  final String telefono;
  final String email;
  final String politicas;
  final String estado; // e.g., "ACTIVA" | "INACTIVA"

  // Documentos
  final String NIT;
  final String LicenciaFuncionamiento;

  const SedeCreateRequest({
    required this.idPersonaD,
    required this.nombre,
    this.descripcion = '',
    this.country = 'Bolivia',
    this.countryCode = 'BO',
    this.stateProvince = 'La Paz',
    this.city = 'La Paz',
    this.district = '',
    this.addressLine = '',
    this.postalCode = '00000',
    this.latitude = 0,
    this.longitude = 0,
    this.timezone = 'America/La_Paz',
    this.telefono = '',
    this.email = '',
    this.politicas = '',
    this.estado = 'ACTIVA',
    this.NIT = '',
    this.LicenciaFuncionamiento = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'idPersonaD': idPersonaD,
      'nombre': nombre,
      'descripcion': descripcion,
      'country': country,
      'countryCode': countryCode,
      'stateProvince': stateProvince,
      'city': city,
      'district': district,
      'addressLine': addressLine,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'telefono': telefono,
      'email': email,
      'politicas': politicas,
      'estado': estado,
      'NIT': NIT,
      'LicenciaFuncionamiento': LicenciaFuncionamiento,
    };
  }
}
