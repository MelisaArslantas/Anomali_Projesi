import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analiz_modeli.dart'; // 🆕 Model dosyasını buraya ekliyoruz

class GecmisScreen extends StatefulWidget {
  const GecmisScreen({super.key});

  @override
  State<GecmisScreen> createState() => _GecmisScreenState();
}

class _GecmisScreenState extends State<GecmisScreen> {
  // 🆕 Future tipini AnalizModeli listesi olarak güncelledik
 late Future<List<AnalizModeli>> _historyFuture;
  String _selectedCategory = 'Hepsi';
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Hepsi', 'Fatura', 'Giyim', 'Eğlence', 'Market', 
    'Gıda', 'Restoran', 'Seyahat', 'Elektronik', 'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

void _loadHistory() {
  // Gelecekteki veriyi çekerken tipini tekrar hatırlatıyoruz
  _historyFuture = ApiService().getHistory();
  setState(() {}); 
}
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // 🛠️ Verileri filtreleme ve sıralama mantığı
  List<AnalizModeli> _processData(List<AnalizModeli> rawData) {
    List<AnalizModeli> filtered = rawData;

    if (_selectedCategory != 'Hepsi') {
      filtered = filtered.where((item) => item.kategori == _selectedCategory).toList();
    }

    if (_selectedDate != null) {
      filtered = filtered.where((item) {
        DateTime itemDate = _parseCsvDate(item.tarih);
        return itemDate.year == _selectedDate!.year &&
               itemDate.month == _selectedDate!.month &&
               itemDate.day == _selectedDate!.day;
      }).toList();
    }
    return filtered;
  }

  DateTime _parseCsvDate(String dateStr) {
    try {
      List<String> parts = dateStr.split(' ');
      List<String> dateParts = parts[0].split('.');
      List<String> timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
        int.parse(timeParts[0]), int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime(2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("İşlem Geçmişi", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedDate != null)
            IconButton(icon: const Icon(Icons.event_busy), onPressed: () => setState(() => _selectedDate = null)),
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => _selectDate(context)),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<List<AnalizModeli>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Henüz hiç işlem kaydı yok."));
                }

                final displayList = _processData(snapshot.data!);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) => _buildTransactionCard(displayList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      color: Colors.indigo,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: _selectedCategory == cat,
              onSelected: (val) => setState(() => _selectedCategory = cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(AnalizModeli item) {
    // Risk skoruna göre renk belirleme
    final Color riskColor = item.riskSkoru >= 70 ? Colors.red : (item.riskSkoru >= 30 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(item.tahmin == "Anomali" ? Icons.warning : Icons.check_circle, color: riskColor),
        title: Text(item.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.tarih),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${item.miktar} TL", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            Text("%${item.riskSkoru}", style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}