class UserModel {
  final int? userId;
  final String email;
  final String username;
  final String password;
  final int? goalMinutes;
  final String dateCreated;

  UserModel({
    this.userId,
    required this.email,
    required this.username,
    required this.password,
    this.goalMinutes,
    required this.dateCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'username': username,
      'password': password,
      'goal_minutes': goalMinutes,
      'date_created': dateCreated,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
      goalMinutes: map['goal_minutes'],
      dateCreated: map['date_created'],
    );
  }
}
