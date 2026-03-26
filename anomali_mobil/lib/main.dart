import 'package:flutter/material.dart';
import 'screens/analiz_form_screen.dart';

void main() {
  runApp(const AnomaliApp());
}

class AnomaliApp extends StatelessWidget {
  const AnomaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Anomali Tespit",
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
      home: const AnalizFormScreen(), // Yeni oluşturduğumuz ekrana yönlendiriyoruz
    );
  }
}