import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
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
    final requestData = {
      "User_ID": userId,
      "Age": age,
      "Income": income,
      "Amount": amount,
      "kategori": category,
      "gelir_grubu": incomeGroup
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return {"error": "Sunucu hatası"};
    } on SocketException {
      return {"error": "Sunucuya ulaşılamıyor"};
    } catch (e) {
      return {"error": "Hata: $e"};
    }
  }

  Future<List<dynamic>> getHistory() async {
    final url = Uri.parse("$_baseUrl/history");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } on SocketException {
      return [];
    } catch (e) {
      return [];
    }
  }
}