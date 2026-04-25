import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "My To Do",
      home: TodoPage()
    );
  }
}

class TodoPage extends StatefulWidget {
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> { 
  final t = TextEditingController();
  List items = [];
  
  // Voice recognition variables
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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

  // Voice listening function
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            t.text = val.recognizedWords;
          }),
          localeId: 'ta_IN', // Specifically tells the app to listen for Tamil
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text("My To Do")),
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
            // Microphone Button
            IconButton(
              onPressed: _listen,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none, 
                color: _isListening ? Colors.red : null
              )
            ),
            // Add Button
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
