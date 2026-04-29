import 'package:flutter/material.dart';
import 'quiz_screen.dart'; // Quiz ekranını açabilmek için import edildi

class JittPage extends StatelessWidget {
  const JittPage({super.key});

  // Tasarımda kullanılan özel renk tanımlamaları
  static const Color emerald = Color(0xFF10B981);
  static const Color whiteCC = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Gelişim Merkezi",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // 1. JiTT Aksiyon Kartı: Anomali durumunda tetiklenen mikro-eğitim alanı
              _buildAnomaliAlertCard(context),
              
              const SizedBox(height: 30),
              
              // 2. Oyunlaştırma Paneli: Puan ve Seviye takibi
              _buildStatsRow(),
              
              const SizedBox(height: 30),
              
              const Text(
                "Öğrenme Modülleri",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1E293B)
                ),
              ),
              const SizedBox(height: 15),
              
              // 3. Eğitim Kütüphanesi: Belgendeki senaryolara uygun içerikler[cite: 2]
              _buildEducationTile(
                title: "Dürtüsel Harcama Kontrolü",
                desc: "Harcama anında karar verme teknikleri.",
                icon: Icons.flash_on_rounded,
                color: Colors.orange,
                xp: "+20 XP",
              ),
              _buildEducationTile(
                title: "Akıllı Birikim Stratejileri",
                desc: "Küçük miktarlarla büyük hedefler.",
                icon: Icons.account_balance_wallet_rounded,
                color: emerald,
                xp: "+15 XP",
              ),
              _buildEducationTile(
                title: "Elektronik Bütçe Yönetimi",
                desc: "Teknoloji harcamalarında tasarruf.",
                icon: Icons.devices_other_rounded,
                color: Colors.blue,
                xp: "+25 XP",
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Anomali saptandığında kullanıcıyı Just-in-Time öğrenmeye yönlendiren kart[cite: 2, 3]
  Widget _buildAnomaliAlertCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text(
                "Anomali Saptandı!",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Elektronik harcamalarınız bu ay alışılmışın dışında. Bu durumu bir fırsata çevirelim mi?",
            style: TextStyle(color: whiteCC, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Quiz ekranına geçiş yaparak JiTT metodolojisini tamamlar[cite: 2]
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
            child: const Text(
              "Mikro-Eğitime Başla", 
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("Okuryazarlık", "Seviye 3", Icons.auto_stories, Colors.blue),
        _buildStatItem("Toplam Puan", "450 XP", Icons.stars_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEducationTile({
    required String title, 
    required String desc, 
    required IconData icon, 
    required Color color, 
    required String xp
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(xp, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}