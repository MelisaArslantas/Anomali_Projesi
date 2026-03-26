import 'package:flutter/material.dart';

// 1️⃣ Risk Skoruna göre renk döndüren fonksiyon
Color getRiskColor(double skor) {
  if (skor > 70) return Colors.red;
  if (skor > 40) return Colors.orange;
  return Colors.green;
}

void showAnimatedAnomalyPopup(BuildContext context, Map<String, dynamic> data) {
  final double skor = (data['risk_skoru'] ?? 0.0).toDouble();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    // 2️⃣ Arka planı daha dramatik karartıyoruz (Blur etkisi hissi için)
    barrierColor: Colors.black.withOpacity(0.7), 
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) => const SizedBox(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Column(
              children: [
                Icon(Icons.report_problem_rounded, color: Colors.red, size: 70),
                SizedBox(height: 10),
                Text("KRİTİK ANALİZ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Sıra dışı bir işlem saptandı!", textAlign: TextAlign.center),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: getRiskColor(skor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: getRiskColor(skor).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // 1️⃣ Dinamik Renklendirme Burada
                      Text(
                        "Risk Skoru: %$skor",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: getRiskColor(skor)),
                      ),
                      const SizedBox(height: 8),
                      Text(data['analiz_notu'] ?? "", textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("KONTROL EDECEĞİM", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}