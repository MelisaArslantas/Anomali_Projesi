import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase araçlarını tanımlıyoruz
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 1. KAYIT OLMA FONKSİYONU (IP2: Veri Tabanı Mimarisi)
  Future<String?> registerUser({
    required String email,
    required String password,
    required double monthlyIncome, // Analiz için kritik
    required String incomeGroup,   // Analiz için kritik
    String? name,                  // Kullanıcı Deneyimi (UX)
  }) async {
    try {
      // Firebase Auth üzerinde kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Oluşturulan kullanıcının UID'si ile Firestore'a detayları kaydet
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name ?? "Kullanıcı",
        'monthly_income': monthlyIncome,
        'income_group': incomeGroup,
        'created_at': DateTime.now(),
        'role': 'user',
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ 2. GİRİŞ YAPMA FONKSİYONU (IP3 Hazırlığı)
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      // Yanlış şifre veya kullanıcı bulunamadı hatalarını yakalar
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ 3. VERİ ÇEKME FONKSİYONU (Dashboard'u canlandırmak için)
  // Bu fonksiyon ile ana sayfada "Hoş geldin Melisa" diyebileceğiz.
  Future<DocumentSnapshot?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return await _firestore.collection('users').doc(user.uid).get();
      }
      return null;
    } catch (e) {
      print("Firestore veri çekme hatası: $e");
      return null;
    }
  }

  // ✅ 4. ÇIKIŞ YAPMA
  Future<void> logout() async {
    await _auth.signOut();
  }
}