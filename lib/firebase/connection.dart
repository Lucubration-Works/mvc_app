import 'package:firebase_core/firebase_core.dart';

class FirebaseConnection {
  final FirebaseApp firebaseApp;
  FirebaseConnection(this.firebaseApp);

  static Future<FirebaseConnection> initialize() async {
    FirebaseApp app = await Firebase.initializeApp(
        name: 'familyplan',
        options: const FirebaseOptions(
            apiKey: 'AIzaSyCOCZafhmoOtEELGkRPc7ReAyJnlweMZBQ',
            authDomain: 'familyplan-d52ef.firebaseapp.com',
            projectId: 'familyplan-d52ef',
            storageBucket: 'familyplan-d52ef.appspot.com',
            messagingSenderId: '540460427270',
            appId: '1:540460427270:android:e8c24cbbae17654999fb87',
            databaseURL: 'https://familyplan-d52ef-default-rtdb.firebaseio.com'
    ));
    return FirebaseConnection(app);
  }

  FirebaseApp getApp() {
    return firebaseApp;
  }
}
