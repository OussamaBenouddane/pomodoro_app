import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/model/user_model.dart';

class UserRepository {
  final DBHelper dbHelper;

  UserRepository(this.dbHelper);

  Future<UserModel?> getUserByEmail(String email) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      [email],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM users WHERE user_id = ? LIMIT 1',
      [userId],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertUser(UserModel user) async {
    return await dbHelper.insertData('users', user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    return await dbHelper.updateData('users', user.toMap(), 'user_id = ?', [
      user.userId,
    ]);
  }

  Future<void> deleteUser(int userId) async {
    await dbHelper.deleteData(
      'users',
      whereClause: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final result = await dbHelper.readData('SELECT * FROM users');
    return result.map((e) => UserModel.fromMap(e)).toList();
  }
}
