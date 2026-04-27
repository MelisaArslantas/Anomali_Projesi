import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analiz_modeli.dart';

class ApiService {
  static const String _baseUrl = "http://10.0.2.2:8000";

  // ✅ BU METOT EKSİK OLDUĞU İÇİN HATA ALIYORSUN
  Future<bool> register(String email, String password, double income, String expenseType) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'income': income,
          'expense_type': expenseType,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Kayıt hatası: $e");
      return false;
    }
  }

  // Tahmin metodu
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
      return response.statusCode == 200 ? jsonDecode(response.body) : {"success": false};
    } catch (e) {
      return {"success": false};
    }
  }

  Future<List<AnalizModeli>> getHistory() async {
    final url = Uri.parse("$_baseUrl/history");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        return List<AnalizModeli>.from(rawData.map((x) => AnalizModeli.fromJson(x)));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}