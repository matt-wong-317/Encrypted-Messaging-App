// HANDLES CREATING API USERS FROM HTTPS CALLS
class ApiUser {
  int id;
  String username;
  String email;
  String password;
  String? image;

  ApiUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.image,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      password: json['password'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'image': image,
    };
  }
}