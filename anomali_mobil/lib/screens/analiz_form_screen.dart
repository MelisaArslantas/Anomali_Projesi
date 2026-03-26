import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/jitt_popup.dart';
import 'gecmis_screen.dart'; // 👈 Geçmiş ekranını import ettik

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
  final TextEditingController _ageController = TextEditingController(text: "23");
  final TextEditingController _incomeController = TextEditingController(text: "50000");
  final TextEditingController _amountController = TextEditingController(text: "100");

  String secilenKategori = "Fatura";
  final List<String> kategoriler = ["Fatura", "Gıda", "Eğlence", "Diğer", "Elektronik", "Giyim", "Market", "Restoran", "Seyahat"];

  String secilenGelirGrubu = "Orta";
  final List<String> gelirGruplari = ["Düşük", "Orta", "Yüksek", "Çok Yüksek"];

  // 🎨 Risk Seviyesine Göre Renk Döndüren Fonksiyon
  Color getRiskColor(String risk) {
    if (risk == "Yüksek") return Colors.red;
    if (risk == "Orta") return Colors.orange;
    return Colors.green;
  }

  Future<void> analizYap() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => yukleniyor = true);

    try {
      final data = await ApiService().predictRisk(
        userId: int.parse(_userIdController.text),
        age: int.parse(_ageController.text),
        income: double.parse(_incomeController.text),
        amount: double.parse(_amountController.text),
        category: secilenKategori,
        incomeGroup: secilenGelirGrubu,
      );

      setState(() {
        sonuc = data;
        yukleniyor = false;
      });

      // 🔥 Anomali Durumunda Popup Göster
      if (data["tahmin"] == "Anomali") {
        showAnimatedAnomalyPopup(context, data);
      }
    } catch (e) {
      setState(() => yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
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
          // 🕒 Sağ Üst Köşeye Geçmiş Butonu
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: "İşlem Geçmişi",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const GecmisScreen())
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📊 Analiz Sonucu Varsa En Üstte Görsel Kart Olarak Göster
              if (sonuc != null) _buildResultCard(sonuc!),
              
              const SizedBox(height: 20),
              _buildField(_userIdController, "Kullanıcı ID", Icons.person),
              _buildField(_ageController, "Yaş", Icons.cake),
              _buildField(_incomeController, "Aylık Gelir", Icons.payments),
              _buildField(_amountController, "Harcama Tutarı", Icons.shopping_bag),
              const SizedBox(height: 15),
              _buildDropdown("Kategori", kategoriler, secilenKategori, (v) => setState(() => secilenKategori = v!)),
              const SizedBox(height: 15),
              _buildDropdown("Gelir Grubu", gelirGruplari, secilenGelirGrubu, (v) => setState(() => secilenGelirGrubu = v!)),
              const SizedBox(height: 30),
              
              yukleniyor 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: analizYap,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55), 
                      backgroundColor: Colors.indigo, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("ANALİZ ET", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // 💎 Gelişmiş Sonuç Kartı (Risk Bar İçerir)
  Widget _buildResultCard(Map<String, dynamic> data) {
    final String risk = data['risk'] ?? "Düşük";
    final double skor = (data['risk_skoru'] ?? 0.0).toDouble();
    final Color anaRenk = getRiskColor(risk);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("ANALİZ RAPORU", style: TextStyle(color: Colors.grey[600], letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              risk.toUpperCase(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: anaRenk),
            ),
            const SizedBox(height: 15),
            
            // 📈 Risk Bar (Progress Bar)
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: LinearProgressIndicator(
                    value: skor / 100,
                    minHeight: 20,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(anaRenk),
                  ),
                ),
                Text("%$skor", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            
            // 📝 Sistem Açıklama Kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: anaRenk.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: anaRenk.withOpacity(0.3)),
              ),
              child: Text(
                data['aciklama'] ?? "İşlem başarıyla analiz edildi.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
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
          prefixIcon: Icon(icon), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        )
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value, 
      decoration: InputDecoration(
        labelText: label, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
      ), 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
      onChanged: onChanged
    );
  }
}