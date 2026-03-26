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

  Color getRiskColor(String risk) {
    switch (risk) {
      case "Yüksek":
        return Colors.red;
      case "Orta":
        return Colors.orange;
      case "Kritik":
        return Colors.deepPurple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İşlem Geçmişi"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz kayıt yok"));
          }

          // En son işlemler başa gelsin
          final list = snapshot.data!.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              final risk = item['risk_seviyesi'] ?? "Düşük";
              final bool isAnomaly = item['tahmin'] == "Anomali";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: getRiskColor(risk).withOpacity(0.2),
                    child: Icon(
                      isAnomaly ? Icons.warning : Icons.check_circle,
                      color: getRiskColor(risk),
                    ),
                  ),
                  title: Text(
                    "${item['kategori']} - ${item['harcama_tutari']} TL",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['tarih'] ?? ""),
                      Text(
                        "Risk: $risk",
                        style: TextStyle(color: getRiskColor(risk)),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "%${item['risk_skoru']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getRiskColor(risk),
                        ),
                      ),
                      if (isAnomaly)
                        const Text(
                          "⚠",
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
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