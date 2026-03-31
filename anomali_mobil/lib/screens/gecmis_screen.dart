import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GecmisScreen extends StatefulWidget {
  const GecmisScreen({super.key});

  @override
  State<GecmisScreen> createState() => _GecmisScreenState();
}

class _GecmisScreenState extends State<GecmisScreen> {
  late Future<List<dynamic>> _historyFuture;
  String _selectedCategory = 'Hepsi';
  DateTime? _selectedDate; // 🗓️ Seçilen tarih filtresi

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
    setState(() {
      _historyFuture = ApiService().getHistory();
    });
  }

  // 🗓️ Takvimden tarih seçme fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: 'Filtrelemek için tarih seçin',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 🛠️ MANTIK: Kategori Filtrele + Tarih Filtrele + En Yeni Üstte Sırala
  List<dynamic> _processData(List<dynamic> rawData) {
    List<dynamic> filtered = rawData;

    // 1. Kategori Filtresi
    if (_selectedCategory != 'Hepsi') {
      filtered = filtered.where((item) => item['kategori'] == _selectedCategory).toList();
    }

    // 2. Tarih Filtresi (Sadece seçilen güne ait harcamalar)
    if (_selectedDate != null) {
      filtered = filtered.where((item) {
        DateTime itemDate = _parseCsvDate(item['tarih'] ?? "");
        return itemDate.year == _selectedDate!.year &&
               itemDate.month == _selectedDate!.month &&
               itemDate.day == _selectedDate!.day;
      }).toList();
    }

    // 3. Sıralama (En yeni en üstte)
    filtered.sort((a, b) {
      try {
        DateTime dateA = _parseCsvDate(a['tarih'] ?? "");
        DateTime dateB = _parseCsvDate(b['tarih'] ?? "");
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

  DateTime _parseCsvDate(String dateStr) {
    try {
      List<String> parts = dateStr.split(' ');
      List<String> dateParts = parts[0].split('.');
      List<String> timeParts = parts[1].split(':');

      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime(2000);
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case "Kritik": return Colors.red[900]!;
      case "Yüksek": return Colors.red[700]!;
      case "Orta": return Colors.orange[700]!;
      default: return Colors.green[700]!;
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
        elevation: 0,
        actions: [
          // 🗓️ Tarih filtresi aktifse iptal etme butonu
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.event_busy, color: Colors.orangeAccent),
              onPressed: () => setState(() => _selectedDate = null),
              tooltip: "Tarih Filtresini Kaldır",
            ),
          // 📅 Takvim açma butonu
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _selectDate(context),
            tooltip: "Tarih Seç",
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClearHistory(context),
            tooltip: "Geçmişi Temizle",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          // 📍 Eğer tarih seçiliyse kullanıcıya bilgi ver
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.indigo[50],
              width: double.infinity,
              child: Text(
                "Filtre: ${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year} tarihindeki harcamalar",
                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadHistory(),
              child: FutureBuilder<List<dynamic>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(Icons.history_rounded, "Henüz hiç işlem kaydı yok.");
                  }

                  final displayList = _processData(snapshot.data!);

                  if (displayList.isEmpty) {
                    return _buildEmptyState(Icons.filter_list_off, "Seçilen kriterlere uygun kayıt bulunamadı.");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) => _buildTransactionCard(displayList[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.indigo,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: Colors.white,
              backgroundColor: Colors.indigo[400],
              labelStyle: TextStyle(
                color: isSelected ? Colors.indigo : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              onSelected: (val) => setState(() => _selectedCategory = cat),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final risk = item['risk_seviyesi'] ?? "Düşük";
    final riskColor = _getRiskColor(risk);
    final isAnomaly = item['tahmin'] == "Anomali";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: riskColor, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () => _showDetailSheet(context, item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAnomaly ? Icons.warning_amber_rounded : Icons.receipt_long_rounded,
            color: riskColor,
            size: 24,
          ),
        ),
        title: Text(
          "${item['kategori']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item['tarih'] ?? "-", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              isAnomaly ? "⚠️ Şüpheli İşlem" : "✓ Normal İşlem",
              style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${item['harcama_tutari']} TL",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.indigo),
            ),
            const SizedBox(height: 2),
            Text(
              "Risk: %${item['risk_skoru']}",
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadHistory, child: const Text("Yenile", style: TextStyle(color: Colors.indigo))),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Geçmişi Sil"),
        content: const Text("Tüm harcama geçmişiniz CSV dosyasından kalıcı olarak silinecektir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("VAZGEÇ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              if (await ApiService().clearHistory()) {
                _loadHistory();
                Navigator.pop(context);
              }
            },
            child: const Text("SİL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("İşlem Detayı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _detailRow("Tarih:", item['tarih']),
            _detailRow("Kategori:", item['kategori']),
            _detailRow("Tutar:", "${item['harcama_tutari']} TL"),
            _detailRow("Risk Skoru:", "%${item['risk_skoru']}"),
            _detailRow("Analiz:", item['tahmin'] == "Anomali" ? "Şüpheli İşlem" : "Normal Harcama"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text("Kapat", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}