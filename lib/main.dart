import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  
  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
  await notificationsPlugin.initialize(initSettings);
  
  runApp(const MyApp());
}

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
  
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    load();
    requestPermissions();
  }

  void requestPermissions() async {
    await notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  Future load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => items = jsonDecode(p.getString('items') ?? '[]'));
  }

  Future save() async {
    final p = await SharedPreferences.getInstance();
    p.setString('items', jsonEncode(items));
  }

  void pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.deepOrangeAccent)), child: child!),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.deepOrangeAccent)), child: child!),
      );
      if (time != null) {
        setState(() {
          selectedDate = date;
          selectedTime = time;
        });
      }
    }
  }

  void add() async {
    if (t.text.trim().isEmpty) return;
    
    String reminderStr = "";
    if (selectedDate != null && selectedTime != null) {
      final dt = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
      reminderStr = DateFormat('yyyy-MM-dd hh:mm a').format(dt);
      
      if (dt.isAfter(DateTime.now())) {
        await notificationsPlugin.zonedSchedule(
          items.length,
          'புலிப் பணிகள்',
          t.text,
          tz.TZDateTime.from(dt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails('tiger_channel', 'Tiger Reminders', importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher'),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    
    setState(() {
      items.insert(0, {"text": t.text, "done": false, "reminder": reminderStr});
      selectedDate = null;
      selectedTime = null;
    });
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
        _speech.listen(onResult: (val) => setState(() => t.text = val.recognizedWords), localeId: 'ta_IN');
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
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent,
              boxShadow: [BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Color(0xFF1A0A00)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.deepOrangeAccent, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.2), blurRadius: 8)]
              ),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: t,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'பணி சேர்க்கவும்...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none)
                        ),
                      )
                    ),
                    IconButton(
                      onPressed: pickDateTime,
                      icon: Icon(Icons.alarm_add, color: selectedDate != null ? Colors.greenAccent : Colors.white54)
                    ),
                    IconButton(
                      onPressed: _listen,
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.redAccent : Colors.deepOrangeAccent)
                    ),
                    IconButton(onPressed: add, icon: const Icon(Icons.add_box, color: Colors.deepOrangeAccent))
                  ]),
                  if (selectedDate != null && selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "⏰ ${DateFormat('MMM dd, yyyy').format(selectedDate!)} at ${selectedTime!.format(context)}",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
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
                    leading: Checkbox(activeColor: Colors.deepOrangeAccent, checkColor: Colors.black, value: items[i]['done'], onChanged: (val) => toggle(i)),
                    title: Text(items[i]['text'], style: TextStyle(color: items[i]['done'] ? Colors.white38 : Colors.white, decoration: items[i]['done'] ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w500)),
                    subtitle: items[i]['reminder'] != null && items[i]['reminder'].toString().isNotEmpty
                      ? Text('⏰ ${items[i]['reminder']}', style: TextStyle(color: items[i]['done'] ? Colors.white24 : Colors.white54, fontSize: 12))
                      : null,
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white54), onPressed: () => del(i)),
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
