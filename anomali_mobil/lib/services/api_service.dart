import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analiz_modeli.dart'; // Model dosyanı import ettiğinden emin ol

class ApiService {
  // Emülatör için 10.0.2.2, fiziksel cihaz için bilgisayarın yerel IP'si
  static const String _baseUrl = "http://10.0.2.2:8000";

  // 🧪 TAHMİN: Yeni harcama analizi gönder
  Future<Map<String, dynamic>> predictRisk({
    required int userId,
    required int age,
    required double income,
    required double amount,
    required String category,
    required String incomeGroup,
  }) async {
    final url = Uri.parse("$_baseUrl/predict");

    final requestData = {
      "kullanici_id": userId,
      "harcama_tutari": amount,
      "kategori": category,
      "yas": age,
      "aylik_gelir": income,
      "gelir_grubu": incomeGroup,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Sunucu hatası: ${response.statusCode}", "success": false};
      }
    } on SocketException {
      return {"error": "Sunucuya ulaşılamıyor. Lütfen backend'in açık olduğunu kontrol edin.", "success": false};
    } catch (e) {
      return {"error": "Hata: $e", "success": false};
    }
  }

  // 📜 LİSTELEME: Geçmiş verileri çek ve Model'e dönüştür
  Future<List<AnalizModeli>> getHistory() async {
    final url = Uri.parse("$_baseUrl/history");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        // JSON listesini AnalizModeli listesine çeviriyoruz (Mapping)
        return rawData.map((json) => AnalizModeli.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Geçmiş çekme hatası: $e");
      return [];
    }
  }

  // 🗑️ TEMİZLEME: Tüm geçmişi sil
  Future<bool> clearHistory() async {
    final url = Uri.parse("$_baseUrl/clear-history");
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Geçmiş silme hatası: $e");
      return false;
    }
  }
}