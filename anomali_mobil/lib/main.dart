import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase çekirdek paketi
import 'firebase_options.dart'; // flutterfire configure ile oluşan dosyan
import 'screens/login_screen.dart'; 

void main() async {
  // Flutter motorunun widget'lar yüklenmeden önce hazır olduğundan emin olur
  WidgetsFlutterBinding.ensureInitialized(); 

  // IP2: Firebase bağlantısını başlatan kritik adım
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const LoginScreen(), 
    );
  }
}