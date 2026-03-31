class AnalizModeli {
  final String tahmin;
  final String riskSeviyesi;
  final double riskSkoru;
  final String aciklama;
  final String kategori; // 🆕 Filtreleme için eklendi
  final String tarih;    // 🆕 Sıralama için eklendi
  final double miktar;   // 🆕 Kart tasarımı için eklendi

  AnalizModeli({
    required this.tahmin,
    required this.riskSeviyesi,
    required this.riskSkoru,
    required this.aciklama,
    required this.kategori,
    required this.tarih,
    required this.miktar,
  });

  // JSON'dan nesneye dönüştürme (Mapping)
  factory AnalizModeli.fromJson(Map<String, dynamic> json) {
    return AnalizModeli(
      tahmin: json['tahmin'] ?? "Normal",
      riskSeviyesi: json['risk_seviyesi'] ?? "Düşük",
      // Risk skoru bazen int bazen double gelebilir, güvenli dönüşüm:
      riskSkoru: double.tryParse(json['risk_skoru'].toString()) ?? 0.0,
      aciklama: json['analiz_notu'] ?? "İşlem normal görünüyor.",
      kategori: json['kategori'] ?? "Diğer",
      tarih: json['tarih'] ?? "",
      miktar: double.tryParse(json['harcama_tutari'].toString()) ?? 0.0,
    );
  }

  // API'ye veri göndermek gerekirse (opsiyonel)
  Map<String, dynamic> toJson() {
    return {
      'tahmin': tahmin,
      'risk_seviyesi': riskSeviyesi,
      'risk_skoru': riskSkoru,
      'analiz_notu': aciklama,
      'kategori': kategori,
      'tarih': tarih,
      'harcama_tutari': miktar,
    };
  }
}