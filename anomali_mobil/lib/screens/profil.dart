import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilScreen extends StatefulWidget {
  // Dashboard'dan gelen maili almak için bu değişkeni ekliyoruz
  final String userEmail;

  // Yapıcı metot (Constructor) artık userEmail parametresini bekliyor
  const ProfilScreen({super.key, required this.userEmail});

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gelirController = TextEditingController();
  
  String gelirGrubu = "Orta Gelir"; 
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    // Örnek bir başlangıç değeri
    _gelirController.text = "15000"; 
  }

  Future<void> _gelirGuncelle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _yukleniyor = true);
      
      // Simülasyon: Burada ApiService çağrısı yapılabilir
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _yukleniyor = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gelir bilgisi başarıyla güncellendi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Bilgileri"),
        centerTitle: true,
        backgroundColor: Colors.indigo, // Dashboard ile uyumlu olması için
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Klavye açıldığında taşma hatası olmaması için
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              
              const Text("E-posta Adresi", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                // widget.userEmail diyerek üst sınıftan gelen veriyi kullanıyoruz
                initialValue: widget.userEmail,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Gelir Grubu", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Text(
                  gelirGrubu,
                  style: TextStyle(fontSize: 16, color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Aylık Gelir (₺)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gelirController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Gelirinizi giriniz",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Lütfen bir miktar giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _gelirGuncelle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _yukleniyor 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Profilimi Güncelle", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}