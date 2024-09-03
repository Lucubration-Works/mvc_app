import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
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
              title: Text('Sayfa 1'),
              onTap: () {
                Navigator.pushNamed(context, '/page1');
              },
            ),
            ListTile(
              leading: Icon(Icons.pages),
              title: Text('Sayfa 2'),
              onTap: () {
                Navigator.pushNamed(context, '/page2');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Sayfa 1 İçeriği', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
