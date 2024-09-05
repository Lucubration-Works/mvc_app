import 'package:family_plan/aile/controller/aile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import QrFlutter package if not already

class AileGiris extends StatefulWidget {
  const AileGiris({super.key});

  @override
  State<AileGiris> createState() => _AileGirisState();
}

class _AileGirisState extends State<AileGiris> {
  final AileController _controller = AileController();
  String? _familyDocumentId;

  Future<void> _generateQrCode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final documentId = prefs.getString('lastCreatedFamilyId');

    if (documentId != null) {
      try {
        final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('families/$documentId');
        final snapshot = await databaseRef.get();

        if (snapshot.exists) {
          final familyData = snapshot.value as Map<Object?, Object?>;
          final registrationCode = familyData['registrationCode'] as String?;

          if (registrationCode != null) {
            setState(() {
              _familyDocumentId = registrationCode;
              print('QR kodu için kayıt kodu: $_familyDocumentId');
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kayıt kodu bulunamadı.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aile bilgileri bulunamadı.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt kodu alınırken bir hata oluştu.')),
        );
        print(e);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aile ID\'si bulunamadı.')),
      );
    }
  }

  Future<void> _saveQrCode(BuildContext context, String familyDocumentId) async {
    try {
      // Create a QR code image
      final qrPainter = QrPainter(
        data: familyDocumentId,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final qrImage = await qrPainter.toImage(200);

      // Convert image to byte data
      final ByteData? byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/qr_code.png';

      // Write byte data to file
      final file = File(path);
      await file.writeAsBytes(uint8List);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR kodu kaydedildi: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR kodu kaydedilirken bir hata oluştu.')),
      );
      print(e);
    }
  }
  // Future<void> _pickAndReadQrCode() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (pickedFile == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Bir resim seçmediniz.')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final file = File(pickedFile.path);
  //     final data = await QrCodeToolsPlugin.decodeFrom(file.path);
  //
  //     if (data != null) {
  //       final registrationCode = data;
  //       await _controller.fetchFamilyDataByRegistrationCode(registrationCode, context);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('QR kodu okunamadı.')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('QR kodu okunurken bir hata oluştu.')),
  //     );
  //     print(e);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sayfa 1'),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lütfen bir seçenek seçin',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final FirebaseAuth auth = FirebaseAuth.instance;
                  final User? user = auth.currentUser;

                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lütfen giriş yapınız.')),
                    );
                    return;
                  }

                  try {
                    final DatabaseReference databaseRef = FirebaseDatabase.instance.ref('families');
                    final DatabaseReference newRef = databaseRef.push();
                    final String documentId = newRef.key!;
                    final String registrationCode = documentId.substring(0, 6);
                    final String userId = user.uid;
                    final DateTime creationTime = DateTime.now();

                    final Map<String, dynamic> familyData = {
                      'registrationCode': registrationCode,
                      'members': {
                        userId: {
                          'role': 'Admin',
                        },
                      },
                      'creatorId': userId,
                      'creationTime': creationTime.toIso8601String(),
                    };

                    print('Kayıt Kodu: $registrationCode');
                    print('Giden belge id: $documentId');

                    await newRef.set(familyData);

                    // Save the document ID to shared preferences
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString('lastCreatedFamilyId', documentId);

                    // Navigate to Page2
                    Navigator.pushReplacementNamed(
                      context,
                      '/page2',
                      arguments: {'documentId': documentId},
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Aile oluşturulurken bir hata oluştu.')),
                    );
                    print(e);
                  }
                },
                child: Text('Aile Oluştur'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Kullanıcıdan kayıt kodunu al
                  final registrationCode = await _controller.showRegistrationCodeDialog(context);

                  if (registrationCode == null || registrationCode.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Geçersiz kayıt kodu.')),
                    );
                    return;
                  }
                  await _controller.fetchFamilyDataByRegistrationCode(registrationCode, context);
                },
                child: Text('Aileye Katıl'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _generateQrCode();
                  if (_familyDocumentId != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('QR Kodu'),
                          content: SizedBox(
                            width: 200, // Sabit bir genişlik veriyoruz
                            height: 200, // Sabit bir yükseklik veriyoruz
                            child: QrImageView(
                              data: _familyDocumentId!,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Kaydet'),
                              onPressed: () async {
                                // QR kodunu kaydetme işlemini burada yapabilirsiniz
                                // Örneğin, QR kodunu görüntü olarak kaydetme
                                await _saveQrCode(context,_familyDocumentId!);
                              },
                            ),
                            TextButton(
                              child: Text('Kapat'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('QR Kodu Üret'),
              ),
              ElevatedButton(
                onPressed: (){},
                child: Text('QR Kodunu Oku'),
              ),




            ],
          ),
        ),
      ),
    );
  }
}
