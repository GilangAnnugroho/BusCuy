class UserModel {
  int? idUser;
  String username;
  String password;
  String role; // 'admin' atau 'pelanggan'

  UserModel({
    this.idUser,
    required this.username,
    required this.password,
    required this.role,
  });

  // Menerima data dari Database (Map -> Object)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUser: map['id_user'],
      username: map['username'] ?? '', // Safety check
      password: map['password'] ?? '',
      role: map['role'] ?? 'pelanggan', // Default ke pelanggan jika null
    );
  }

  // Mengirim data ke Database (Object -> Map)
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}
