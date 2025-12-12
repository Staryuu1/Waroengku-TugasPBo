import '../db/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<bool> register(String username, String password) async {
    try {
      await _db.insertUser(User(username: username, password: password));
      return true;
    } catch (e) {
      return false; // username duplicate
    }
  }

  Future<User?> login(String username, String password) async {
    return await _db.login(username, password);
  }
}
