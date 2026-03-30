import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GecmisScreen extends StatefulWidget {
  const GecmisScreen({super.key});

  @override
  State<GecmisScreen> createState() => _GecmisScreenState();
}

class _GecmisScreenState extends State<GecmisScreen> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService().getHistory();
  }

  // 🎨 Risk seviyesine göre renk belirleme
  Color getRiskColor(String risk) {
    switch (risk) {
      case "Kritik":
        return Colors.red[900]!;
      case "Yüksek":
        return Colors.red;
      case "Orta":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // 💰 Tutar Formatlama
  String formatTutar(dynamic tutar) {
    double deger = double.tryParse(tutar.toString()) ?? 0.0;
    return "${deger.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} TL";
  }

  // 🔥 YENİ: Geçmişi Silme Onay Kutusu
  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Geçmişi Sil"),
        content: const Text("Tüm işlem geçmişiniz kalıcı olarak silinecektir. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İPTAL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool ok = await ApiService().clearHistory();
              if (ok) {
                setState(() {
                  _historyFuture = ApiService().getHistory(); // Listeyi yenile
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Geçmiş başarıyla temizlendi.")),
                  );
                }
              }
            },
            child: const Text("SİL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 📝 İşlem Detaylarını Gösteren Pencere
  void _showDetailSheet(BuildContext context, Map<String, dynamic> item) {
    final riskColor = getRiskColor(item['risk_seviyesi'] ?? "");
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("İşlem Detayları", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Divider(),
              _buildDetailRow("Kategori:", item['kategori'] ?? "-"),
              _buildDetailRow("Tutar:", formatTutar(item['harcama_tutari'])),
              _buildDetailRow("Tarih:", item['tarih'] ?? "-"),
              _buildDetailRow("Risk Seviyesi:", item['risk_seviyesi'] ?? "-", color: riskColor),
              _buildDetailRow("Risk Skoru:", "%${item['risk_skoru']}", color: riskColor),
              _buildDetailRow("Analiz Notu:", item['analiz_notu'] ?? "İşlem normal aralıkta."),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black87, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("İşlem Geçmişi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _confirmClearHistory(context), 
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz bir işlem kaydı bulunamadı."));
          }

          final list = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final risk = item['risk_seviyesi'] ?? "Düşük";
              final bool isAnomaly = item['tahmin'] == "Anomali";
              final color = getRiskColor(risk);

              return GestureDetector(
                onTap: () => _showDetailSheet(context, item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(isAnomaly ? Icons.warning_rounded : Icons.check_circle_outline, color: color),
                    ),
                    title: Text(
                      "${item['kategori']} - ${formatTutar(item['harcama_tutari'])}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("${item['tarih']}\nRisk: $risk", style: const TextStyle(height: 1.4)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "%${item['risk_skoru']}",
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16),
                        ),
                        if (isAnomaly)
                          const Icon(Icons.priority_high, color: Colors.red, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}