import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/jitt_popup.dart';
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
  final TextEditingController _ageController = TextEditingController(text: "23");
  final TextEditingController _incomeController = TextEditingController(text: "50000");
  final TextEditingController _amountController = TextEditingController(text: "100");

  String secilenKategori = "Fatura";
  final List<String> kategoriler = ["Fatura", "Gıda", "Eğlence", "Diğer", "Elektronik", "Giyim", "Market", "Restoran", "Seyahat"];

  String secilenGelirGrubu = "Orta";
  final List<String> gelirGruplari = ["Düşük", "Orta", "Yüksek", "Çok Yüksek"];

  // 🎨 Risk Seviyesine Göre Renk Döndüren Akıllı Fonksiyon
  Color getRiskColor(Map<String, dynamic> data) {
    // Backend'den gelen tüm olası etiketleri kontrol et
    String seviye = (data['risk_seviyesi'] ?? data['risk'] ?? "").toString().toLowerCase();
    String tahmin = (data["tahmin"] ?? "").toString().toLowerCase();
    double skor = (data["risk_skoru"] ?? 0.0).toDouble();

    // 1. Önce "Anomali" veya "Kritik" durumuna bak (En öncelikli)
    if (tahmin.contains("anomali") || seviye.contains("kritik")) {
      return Colors.red;
    }

    // 2. Metin bazlı kontrol (Yüksek, Orta, Düşük)
    if (seviye.contains("yüksek")) return Colors.red;
    if (seviye.contains("orta")) return Colors.orange;
    if (seviye.contains("düşük")) return Colors.green;

    // 3. Fallback: Eğer metin bulunamazsa skora göre belirle
    if (skor >= 75) return Colors.red;
    if (skor >= 40) return Colors.orange;
    return Colors.green;
  }

  Future<void> analizYap() async {
    if (!_formKey.currentState!.validate()) return;
    if (yukleniyor) return; 

    setState(() => yukleniyor = true);

    try {
      final data = await ApiService().predictRisk(
        userId: int.tryParse(_userIdController.text) ?? 1,
        age: int.tryParse(_ageController.text) ?? 0,
        income: double.tryParse(_incomeController.text) ?? 0.0,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: secilenKategori,
        incomeGroup: secilenGelirGrubu,
      );

      setState(() {
        sonuc = data;
        yukleniyor = false;
        // Debug için terminale yazdıralım (Hata olursa buradan görürüz)
        print("API YANITI: $data");
      });

      if (data["tahmin"] == "Anomali") {
        showAnimatedAnomalyPopup(context, data);
      }
    } catch (e) {
      setState(() => yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Sunucu bağlantı hatası!"),
          backgroundColor: Colors.redAccent,
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
                ? const CircularProgressIndicator(color: Colors.indigo) 
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

  Widget _buildResultCard(Map<String, dynamic> data) {
    // 🔥 ÖNEMLİ: Etiketi doğru anahtardan çekiyoruz
    final String riskEtiketi = data['risk_seviyesi'] ?? data['risk'] ?? "Normal";
    final double skor = (data['risk_skoru'] ?? 0.0).toDouble();
    final Color anaRenk = getRiskColor(data); 

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("ANALİZ RAPORU", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Text(
              riskEtiketi.toUpperCase(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: anaRenk),
            ),
            const SizedBox(height: 15),
            
            // Risk Çubuğu
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: skor / 100,
                    minHeight: 22,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(anaRenk),
                  ),
                ),
                Text("%${skor.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 15),
            
            // Açıklama Notu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: anaRenk.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: anaRenk.withOpacity(0.2)),
              ),
              child: Text(
                data['analiz_notu'] ?? data['aciklama'] ?? "İşlem başarıyla analiz edildi.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctr, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctr, 
        keyboardType: TextInputType.number, 
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo)),
          filled: true,
          fillColor: Colors.grey[50],
        )
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value, 
      decoration: InputDecoration(
        labelText: label, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ), 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
      onChanged: onChanged
    );
  }
}