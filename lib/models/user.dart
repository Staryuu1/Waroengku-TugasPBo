class User {
  int? id;
  String username;
  String password;

  User({
    this.id,
    required this.username,
    required this.password,
  });

  // mengkonversi object ke map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }

  // mengkonversi object ke map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}
