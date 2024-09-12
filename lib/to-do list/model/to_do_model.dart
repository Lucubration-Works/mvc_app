import 'package:intl/intl.dart'; // Tarih formatı

class ToDo {
  final String title;
  final String lastEditedBy;
  final DateTime createdAt;

  ToDo({
    required this.title,
    required this.lastEditedBy,
    required this.createdAt,
  });
}