import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
class AileController {
  Future<String?> showRegistrationCodeDialog(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kayıt Kodunu Girin'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Kayıt Kodunu Girin"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text('Gönder'),
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateUserFamilyID(String userID,String f_id) async {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref('users');

    try {
      // Belirtilen userID'yi eşleştiren kullanıcı verilerini çek
      final snapshot = await databaseReference.orderByChild('userID').equalTo(userID).get();

      // Eğer veriler mevcutsa
      if (snapshot.exists) {
        final userMap = snapshot.value as Map<dynamic, dynamic>;

        if (userMap.isNotEmpty) {
          // İlk anahtarı al
          final key = userMap.keys.first;

          // 'name' alanını boş bırakacak şekilde güncelle
          await databaseReference.child(key).update({
            'familyID': f_id,
          });

          print('Kullanıcı familyID güncellendi.');
        }
      } else {
        print('Kullanıcı bulunamadı.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> fetchFamilyDataByRegistrationCode(String registrationCode, BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen giriş yapınız.')),
      );
      return;
    }

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('families');

    try {
      final query = dbRef.orderByChild('registrationCode').equalTo(registrationCode);
      final snapshot = await query.get();

      if (snapshot.exists) {
        // Veriyi al
        final familyDataMap = snapshot.value as Map<Object?, Object?>;

        // Document ID'yi al
        final documentId = familyDataMap.keys.first as String;
        print(documentId);

        updateUserFamilyID(user.uid, documentId);


        // Verinin içeriğini al
        final familyData = familyDataMap[documentId] as Map<Object?, Object?>;

        // Kullanıcı üyeliği kontrolü
        final members = (familyData['members'] as Map<Object?, Object?>)
            .map((key, value) => MapEntry(key as String, value as Map<Object?, dynamic>));

        if (members.containsKey(user.uid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kullanıcı zaten bu aileye üye.')),
          );
          return;
        }

        // Kullanıcıyı aile üyeleri listesine ekle
        final updatedMembers = {
          ...members,
          user.uid: {'role': 'Member','userId':user.uid},
        };

        // Veriyi güncelle
        await dbRef.child(documentId).update({
          'members': updatedMembers,
        });

        // Document ID'yi paylaşmak için SharedPreferences'e kaydet
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastCreatedFamilyId', documentId);

        // Page2'ye yönlendirme
        Navigator.pushReplacementNamed(
          context,
          '/aile_icerik',
          arguments: {'documentId': documentId},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aile bilgileri bulunamadı.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aile bilgileri alınırken bir hata oluştu.')),
      );
    }
  }

  late DatabaseReference familyRef;
  Map<String, dynamic>? familyData;
  bool isLoading = true;
  String? documentId;

  Future<String?> getLastCreatedFamilyId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastCreatedFamilyId');
  }
  Future<void> testSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('SharedPreferences initialized: ${prefs != null}');
    await prefs.setString('testKey', 'testValue');
    final String? value = prefs.getString('testKey');
    print('Test value retrieved: $value');
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

  Future<String?> getUserRole(String userID) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return null;
    }

    final databaseReference = FirebaseDatabase.instance.ref('families');

    try {
      // Kullanıcının ait olduğu ailenin ID'sini almak için öncelikle ailenin belgelerinden alın.
      final familiesSnapshot = await databaseReference.get();

      if (familiesSnapshot.exists) {
        final familiesMap = familiesSnapshot.value as Map<dynamic, dynamic>;

        for (var familyEntry in familiesMap.entries) {
          final familyID = familyEntry.key;
          final familyData = familyEntry.value as Map<dynamic, dynamic>;

          final members = familyData['members'] as Map<dynamic, dynamic>?;

          if (members != null && members.containsKey(userID)) {
            final userRole = members[userID]['role'];
            return userRole;
          }
        }
      }

      return null; // Rol bilgisi bulunamadı
    } catch (e) {
      print('Error: $e');
      return null; // Hata durumunda null döndür
    }
  }

}