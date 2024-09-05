import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/aile_controller.dart';  // Import shared_preferences


class AileIcerik extends StatefulWidget {
  @override
  _AileIcerikState createState() => _AileIcerikState();
}

class _AileIcerikState extends State<AileIcerik> {
  final AileController _controller = AileController();



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      _controller.documentId = arguments['documentId'];
      print('Gelen belge ID: $_controller.documentId');
      _controller.testSharedPreferences();
      if (_controller.documentId != null) {
        _fetchFamilyData(_controller.documentId!);
      }
    } else {
      // Optionally, you might want to check shared preferences here
      _controller.getLastCreatedFamilyId().then((documentId) {
        if (documentId != null) {
          _fetchFamilyData(documentId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Belge ID\'si sağlanmamış.')),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _fetchFamilyData(String documentId) async {
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
      final snapshot = await dbRef.child(documentId).get();

      if (snapshot.exists) {
        // Safely cast the snapshot value to a Map<String, dynamic>
        final familyData = snapshot.value as Map<dynamic, dynamic>?;

        if (familyData != null) {
          // Convert the dynamic map to a Map<String, dynamic>
          final familyDataTyped = Map<String, dynamic>.from(familyData);

          print('Veri bulundu: $familyDataTyped');

          setState(() {
            _controller.familyData = familyDataTyped;
            _controller.isLoading = false;
          });
        } else {
          print('Veri bulunamadı');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aile bilgileri bulunamadı.')),
          );
          Navigator.pop(context); // Go back if no data is found
        }
      } else {
        print('Veri bulunamadı');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aile bilgileri bulunamadı.')),
        );
        Navigator.pop(context); // Go back if no data is found
      }
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aile bilgileri alınırken bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Aile Bilgileri'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Anasayfa'),
                onTap: () {
                  Navigator.pushNamed(context, '/home');
                },
              ),
              ListTile(
                leading: Icon(Icons.pageview),
                title: Text('Aile Giriş ve Kayıt'),
                onTap: () {
                  Navigator.pushNamed(context, '/aile_giris');
                },
              ),
              ListTile(
                leading: Icon(Icons.pages),
                title: Text('Aile Üyeleri'),
                onTap: () {
                  Navigator.pushNamed(context, '/aile_icerik');
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Aile Bilgileri'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Anasayfa'),
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.pageview),
              title: Text('Aile Giriş ve Kayıt'),
              onTap: () {
                Navigator.pushNamed(context, '/aile_giris');
              },
            ),
            ListTile(
              leading: Icon(Icons.pages),
              title: Text('Aile Üyeleri'),
              onTap: () {
                Navigator.pushNamed(context, '/aile_icerik');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kayıt Numarası: ${_controller.familyData?['registrationCode'] ?? 'Yok'}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Üyeler:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.familyData?['members']?.length ?? 0,
                itemBuilder: (context, index) {
                  final member = _controller.familyData!['members'].entries.elementAt(index);
                  return ListTile(
                    title: Text(member.key),  // Üye ID'si
                    subtitle: Text('Rol: ${member.value['role']}'),  // Üye rolü
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
