import 'package:flutter/material.dart';
import 'risk_bar.dart';

Widget buildResultCard(Map<String, dynamic> data) {
  // 1. Verileri Hazırlayalım
  final String tahmin = (data["tahmin"] ?? "").toString().toLowerCase();
  final double riskSkoru = (data["risk_skoru"] ?? 0.0).toDouble();
  final bool isAnomaly = tahmin.contains("anomali") || tahmin.contains("kritik");
  
  Color mainColor;
  Color lightColor;

  // 2. Risk Rengine Göre UI Belirleme (Düşük, Orta, Yüksek)
  if (riskSkoru >= 70 || isAnomaly) {
    mainColor = Colors.red; // Yüksek / Kritik
    lightColor = Colors.red.shade50;
  } else if (riskSkoru >= 30) {
    mainColor = Colors.orange; // Orta
    lightColor = Colors.orange.shade50;
  } else {
    mainColor = Colors.green; // Düşük
    lightColor = Colors.green.shade50;
  }

  return Card(
    elevation: 5,
    margin: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias, // Kenar şeridi için gerekli
    child: Container(
      // Kartın soluna renkli bir şerit ekleyerek görseli güçlendiriyoruz
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: mainColor, width: 8)),
        color: lightColor,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ANALİZ SONUCU",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainColor.withOpacity(0.7)),
                  ),
                  Text(
                    data["tahmin"] ?? "Bilinmiyor",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: mainColor),
                  ),
                ],
              ),
              Icon(
                isAnomaly ? Icons.gpp_bad_rounded : Icons.verified_user_rounded, 
                color: mainColor,
                size: 45
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Risk Bar Widget'ı
          RiskBar(skor: riskSkoru),
          
          const SizedBox(height: 20),
          
          // Açıklama Kutusu
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: mainColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data["analiz_notu"] ?? data["aciklama"] ?? "İşlem başarıyla analiz edildi.",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}