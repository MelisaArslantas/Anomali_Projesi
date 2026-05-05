import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // ✅ Eklendi
import 'screens/dashboard_screen.dart'; // ✅ Eklendi

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

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
      // Uygulama başladığında ilk açılacak sayfa
      initialRoute: '/login', 
      
      // ✅ Sayfa Rotaları (Routes)
      // Bu tablo sayesinde Navigator.pushNamed('/dashboard') komutu çalışır hale gelir.
      routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/dashboard': (context) => const DashboardScreen(userEmail: "Kullanıcı"), // ✅ Buraya userEmail parametresini ekledik
},
    );
  }
}