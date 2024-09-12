import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToDoController{

  late DatabaseReference familyRef;
  Map<String, dynamic>? familyData;
  bool isLoading = true;
  String? documentId;

  Future<String?> getLastCreatedFamilyId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastCreatedFamilyId');
  }

  Future<Map<String, dynamic>?> getUserDataById(String userID) async {
    final databaseReference = FirebaseDatabase.instance.ref('users');
    try {
      final snapshot = await databaseReference.orderByChild('userID').equalTo(userID).get();
      if (snapshot.exists) {
        final userMap = snapshot.value as Map<dynamic, dynamic>;
        if (userMap.isNotEmpty) {
          final key = userMap.keys.first;
          return Map<String, dynamic>.from(userMap[key]);
        }
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<String?> getCurrentUserId() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      // Kullanıcı oturum açmış, kullanıcı ID'sini döndür
      return user.uid;
    } else {
      // Kullanıcı oturum açmamış, null döndür
      return null;
    }
  }

  Future<String> getUserNameById(String userId) async {
    final userData = await getUserDataById(userId);
    return userData?['name'] ?? 'Unknown'; // Kullanıcı adı bulunamazsa 'Unknown' döndür
  }



}