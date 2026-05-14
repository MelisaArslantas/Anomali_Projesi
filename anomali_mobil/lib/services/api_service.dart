import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analiz_modeli.dart';

class ApiService {
  // Emülatör için standart IP. Gerçek cihazda kendi IP'ni yazmalısın.
  static const String _baseUrl = "http://10.0.2.2:8000";

  // 🆕 CollectAPI Bilgileri
  static const String _collectApiKey = "7ulkf3NdU7ins4koAIBkJ2:0nzEKCTFtiZZRTVKwbtZOW"; 
  static const String _collectApiBaseUrl = "https://api.collectapi.com/economy";

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

  /// 5️⃣ Dashboard İstatistiklerini Getirme Metodu
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

  /// 6️⃣ 🆕 GÜNCELLENMİŞ CANLI VERİ METODU: Sayı hatası giderildi.
  Future<Map<String, double>> getLivePrices() async {
    final currencyUrl = Uri.parse("$_collectApiBaseUrl/allCurrency");
    final goldUrl = Uri.parse("$_collectApiBaseUrl/goldPrice");
    
    Map<String, double> prices = {
      "Dolar": 45.30, 
      "Euro": 52.93, 
      "Gram Altın": 6920.0,
      "Çeyrek Altın": 11350.0
    };

    try {
      final headers = {
        'content-type': 'application/json',
        'authorization': 'apikey $_collectApiKey'
      };

      final currRes = await http.get(currencyUrl, headers: headers);
      if (currRes.statusCode == 200) {
        final data = jsonDecode(currRes.body);
        final List results = data['result'] ?? [];
        
        for (var key in ["Dolar", "Euro"]) {
          String searchKey = key == "Dolar" ? "USD" : "EUR";
          var found = results.firstWhere((e) => e['name'].toString().contains(searchKey), orElse: () => null);
          if (found != null) {
            prices[key] = _parsePrice(found['buying'].toString(), prices[key]!);
          }
        }
      }

      final goldRes = await http.get(goldUrl, headers: headers);
      if (goldRes.statusCode == 200) {
        final data = jsonDecode(goldRes.body);
        final List results = data['result'] ?? [];
        
        for (var key in ["Gram Altın", "Çeyrek Altın"]) {
          String searchKey = key.split(' ')[0]; // "Gram" veya "Çeyrek"
          var found = results.firstWhere((e) => e['name'].toString().contains(searchKey), orElse: () => null);
          if (found != null) {
            prices[key] = _parsePrice(found['buying'].toString(), prices[key]!);
          }
        }
      }
      return prices;
    } catch (e) {
      print("❌ Canlı ekonomi verisi çekilemedi: $e");
      return prices;
    }
  }

  /// 🔥 Sayıyı Güvenli Şekilde Double'a Çeviren Yardımcı Metot
  double _parsePrice(String rawValue, double fallback) {
    try {
      // 1. Durum: Hem nokta hem virgül varsa (Örn: 1.234,56)
      if (rawValue.contains('.') && rawValue.contains(',')) {
        return double.tryParse(rawValue.replaceAll('.', '').replaceAll(',', '.')) ?? fallback;
      } 
      // 2. Durum: Sadece virgül varsa (Örn: 6859,19)
      else if (rawValue.contains(',')) {
        return double.tryParse(rawValue.replaceAll(',', '.')) ?? fallback;
      } 
      // 3. Durum: Sadece nokta varsa veya temizse (Örn: 6859.19)
      else {
        return double.tryParse(rawValue) ?? fallback;
      }
    } catch (e) {
      return fallback;
    }
  }
}