class User {
  final String id; // idUsuario
  final String? personaId; // idPersona asociado
  final String username; // nombre de usuario (backend: usuario)
  final String email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.personaId,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? personaId,
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      personaId: personaId ?? this.personaId,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personaId': personaId,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: (map['id'] ?? map['idUsuario']).toString(),
      personaId: map['personaId']?.toString() ?? map['idPersona']?.toString(),
      username: (map['username'] ?? map['name'] ?? map['usuario']).toString(),
      email: map['email']?.toString() ?? map['correo']?.toString() ?? '',
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  @override
  String toString() =>
      'User(id: $id, personaId: $personaId, username: $username, email: $email)';
}
