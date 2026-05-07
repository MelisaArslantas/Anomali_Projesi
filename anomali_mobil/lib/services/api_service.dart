import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analiz_modeli.dart';

class ApiService {
  // Emülatör için standart IP. Gerçek cihazda kendi IP'ni yazmalısın.
  static const String _baseUrl = "http://10.0.2.2:8000";

  /// 1️⃣ Yeni kullanıcı kaydı
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
      print("❌ Kayıt hatası: $e");
      return false;
    }
  }

  /// 2️⃣ Anomali Tespiti ve Risk Analizi Metodu
  Future<Map<String, dynamic>> predictRisk({
    required dynamic userId,
    required int age,
    required double income,
    required double amount,
    required String category,
    required String incomeGroup,
  }) async {
    final url = Uri.parse("$_baseUrl/predict");
    final requestData = {
      "userId": userId,
      "amount": amount,
      "category": category,
      "age": age,
      "income": income,
      "incomeGroup": incomeGroup,
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
        return {"success": false, "error": "Sunucu hatası"};
      }
    } catch (e) {
      return {"success": false, "error": "Bağlantı hatası"};
    }
  }

  /// 3️⃣ Harcama Geçmişini Getirme Metodu (UID ile)
  Future<List<AnalizModeli>> getHistory(String userId) async {
    final url = Uri.parse("$_baseUrl/history/$userId");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        return List<AnalizModeli>.from(rawData.map((x) => AnalizModeli.fromJson(x)));
      }
      return [];
    } catch (e) {
      print("❌ Geçmiş verileri çekilemedi: $e");
      return [];
    }
  }

  /// 4️⃣ İşlem Silme Metodu
  Future<bool> deleteTransaction(String userId, String date) async {
    final url = Uri.parse("$_baseUrl/delete-transaction/$userId/$date");
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        print("🗑️ İşlem başarıyla silindi.");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Silme hatası: $e");
      return false;
    }
  }

  /// 5️⃣ 🆕 Dashboard İstatistiklerini Getirme Metodu
  // Backend'deki @app.get("/stats/{u_id}") kısmına bağlanır.
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final url = Uri.parse("$_baseUrl/stats/$userId");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("⚠️ Stats Sunucu Hatası: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("❌ İstatistikler çekilemedi: $e");
      return {};
    }
  }
}