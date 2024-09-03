import 'package:family_plan/firebase/connection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseConnection extends FirebaseConnection {
  final FirebaseDatabase realtimeDb;

  RealtimeDatabaseConnection._(FirebaseApp app, this.realtimeDb) : super(app);

  static Future<RealtimeDatabaseConnection> initialize() async {
    FirebaseConnection connection = await FirebaseConnection.initialize();
    FirebaseDatabase database = FirebaseDatabase.instance;
    return RealtimeDatabaseConnection._(connection.getApp(), database);
  }

  FirebaseDatabase getRealtimeDb() {
    return realtimeDb;
  }
}

class RealtimeDatabaseManager {
  final DatabaseReference dbRef;
  final String tableName;

  RealtimeDatabaseManager(this.dbRef, this.tableName);

  DatabaseReference _getTableRef() {
    return dbRef.child(tableName);
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _getTableRef().push().set(data);
  }

  Future<DatabaseEvent> read(String key) async {
    return await _getTableRef().child(key).once();
  }

  Future<void> update(String key, Map<String, dynamic> data) async {
    await _getTableRef().child(key).update(data);
  }

  Future<void> delete(String key) async {
    await _getTableRef().child(key).remove();
  }
}
