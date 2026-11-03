class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.role,
    required this.accessToken,
  });

  final int id;
  final String name;
  final String role;
  final String accessToken;

  factory UserSession.fromJson(Map<String, dynamic> json, String token) {
    const roles = {'student', 'coordinator', 'adviser', 'partner_reviewer'};
    final id = json['id'];
    final name = json['name'];
    final role = json['role'];

    if (id is! int ||
        name is! String ||
        role is! String ||
        !roles.contains(role) ||
        token.isEmpty) {
      throw const FormatException('Invalid session response.');
    }

    return UserSession(id: id, name: name, role: role, accessToken: token);
  }
}
