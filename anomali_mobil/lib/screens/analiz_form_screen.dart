import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/jitt_popup.dart';
import '../../widgets/anomali_card.dart'; // 🆕 Yeni kart widget'ımızı ekledik
import 'gecmis_screen.dart';

class AnalizFormScreen extends StatefulWidget {
  const AnalizFormScreen({super.key});

  @override
  State<AnalizFormScreen> createState() => _AnalizFormScreenState();
}

class _AnalizFormScreenState extends State<AnalizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool yukleniyor = false;
  Map<String, dynamic>? sonuc;

  // Form Kontrolcüleri
  final TextEditingController _userIdController = TextEditingController(text: "1");
  final TextEditingController _amountController = TextEditingController(text: "100");

  String secilenKategori = "Fatura";
  final List<String> kategoriler = ["Fatura", "Gıda", "Eğlence", "Diğer", "Elektronik", "Giyim", "Market", "Restoran", "Seyahat"];

  // 🚀 ANALİZ YAPMA FONKSİYONU
  Future<void> analizYap() async {
    if (!_formKey.currentState!.validate()) return;
    if (yukleniyor) return; 

    setState(() {
      yukleniyor = true;
      sonuc = null; // Yeni analiz başlarken eski sonucu temizle
    });

    try {
      final data = await ApiService().predictRisk(
        userId: int.tryParse(_userIdController.text) ?? 1,
        age: 23, // Backend'de kullanılmadığı için sabit verdik
        income: 50000.0,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: secilenKategori,
        incomeGroup: "Orta",
      );

      setState(() {
        sonuc = data;
        yukleniyor = false;
      });

      // Eğer anomali tespiti varsa popup göster
      if (data["tahmin"] == "Anomali") {
        showAnimatedAnomalyPopup(context, data);
      }
    } catch (e) {
      setState(() => yukleniyor = false);
      
      // ⚠️ Gelişmiş Hata Mesajı Gösterimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Sunucu Hatası: ${e.toString()}"), // Hatayı tam metin olarak gösterir
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛡️ İşlem Analizi"), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GecmisScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🎨 Güzelleştirilmiş Sonuç Kartı
              if (sonuc != null) buildResultCard(sonuc!),
              
              const SizedBox(height: 10),
              
              _buildField(_userIdController, "Kullanıcı ID", Icons.person_outline),
              _buildField(_amountController, "Harcama Tutarı (TL)", Icons.monetization_on_outlined),
              
              const SizedBox(height: 15),
              _buildDropdown("Kategori Seçimi", kategoriler, secilenKategori, (v) => setState(() => secilenKategori = v!)),
              
              const SizedBox(height: 30),
              
              // 🔄 Loading Spinner veya Buton Kontrolü
              yukleniyor 
                ? const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 10),
                      Text("Yapay Zeka Analiz Ediyor...", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
                    ],
                  ) 
                : ElevatedButton.icon(
                    onPressed: analizYap,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text("ANALİZ ET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60), 
                      backgroundColor: Colors.indigo, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctr, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctr, 
        keyboardType: TextInputType.number, 
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: Colors.indigo), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Bu alan boş bırakılamaz" : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value, 
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: const Icon(Icons.category_outlined, color: Colors.indigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[50],
      ), 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
      onChanged: onChanged
    );
  }
}