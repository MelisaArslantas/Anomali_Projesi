import 'dart:io'; // 'File' tipini tanımak için bu satır şart!
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Mevcut giriş yapmış kullanıcının UID'sini alır
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "unknown";

  /// Profil fotoğrafını Firebase Storage'a yükler ve indirme URL'sini döndürür
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      // 1. Dosyanın Storage'da nereye kaydedileceğini belirle
      // 'profile_photos/KULLANICI_ID.jpg' yoluna kaydeder
      Reference ref = _storage.ref().child("profile_photos").child("$_uid.jpg");

      // 2. Dosyayı yükle
      UploadTask uploadTask = ref.putFile(imageFile);

      // 3. Yükleme tamamlanana kadar bekle
      TaskSnapshot snapshot = await uploadTask;

      // 4. Yüklenen fotoğrafın internet adresini (URL) al
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print("Firebase Storage Yükleme Hatası: $e");
      return null;
    }
  }
}