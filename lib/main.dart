import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Gobi's To Do",
      home: TodoPage()
    );
  }
}

class TodoPage extends StatefulWidget {
  @override
  State<TodoPage> createState() => _TodoPageState(); // Underscore here
}

// Added the missing underscore to the class name to match createState()
class _TodoPageState extends State<TodoPage> { 
  final t = TextEditingController();
  List items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => items = jsonDecode(p.getString('items') ?? '[]'));
  }

  Future save() async {
    final p = await SharedPreferences.getInstance();
    p.setString('items', jsonEncode(items));
  }

  void add() {
    if (t.text.trim().isEmpty) return;
    setState(() => items.insert(0, {"text": t.text, "done": false}));
    t.clear();
    save();
  }

  void toggle(i) {
    setState(() => items[i]['done'] = !items[i]['done']);
    save();
  }

  void del(i) {
    setState(() => items.removeAt(i));
    save();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text("Gobi's To Do")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Text('என் தினசரி பணிகள்'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: t,
                decoration: InputDecoration(hintText: 'பணி சேர்க்கவும்')
              )
            ),
            IconButton(
              onPressed: add,
              icon: Icon(Icons.add_circle)
            )
          ]),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (c, i) => ListTile(
                leading: Checkbox(
                  value: items[i]['done'],
                  onChanged: (val) => toggle(i)
                ),
                title: Text(
                  items[i]['text'],
                  style: TextStyle(
                    decoration: items[i]['done'] ? TextDecoration.lineThrough : null
                  )
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => del(i)
                ),
              )
            )
          )
        ])
      ),
    );
  }
}
