import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 🟡 UX İÇİN (Opsiyonel)
  final _nameController = TextEditingController();

  // ✅ ZORUNLU
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ✅ ANALİZ İÇİN GEREKLİ
  final _incomeController = TextEditingController();
  String? _selectedIncomeGroup;
  final List<String> _incomeGroups = ['Düşük Gelir', 'Orta Gelir', 'Yüksek Gelir'];

  final AuthService _authService = AuthService();

  void _handleRegister() async {
    // Zorunlu alan ve dropdown seçimi kontrolü
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _selectedIncomeGroup == null || 
        _incomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen yıldızlı (*) alanları doldurun!")),
      );
      return;
    }

    // Firebase kayıt işlemi
    String? result = await _authService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(), // Boşsa AuthService "Kullanıcı" atar
      monthlyIncome: double.tryParse(_incomeController.text) ?? 0.0,
      incomeGroup: _selectedIncomeGroup!,
    );

    if (result == "success") {
      // Kayıt başarılı; dökümandaki ana ekrana yönlendirilir
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Hata mesajını kullanıcıya göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $result")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo),
        title: const Text("Kayıt Ol", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add_rounded, size: 80, color: Colors.indigo),
            const SizedBox(height: 30),
            
            // 🟡 UX İÇİN (Opsiyonel Katman)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "İsim (Opsiyonel)",
                prefixIcon: const Icon(Icons.person_outline, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ ZORUNLU (Kimlik Katmanı)
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email *",
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre *",
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ ANALİZ İÇİN (Finansal Veri Katmanı)
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Aylık Gelir *",
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Gelir Grubu *", // Görseldeki hata burada düzeltildi
                prefixIcon: const Icon(Icons.bar_chart_rounded, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: _selectedIncomeGroup,
              items: _incomeGroups.map((group) => DropdownMenuItem(
                value: group, 
                child: Text(group)
              )).toList(),
              onChanged: (val) => setState(() => _selectedIncomeGroup = val),
            ),

            const SizedBox(height: 30),

            // KAYIT BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}