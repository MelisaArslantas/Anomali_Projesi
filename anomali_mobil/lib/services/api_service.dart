import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Emülatör kullandığın için 10.0.2.2 adresi doğrudur.
  static const String _baseUrl = "http://10.0.2.2:8000";

  Future<Map<String, dynamic>> predictRisk({
    required int userId,
    required int age,
    required double income,
    required double amount,
    required String category,
    required String incomeGroup,
  }) async {
    final url = Uri.parse("$_baseUrl/predict");

    // 🔥 KRİTİK: Değişken isimlerini Python (main.py) ile birebir eşitledik.
    // Python tarafı bu anahtarları (key) bekliyor.
    final requestData = {
      "kullanici_id": userId,
      "harcama_tutari": amount,
      "kategori": category,
      "yas": age,
      "aylik_gelir": income,
      "gelir_grubu": incomeGroup,
      "amount": amount, // Yedek olarak tutuyoruz
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
        return {"error": "Sunucu hatası: ${response.statusCode}"};
      }
    } on SocketException {
      return {"error": "Sunucuya ulaşılamıyor. Lütfen backend'in çalıştığından emin olun."};
    } catch (e) {
      return {"error": "Beklenmedik bir hata oluştu: $e"};
    }
  }
  Future<bool> clearHistory() async {
  final url = Uri.parse("$_baseUrl/clear-history");
  try {
    final response = await http.delete(url).timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

  Future<List<dynamic>> getHistory() async {
    final url = Uri.parse("$_baseUrl/history");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        // Backend artık listeyi direkt döndürüyor.
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Geçmiş çekme hatası: $e");
      return [];
    }
  }
}