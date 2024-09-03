import 'package:flutter/material.dart';

import '../../firebase/realtime_database.dart';
import '../../firebase/user_management.dart';

class SignUpController {
  TextEditingController name_controller = TextEditingController();
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  TextEditingController confirm_password_controller = TextEditingController();

  Future<bool> sign_up(String email, String password) async {
    if (password_controller.value.text ==
        confirm_password_controller.value.text) {
      try {
        FirebaseUserManager userManager = FirebaseUserManager();
        FirebaseUser newUser = await userManager.createUser(email, password);
        print('Created user: ${newUser.email}');
        try {
          RealtimeDatabaseConnection connection = await RealtimeDatabaseConnection.initialize();
          RealtimeDatabaseManager manager = RealtimeDatabaseManager(connection.getRealtimeDb().ref(), 'users');
          await manager.create({'name': name_controller.value.text, 'email': email_controller,'password': password_controller.value.text});
          print('User added to Realtime Database');
        } catch (e) {
          print('Database Error: $e');
        }

        return true;
      } catch (e) {
        print('Create User Error: $e');
        return false;
      }
    } else {
      return false;
    }
  }
}
