class Persona {
  final String idPersona;
  final String nombres;
  final String? paterno;
  final String? materno;
  final String? documentoTipo;
  final String? documentoNumero;
  final String? telefono;
  final bool telefonoVerificado;
  final DateTime? fechaNacimiento;
  final String? genero;
  final String? urlFoto;
  final DateTime? creadoEn;

  Persona({
    required this.idPersona,
    required this.nombres,
    this.paterno,
    this.materno,
    this.documentoTipo,
    this.documentoNumero,
    this.telefono,
    this.telefonoVerificado = false,
    this.fechaNacimiento,
    this.genero,
    this.urlFoto,
    this.creadoEn,
  });

  factory Persona.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }
    return Persona(
      idPersona: (map['idPersona'] ?? map['id']).toString(),
      nombres: map['nombres']?.toString() ?? '',
      paterno: map['paterno']?.toString(),
      materno: map['materno']?.toString(),
      documentoTipo: map['documentoTipo']?.toString(),
      documentoNumero: map['documentoNumero']?.toString(),
      telefono: map['telefono']?.toString(),
      telefonoVerificado: (map['telefonoVerificado'] == true || map['telefonoVerificado'] == 1),
      fechaNacimiento: parseDate(map['fechaNacimiento']),
      genero: map['genero']?.toString(),
      urlFoto: map['urlFoto']?.toString(),
      creadoEn: parseDate(map['creadoEn']),
    );
  }

  Map<String, dynamic> toMap() => {
    'idPersona': idPersona,
    'nombres': nombres,
    'paterno': paterno,
    'materno': materno,
    'documentoTipo': documentoTipo,
    'documentoNumero': documentoNumero,
    'telefono': telefono,
    'telefonoVerificado': telefonoVerificado,
    'fechaNacimiento': fechaNacimiento?.toIso8601String(),
    'genero': genero,
    'urlFoto': urlFoto,
    'creadoEn': creadoEn?.toIso8601String(),
  };
}