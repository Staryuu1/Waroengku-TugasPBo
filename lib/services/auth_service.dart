import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // LOGIN
  Future<User?> login(String username, String password) async {
    User? user = await _db.login(username, password);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLogin', true);
      await prefs.setInt('userId', user.id!);
      await prefs.setString('username', user.username);
    }
   
    return user;
  }

  // REGISTER
  Future<bool> register(String username, String password) async {
    try {
      await _db.insertUser(
        User(username: username, password: password),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();

    bool isLogin = prefs.getBool('isLogin') ?? false;
    if (!isLogin) return null;

    int? userId = prefs.getInt('userId');
    String? username = prefs.getString('username');

    if (userId == null || username == null) return null;

    return User(
      id: userId,
      username: username,
      password: '',
    );
  }

  // CEK SESSION
  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLogin') ?? false;
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
