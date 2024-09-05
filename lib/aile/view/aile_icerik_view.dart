import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../controller/aile_controller.dart'; // Import shared_preferences

class AileIcerik extends StatefulWidget {
  @override
  _AileIcerikState createState() => _AileIcerikState();
}

class _AileIcerikState extends State<AileIcerik> {
  final AileController _controller = AileController();

  Future<void> fetchFamilyData(String documentId) async {
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
        final familyData = snapshot.value as Map<dynamic, dynamic>?;

        if (familyData != null) {
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
          Navigator.pop(context);
        }
      } else {
        print('Veri bulunamadı');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aile bilgileri bulunamadı.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aile bilgileri alınırken bir hata oluştu.')),
      );
    }
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      _controller.documentId = arguments['documentId'];
      print('Gelen belge ID: $_controller.documentId');
      _controller.testSharedPreferences();
      if (_controller.documentId != null) {
        fetchFamilyData(_controller.documentId!);
      }
    } else {
      // Optionally, you might want to check shared preferences here
      _controller.getLastCreatedFamilyId().then((documentId) {
        if (documentId != null) {
          fetchFamilyData(documentId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Belge ID\'si sağlanmamış.')),
          );
          Navigator.pop(context);
        }
      });
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
            FutureBuilder<String?>(
              future: _controller.getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final userId = snapshot.data;
                  return Text(
                    'User ID: ${userId ?? 'Bilinmiyor'}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  );
                } else {
                  return Text('Kullanıcı oturum açmamış.');
                }
              },
            ),
            FutureBuilder<String?>(
              future: _controller.getCurrentUserId(),
              builder: (context, userIdSnapshot) {
                if (userIdSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (userIdSnapshot.hasError) {
                  return Text('Hata: ${userIdSnapshot.error}');
                } else if (userIdSnapshot.hasData) {
                  final userId = userIdSnapshot.data;
                  return FutureBuilder<String?>(
                    future: _controller.getUserRole(userId!),
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (roleSnapshot.hasError) {
                        return Text('Hata: ${roleSnapshot.error}');
                      } else if (roleSnapshot.hasData) {
                        final role = roleSnapshot.data;
                        return Text(
                          role == 'Admin' ? 'Admin' : 'Üye',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        );
                      } else {
                        return Text('Rol bilgisi bulunamadı.');
                      }
                    },
                  );
                } else {
                  return Text('Kullanıcı oturum açmamış.');
                }
              },
            ),
            SizedBox(height: 20),
            Text(
              'Üyeler:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<String?>(
                future: _controller.getCurrentUserId(),
                // Geçerli kullanıcı ID'sini al
                builder: (context, userIdSnapshot) {
                  if (userIdSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userIdSnapshot.hasError) {
                    return Center(child: Text('Hata: ${userIdSnapshot.error}'));
                  } else if (!userIdSnapshot.hasData) {
                    return Center(child: Text('Kullanıcı oturum açmamış.'));
                  }

                  final currentUserId = userIdSnapshot.data;

                  // Kullanıcının rolünü al
                  return FutureBuilder<String?>(
                    future: currentUserId != null
                        ? _controller.getUserRole(currentUserId)
                        : null,
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (roleSnapshot.hasError) {
                        return Center(
                            child: Text('Hata: ${roleSnapshot.error}'));
                      } else if (!roleSnapshot.hasData) {
                        return Center(child: Text('Rol bulunamadı.'));
                      }

                      final userRole = roleSnapshot.data;

                      return ListView.builder(
                        itemCount:
                            _controller.familyData?['members']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final member = _controller
                              .familyData?['members']?.entries
                              .elementAt(index);

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: member != null
                                ? _controller.getUserDataById(member.key)
                                : null,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  title: Text(member?.key ?? ''),
                                  // Üye ID'si
                                  subtitle: Text('Yükleniyor...'),
                                  // Yükleniyor mesajı
                                  trailing: userRole == 'Admin'
                                      ? IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Düzenleme işlemi için gerekli kod burada olacak
                                            // Örneğin: Navigator.pushNamed(context, '/edit', arguments: userData);
                                          },
                                        )
                                      : null,
                                );
                              } else if (snapshot.hasError) {
                                return ListTile(
                                  title: Text(member?.key ?? ''),
                                  // Üye ID'si
                                  subtitle: Text('Hata: ${snapshot.error}'),
                                  // Hata mesajı
                                  trailing: userRole == 'Admin'
                                      ? IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Düzenleme işlemi için gerekli kod burada olacak
                                            // Örneğin: Navigator.pushNamed(context, '/edit', arguments: userData);
                                          },
                                        )
                                      : null,
                                );
                              } else if (snapshot.hasData) {
                                final userData = snapshot.data!;
                                return ListTile(
                                  title: Text(
                                      userData['name'] ?? member?.key ?? ''),
                                  // Üye adı
                                  subtitle: Text(
                                      'Rol: ${member?.value['role'] ?? ''} - ${member?.key ?? ''}'),
                                  // Üye rolü
                                  trailing: userRole == 'Admin'
                                      ? IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Düzenleme işlemi için gerekli kod burada olacak
                                            // Örneğin: Navigator.pushNamed(context, '/edit', arguments: userData);
                                          },
                                        )
                                      : null,
                                );
                              } else {
                                return ListTile(
                                  title: Text(member?.key ?? ''),
                                  // Üye ID'si
                                  subtitle: Text('Veri bulunamadı'),
                                  // Veri bulunamadı mesajı
                                  trailing: userRole == 'Admin'
                                      ? IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Düzenleme işlemi için gerekli kod burada olacak
                                            // Örneğin: Navigator.pushNamed(context, '/edit', arguments: userData);
                                          },
                                        )
                                      : null,
                                );
                              }
                            },
                          );
                        },
                      );
                    },
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
