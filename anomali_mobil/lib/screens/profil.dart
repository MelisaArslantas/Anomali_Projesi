import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart'; // 🔴 Haftaya eklenecek paket
// import 'package:firebase_storage/firebase_storage.dart'; // 🔴 Haftaya eklenecek paket
import 'dart:io'; // Dosya işlemleri için
import '../services/auth_service.dart';

class ProfilScreen extends StatefulWidget {
  final String userEmail;
  const ProfilScreen({super.key, required this.userEmail});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  String selectedIncomeGroup = "Orta Gelir";
  bool isLoading = true;
  String? _profileImageUrl; // ✅ Fotoğraf URL'sini tutacak
  File? _pickedImage;      // ✅ Yeni seçilen fotoğraf dosyası

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await _authService.getUserData();
    if (userData != null && userData.exists) {
      if (mounted) {
        setState(() {
          _nameController.text = userData['name'] ?? "";
          _incomeController.text = userData['monthly_income']?.toString() ?? "0";
          selectedIncomeGroup = userData['income_group'] ?? "Orta Gelir";
          _profileImageUrl = userData['profile_image_url']; // ✅ URL'yi Firestore'dan oku
          isLoading = false;
        });
      }
    }
  }

  // ✅ 🔴 HAFTAYA YAPILACAK: Fotoğraf Seçme Fonksiyonu
  Future<void> _pickImage() async {
    // Şimdilik boş bırakıyoruz, paketleri kurunca dolduracağız.
    // print("Fotoğraf seçme tetiklendi");
    _showErrorSnackBar("Fotoğraf seçme paketi haftaya kurulacak.");
  }

  // ✅ Verileri ve Fotoğraf URL'sini Güncelliyoruz
  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser; 
    
    if (user != null) {
      try {
        setState(() => isLoading = true);
        
        // 🔴 HAFTAYA YAPILACAK: Eğer yeni fotoğraf seçildiyse Firebase Storage'a yükle
        // String? newImageUrl = _profileImageUrl;
        // if (_pickedImage != null) {
        //   newImageUrl = await _uploadImageToStorage(user.uid);
        // }

        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "name": _nameController.text.trim(),
          "monthly_income": double.tryParse(_incomeController.text) ?? 0.0,
          "income_group": selectedIncomeGroup,
          // "profile_image_url": newImageUrl, // 🔴 Haftaya açılacak
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profil güncellendi!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() => isLoading = false);
        _showErrorSnackBar("Hata: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Profil Bilgileri"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // ✅ FOTOĞRAF ALANI (GELİŞTİRİLDİ)
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage: _profileImageUrl != null 
                          ? NetworkImage(_profileImageUrl!) // İnternetten yükle
                          : null,
                      child: _profileImageUrl == null 
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // ✅ Tıklayınca galeri açılacak
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                _buildTextField("Ad Soyad", _nameController, Icons.person_outline),
                const SizedBox(height: 15),
                _buildIncomeDropdown(),
                const SizedBox(height: 15),
                _buildTextField("Aylık Gelir (₺)", _incomeController, Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Profilimi Güncelle", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
    );
  }

  // textField ve dropdown yardımcı metotları aynı kalıyor...
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildIncomeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedIncomeGroup,
      decoration: InputDecoration(
        labelText: "Gelir Grubu", 
        prefixIcon: const Icon(Icons.trending_up, color: Colors.indigo),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      items: ["Düşük Gelir", "Orta Gelir", "Yüksek Gelir"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => setState(() => selectedIncomeGroup = val!),
    );
  }
}