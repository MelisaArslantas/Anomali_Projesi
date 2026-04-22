import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // HATA BURADAYDI: Bu satırı ekleyerek LoginScreen'i tanıttık.

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), 
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Artık sınıf tanınıyor
    );
  }
} // HATA BURADAYDI: Dosyanın bu parantezle bittiğinden emin ol.