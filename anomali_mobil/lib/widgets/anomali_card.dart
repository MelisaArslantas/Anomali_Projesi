import 'package:flutter/material.dart';
import 'risk_bar.dart'; // RiskBar'ın aynı klasörde olduğunu varsayıyorum

Widget buildResultCard(Map<String, dynamic> data) {
  // 1. Tahmine göre ana renkleri belirleyelim
  // API'den "tahmin" anahtarı ile "Anomali" gelip gelmediğini kontrol ediyoruz
  final bool isAnomaly = data["tahmin"] == "Anomali";
  
  // Risk skoruna göre daha hassas renk kontrolü (Görsel uyum için)
  final double riskSkoru = (data["risk_skoru"] ?? 0.0).toDouble();
  
  Color mainColor;
  Color cardBgColor;

  if (isAnomaly || riskSkoru >= 70) {
    mainColor = Colors.red;
    cardBgColor = Colors.red.shade50;
  } else if (riskSkoru >= 40) {
    mainColor = Colors.orange;
    cardBgColor = Colors.orange.shade50;
  } else {
    mainColor = Colors.green;
    cardBgColor = Colors.green.shade50;
  }

  return Card(
    elevation: 4,
    color: cardBgColor, 
    margin: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: mainColor.withOpacity(0.3), width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["tahmin"] ?? "Bilinmiyor",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: mainColor
                ),
              ),
              Icon(
                isAnomaly ? Icons.report_problem_rounded : Icons.check_circle_rounded, 
                color: mainColor,
                size: 30
              ),
            ],
          ),
          const Divider(height: 30),
          
          // 2. Risk Bar (Senin widget'ın)
          RiskBar(skor: riskSkoru),
          
          const SizedBox(height: 20),
          
          // Analiz notu kutusu
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              data["analiz_notu"] ?? (isAnomaly ? "Şüpheli işlem saptandı." : "İşlem normal davranış aralığında."),
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    ),
  );
}