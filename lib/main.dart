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
      title: "Tiger Tasks",
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepOrangeAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrangeAccent,
          secondary: Colors.orange,
        ),
      ),
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            t.text = val.recognizedWords;
          }),
          localeId: 'ta_IN',
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: const [
            Text('💪🏻', style: TextStyle(fontSize: 28)), 
            SizedBox(width: 12),
            Text("புலிப் பணிகள்", style: TextStyle(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ]
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            height: 2.0,
            // The fix is here: moving color and boxShadow inside BoxDecoration
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent,
              boxShadow: [
                BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A0A00)], 
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.deepOrangeAccent, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.2), blurRadius: 8)
                ]
              ),
              child: Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: t,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'பணி சேர்க்கவும்...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      )
                    ),
                  )
                ),
                IconButton(
                  onPressed: _listen,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none, 
                    color: _isListening ? Colors.redAccent : Colors.deepOrangeAccent
                  )
                ),
                IconButton(
                  onPressed: add,
                  icon: const Icon(Icons.add_box, color: Colors.deepOrangeAccent)
                )
              ]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (c, i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border(left: BorderSide(color: items[i]['done'] ? Colors.green : Colors.deepOrangeAccent, width: 4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      activeColor: Colors.deepOrangeAccent,
                      checkColor: Colors.black,
                      value: items[i]['done'],
                      onChanged: (val) => toggle(i)
                    ),
                    title: Text(
                      items[i]['text'],
                      style: TextStyle(
                        color: items[i]['done'] ? Colors.white38 : Colors.white,
                        decoration: items[i]['done'] ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w500
                      )
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54),
                      onPressed: () => del(i)
                    ),
                  )
                )
              )
            )
          ])
        ),
      ),
    );
  }
}
