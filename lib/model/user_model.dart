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

  /// ✅ Add this:
  UserModel copyWith({
    int? userId,
    String? email,
    String? username,
    String? password,
    int? goalMinutes,
    String? dateCreated,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
