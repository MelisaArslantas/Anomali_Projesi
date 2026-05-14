import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/jitt_popup.dart';
import '../../widgets/anomali_card.dart';
import 'gecmis_screen.dart';

class AnalizFormScreen extends StatefulWidget {
  const AnalizFormScreen({super.key});

  @override
  State<AnalizFormScreen> createState() => _AnalizFormScreenState();
}

class _AnalizFormScreenState extends State<AnalizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool yukleniyor = false;
  Map<String, dynamic>? sonuc;

  final TextEditingController _amountController = TextEditingController();

  // ✅ KATEGORİLER: Maaş ve Gelir en başa eklendi (Dashboard ile tam uyum)
  String secilenKategori = "Gıda & Market";
  final List<String> kategoriler = [
    'Maaş', 
    'Gelir',
    'Gıda & Market',
    'Kira & Konut',
    'Fatura & Aidat',
    'Ulaşım & Akaryakıt',
    'Dışarıda Yemek',
    'Eğitim & Gelişim',
    'Teknoloji & Elektronik',
    'Sağlık & Bakım',
    'Giyim & Aksesuar',
    'Eğlence & Hobiler',
    'Borç & Taksit',
    'Diğer'
  ];

  Future<void> analizYap() async {
    if (!_formKey.currentState!.validate()) return;
    if (yukleniyor) return;

    setState(() {
      yukleniyor = true;
      sonuc = null;
    });

    try {
      final userData = await _authService.getUserData();
      if (userData == null || !userData.exists) throw "Kullanıcı verisi bulunamadı";

      double userIncome = (userData['monthly_income'] as num).toDouble();
      String userIncomeGroup = userData['income_group'];
      String realUid = userData['uid'];

      // 💡 MANTIK: Eğer seçilen kategori "Maaş" ise anomali analizi yerine doğrudan kaydetme yapılabilir.
      // Ancak senin backend (FastAPI) tüm işlemleri predictRisk üzerinden kaydediyorsa devam ediyoruz:
      
      final data = await ApiService().predictRisk(
        userId: realUid,
        age: 23, 
        income: userIncome, 
        amount: double.tryParse(_amountController.text) ?? 0.0,
        category: secilenKategori,
        incomeGroup: userIncomeGroup, 
      );

      setState(() {
        sonuc = data;
        yukleniyor = false;
      });

      // ✅ Maaş/Gelir girişlerinde tebrik mesajı, harcamalarda anomali kontrolü
      if (secilenKategori == "Maaş" || secilenKategori == "Gelir") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("💰 Gelir girişi başarıyla kaydedildi! Bütçeniz güncellendi."),
            backgroundColor: Colors.green,
          ),
        );
      } else if (data["tahmin"] == "Anomali") {
        showAnimatedAnomalyPopup(context, data);
      }
      
    } catch (e) {
      setState(() => yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Hata: ${e.toString()}"), backgroundColor: Colors.redAccent),
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
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const GecmisScreen())
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (sonuc != null) AnomaliCard(data: sonuc!),
              
              const SizedBox(height: 10),
              
              // Tutar Girişi (Maaş ise "Gelir Tutarı" yazması daha şık olur)
              _buildField(
                _amountController, 
                (secilenKategori == "Maaş" || secilenKategori == "Gelir") ? "Gelir Tutarı (TL)" : "Harcama Tutarı (TL)", 
                Icons.monetization_on_outlined
              ),
              
              const SizedBox(height: 15),
              
              _buildDropdown("İşlem Kategorisi", kategoriler, secilenKategori, 
                (v) => setState(() => secilenKategori = v!)),
              
              const SizedBox(height: 30),
              
              yukleniyor 
                ? const CircularProgressIndicator(color: Colors.indigo)
                : ElevatedButton.icon(
                    onPressed: analizYap,
                    icon: Icon((secilenKategori == "Maaş" || secilenKategori == "Gelir") ? Icons.save_as : Icons.analytics_outlined),
                    label: Text(
                      (secilenKategori == "Maaş" || secilenKategori == "Gelir") ? "GELİRİ KAYDET" : "ANALİZ ET", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: (secilenKategori == "Maaş" || secilenKategori == "Gelir") ? Colors.green[700] : Colors.indigo,
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
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? "Bu alan boş bırakılamaz" : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.category_outlined, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged);
  }
}