
import 'package:family_plan/firebase/realtime_database.dart';
import 'package:family_plan/firebase/user_management.dart';
import 'package:flutter/material.dart';

import 'connection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseConnection connection = await FirebaseConnection.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Exampl'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  FirebaseUser user = await FirebaseUser.signIn('test@example.com', 'password123');
                  print('Signed in as: ${user.email}');
                } catch (e) {
                  print('Sign In Error: $e');
                }
              },
              child: Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  FirebaseUserManager userManager = FirebaseUserManager();
                  FirebaseUser newUser = await userManager.createUser(
                    'newuser2@example.com',
                    'password123',
                  );
                  print('Created user: ${newUser.email}');
                } catch (e) {
                  print('Create User Error: $e');
                }
              },
              child: Text('Create User'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  RealtimeDatabaseConnection connection =await RealtimeDatabaseConnection.initialize();
                  RealtimeDatabaseManager manager = RealtimeDatabaseManager(connection.getRealtimeDb().ref(), 'users');
                  await manager.create({'name': 'John Doe', 'age': 31});
                  print('User added to Realtime Database');
                } catch (e) {
                  print('Database Error: $e');
                }
              },
              child: Text('Add Data to Realtime Database'),
            ),
          ],
        ),
      ),
    );
  }
}
