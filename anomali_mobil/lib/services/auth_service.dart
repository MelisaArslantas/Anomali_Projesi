import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase'in kapılarını açan yetkili araçlar
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni Kullanıcı Kayıt Fonksiyonu
  Future<String?> registerUser({
    required String email,
    required String password,
    required double monthlyIncome, // ✅ ANALİZ
    required String incomeGroup,   // ✅ ANALİZ
    String? name,                  // 🟡 UX (Opsiyonel)
  }) async {
    try {
      // 1. Firebase Auth üzerinde kullanıcıyı oluştur (Email/Şifre ile)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Kullanıcı başarılı oluştuktan sonra Firestore'a detaylı bilgileri yaz
      // 'users' koleksiyonu altında kullanıcının UID'si ile bir döküman açıyoruz
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name ?? "Kullanıcı", // İsim yoksa varsayılan değer verilir
        'monthly_income': monthlyIncome,
        'income_group': incomeGroup,
        'created_at': DateTime.now(), // Kayıt tarihi (Raporlama için önemli)
        'role': 'user', // İleride admin paneli yaparsan ayrım için
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      // Firebase'den gelen özel hatalar (Örn: Email zaten kullanımda)
      return e.message;
    } catch (e) {
      // Diğer genel hatalar
      return e.toString();
    }
  }
}