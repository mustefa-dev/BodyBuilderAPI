class AuthResponse {
  final String token;
  final String fullName;
  final String id;

  AuthResponse({required this.token, required this.fullName, required this.id});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      fullName: json['fullName'] as String,
      id: json['id'] as String,
    );
  }
}
