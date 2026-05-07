class AnalizModeli {
  final String tarih;
  final String kullaniciId;
  final String kategori;
  final double harcamaTutari; // ✅ İsmi tam olarak bu yaptık
  final String riskSeviyesi;
  final double riskSkoru;
  final String tahmin;

  AnalizModeli({
    required this.tarih,
    required this.kullaniciId,
    required this.kategori,
    required this.harcamaTutari,
    required this.riskSeviyesi,
    required this.riskSkoru,
    required this.tahmin,
  });

  // JSON'dan modele dönüştürme (Backend'deki isimlerle eşleşmeli)
  factory AnalizModeli.fromJson(Map<String, dynamic> json) {
    return AnalizModeli(
      tarih: json['tarih'] ?? '',
      kullaniciId: json['kullanici_id']?.toString() ?? '',
      kategori: json['kategori'] ?? 'Diğer',
      harcamaTutari: (json['harcama_tutari'] as num?)?.toDouble() ?? 0.0, // ✅ Burası kritik
      riskSeviyesi: json['risk_seviyesi'] ?? 'Düşük',
      riskSkoru: (json['risk_skoru'] as num?)?.toDouble() ?? 0.0,
      tahmin: json['tahmin'] ?? 'Normal',
    );
  }
}