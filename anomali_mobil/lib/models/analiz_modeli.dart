class AnalizModeli {
  final String tahmin;
  final String riskSeviyesi;
  final double riskSkoru;
  final String aciklama;

  AnalizModeli({
    required this.tahmin,
    required this.riskSeviyesi,
    required this.riskSkoru,
    required this.aciklama,
  });

  factory AnalizModeli.fromJson(Map<String, dynamic> json) {
    return AnalizModeli(
      tahmin: json['tahmin'] ?? "Bilinmiyor",
      riskSeviyesi: json['risk_seviyesi'] ?? "Düşük",
      riskSkoru: (json['risk_skoru'] ?? 0.0).toDouble(),
      aciklama: json['analiz_notu'] ?? "İşlem normal görünüyor.",
    );
  }
}