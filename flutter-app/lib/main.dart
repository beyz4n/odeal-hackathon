import 'package:azure_chat/src/chat.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primaryContainer: Colors.white, // green
          secondaryContainer: Colors.white, // light gray
          background: Colors.white60, // almost black
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ödeal Chatbot'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.lightBlue,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
          title: Text(title),
        ),
        body: const Center(
          child: Chat(),
        ),
      ),
    );
  }
}
