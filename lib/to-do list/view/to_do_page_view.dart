import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/to_do_controller.dart';

class ToDoPageView extends StatefulWidget {
  const ToDoPageView({super.key});

  @override
  State<ToDoPageView> createState() => _ToDoPageViewState();
}

class _ToDoPageViewState extends State<ToDoPageView> {
  final TextEditingController _todoController = TextEditingController();
  final ToDoController _controller = ToDoController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref('todos');

  List<Map<String, dynamic>> _todos = [];
  Map<String, String> _userNames = {}; // Kullanıcı adlarını saklayacağımız bir harita
  bool _isLoading = true; // Yükleme durumunu göstermek için bir bayrak

  // Kullanıcı adını almak için işlev


  Future<void> _addTodo() async {
    String? familyId = await _controller.getLastCreatedFamilyId(); // FamilyId almak
    String? userId = await _controller.getCurrentUserId(); // UserId almak

    if (familyId != null && userId != null && _todoController.text.isNotEmpty) {
      final newTodoRef = _database.child('$familyId/todos').push(); // todos altında yeni bir kayıt oluştur

      await newTodoRef.set({
        'content': _todoController.text,
        'updatedAt': formatDate(DateTime.now()), // Tarihi string olarak saklıyoruz
        'userId': userId
      });

      setState(() {
        _todoController.clear(); // TextField temizle
      });

      // Yeni eklenen ToDo'yu tekrar yükle
      _fetchTodos();
    }
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Future<void> _fetchTodos() async {
    String? familyId = await _controller.getLastCreatedFamilyId();

    if (familyId != null) {
      DatabaseReference familyTodosRef = _database.child('$familyId/todos');

      setState(() {
        _isLoading = true; // Yükleme başladığında
      });

      DatabaseEvent event = await familyTodosRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> todoData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> loadedTodos = [];

        todoData.forEach((key, value) {
          loadedTodos.add({
            'id': key,
            'content': value['content'],
            'updatedAt': value['updatedAt'],
            'userId': value['userId']
          });
        });

        setState(() {
          _todos = loadedTodos;
          _fetchUserNames(); // Kullanıcı adlarını yükle
        });
      } else {
        setState(() {
          _todos = []; // Eğer veri yoksa boş liste
        });
      }

      setState(() {
        _isLoading = false; // Yükleme tamamlandığında
      });
    }
  }

  Future<void> _fetchUserNames() async {
    final Map<String, String> names = {};
    for (var todo in _todos) {
      final userId = todo['userId'];
      if (userId != null && !names.containsKey(userId)) {
        final userName = await _controller.getUserNameById(userId);
        names[userId] = userName;
      }
    }
    setState(() {
      _userNames = names;
    });
  }

  Future<void> _deleteTodo(String todoId) async {
    String? familyId = await _controller.getLastCreatedFamilyId();

    if (familyId != null) {
      final todoRef = _database.child('$familyId/todos/$todoId');
      await todoRef.remove();

      // Silme işleminden sonra ToDo'ları tekrar yükle
      _fetchTodos();
    }
  }

  Future<void> _editTodo(String todoId, String currentContent) async {
    final TextEditingController _editController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit ToDo'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(
              labelText: 'ToDo Content',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                String? familyId = await _controller.getLastCreatedFamilyId();
                String? userId = await _controller.getCurrentUserId();

                if (familyId != null && userId != null) {
                  final todoRef = _database.child('$familyId/todos/$todoId');

                  await todoRef.update({
                    'content': _editController.text,
                    'updatedAt': formatDate(DateTime.now()),
                    'userId': userId
                  });

                  Navigator.of(context).pop();
                  _fetchTodos(); // Düzenleme tamamlandığında ToDo'ları tekrar yükle
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _todoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter a new ToDo',
                ),
                onSubmitted: (value) => _addTodo(),
              ),
            ),
            ElevatedButton(
              onPressed: _addTodo,
              child: const Text('Add ToDo'),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Yüklenirken göstergesi
                  : _todos.isEmpty
                  ? const Center(child: Text('No ToDos available'))
                  : ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  final userName = _userNames[todo['userId']] ?? 'Loading...'; // Kullanıcı adı yüklenene kadar 'Loading...' yazısı
                  return ListTile(
                    title: Text(todo['content']),
                    subtitle: Text('Last updated by user: $userName on ${todo['updatedAt']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTodo(todo['id'], todo['content']), // Düzenleme işlevini çağır
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTodo(todo['id']), // Silme işlevini çağır
                        ),
                      ],
                    ),
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
