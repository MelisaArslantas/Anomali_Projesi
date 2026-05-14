import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class PortfoyScreen extends StatefulWidget {
  const PortfoyScreen({super.key});

  @override
  State<PortfoyScreen> createState() => _PortfoyScreenState();
}

class _PortfoyScreenState extends State<PortfoyScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final ApiService _apiService = ApiService();
  
  Map<String, double> _livePrices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLivePrices();
  }

  Future<void> _fetchLivePrices() async {
    setState(() => _isLoading = true);
    final prices = await _apiService.getLivePrices();
    if (mounted) {
      setState(() {
        _livePrices = prices;
        _isLoading = false;
      });
    }
  }

  // 🔥 Toplam Değeri Hassas Hesaplayan Fonksiyon
  double _calculateTotalPortfolio(List<QueryDocumentSnapshot> docs) {
    double total = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      String varlik = (data['varlik'] ?? "").toString().toLowerCase().trim();
      double miktar = double.tryParse(data['miktar'].toString()) ?? 0.0;
      double alisFiyati = double.tryParse(data['fiyat'].toString()) ?? 0.0;

      // API fiyatını bul (harf duyarsız)
      double guncelBirimFiyat = 0.0;
      _livePrices.forEach((key, value) {
        if (key.toLowerCase().trim() == varlik) {
          guncelBirimFiyat = value;
        }
      });

      // API'de yoksa alış fiyatını kullan
      if (guncelBirimFiyat == 0.0) guncelBirimFiyat = alisFiyati;

      total += (miktar * guncelBirimFiyat);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Mizan - Birikim Defterim", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLivePrices)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('portfoy').orderBy('tarih', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                double totalValue = _calculateTotalPortfolio(docs);

                return Column(
                  children: [
                    _buildTotalValueCard(totalValue),
                    Expanded(
                      child: docs.isEmpty 
                        ? const Center(child: Text("Henüz birikim eklenmemiş."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;
                              
                              return Dismissible(
                                key: Key(docId),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                                ),
                                confirmDismiss: (direction) => _showDeleteConfirmDialog(docId),
                                child: _buildAssetCard(data, docId),
                              );
                            },
                          ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTotalValueCard(double totalValue) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Color(0xFF4C51BF)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("Toplam Portföy Değeri", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            "₺${totalValue.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> data, String docId) {
    String varlik = data['varlik'] ?? "Bilinmiyor";
    double alisFiyati = double.tryParse(data['fiyat'].toString()) ?? 0.0;
    double miktar = double.tryParse(data['miktar'].toString()) ?? 0.0;
    
    double guncelFiyat = 0.0;
    _livePrices.forEach((key, value) {
      if (key.toLowerCase().trim() == varlik.toLowerCase().trim()) {
        guncelFiyat = value;
      }
    });
    if (guncelFiyat == 0.0) guncelFiyat = alisFiyati;

    double karZarar = (guncelFiyat - alisFiyati) * miktar;
    double yuzde = alisFiyati > 0 ? ((guncelFiyat - alisFiyati) / alisFiyati) * 100 : 0.0;
    bool isPositive = karZarar >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? Colors.green : Colors.red),
        ),
        title: Text("$miktar $varlik", style: const TextStyle(fontWeight: FontWeight.bold)),
        // ✅ Kuruşları burada görünür yaptık
        subtitle: Text(
          "Alış: ₺${alisFiyati.toStringAsFixed(2)} | Güncel: ₺${guncelFiyat.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ✅ Kâr/Zarar TL tutarı da artık küsuratlı ve net
            Text(
              "${isPositive ? '+' : ''}${karZarar.toStringAsFixed(2)} TL", 
              style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red)
            ),
            Text(
              "%${yuzde.toStringAsFixed(2)}", 
              style: TextStyle(fontSize: 12, color: isPositive ? Colors.green : Colors.red)
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(String docId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Sil?"),
        content: const Text("Bu birikimi defterden silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(uid).collection('portfoy').doc(docId).delete();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAssetDialog() {
    String selectedAsset = "Gram Altın";
    final List<String> assetList = ["Gram Altın", "Dolar", "Euro", "Çeyrek Altın"];
    final miktarController = TextEditingController();
    final fiyatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Yeni Birikim Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedAsset,
                decoration: const InputDecoration(labelText: "Varlık Türü"),
                items: assetList.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setDialogState(() => selectedAsset = val!),
              ),
              const SizedBox(height: 10),
              TextField(controller: miktarController, decoration: const InputDecoration(labelText: "Miktar"), keyboardType: TextInputType.number),
              TextField(controller: fiyatController, decoration: const InputDecoration(labelText: "Alış Fiyatı (TL)"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (uid != null && miktarController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).collection('portfoy').add({
                    'varlik': selectedAsset,
                    'miktar': double.tryParse(miktarController.text) ?? 0.0,
                    'fiyat': double.tryParse(fiyatController.text) ?? 0.0,
                    'tarih': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}