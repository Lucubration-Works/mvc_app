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
          user.uid: {'role': 'Member'},
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



}