import 'package:flutter/material.dart';
import 'analiz_form_screen.dart';
import 'gecmis_screen.dart';
import 'profil.dart';
import 'jitt.dart';

class DashboardScreen extends StatefulWidget { // StatefulWidget'a çevirdik
  final String userEmail;

  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Rozetin görünüp görünmeyeceğini kontrol eden değişken
  bool hasNotification = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finansal Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilScreen(userEmail: widget.userEmail),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context), 
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoşgeldin,",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            Text(
              widget.userEmail,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 30),

            // Özet Kartları
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildSummaryCard("Aylık Gelir", "₺15,000", Icons.account_balance_wallet, Colors.green),
                _buildSummaryCard("İşlem Sayısı", "24", Icons.list_alt, Colors.blue),
                _buildSummaryCard("Ort. Risk", "%12", Icons.warning_amber_rounded, Colors.orange),
                _buildSummaryCard("Durum", "Güvenli", Icons.check_circle_outline, Colors.teal),
              ],
            ),
            const SizedBox(height: 35),

            const Text(
              "Gelişim Fırsatları",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildActionButton(
                  context, 
                  "Finansal Gelişim Merkezi (JiTT)", 
                  Icons.auto_awesome, 
                  Colors.purple.shade700,
                  () {
                    // Sayfaya girerken bildirimi kapatıyoruz
                    setState(() {
                      hasNotification = false;
                    });
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const JittPage())
                    );
                  }
                ),
                // hasNotification true ise rozeti göster
                if (hasNotification)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "1",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 35),
            const Text(
              "Hızlı İşlemler",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            _buildActionButton(
              context, 
              "Yeni Analiz Yap", 
              Icons.analytics_outlined, 
              Colors.indigo,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalizFormScreen()))
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context, 
              "İşlem Geçmişi", 
              Icons.history, 
              const Color(0xFF5C6BC0),
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GecmisScreen()))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}