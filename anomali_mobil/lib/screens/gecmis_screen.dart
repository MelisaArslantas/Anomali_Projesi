import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; 
import '../models/analiz_modeli.dart';

class GecmisScreen extends StatefulWidget {
  const GecmisScreen({super.key});

  @override
  State<GecmisScreen> createState() => _GecmisScreenState();
}

class _GecmisScreenState extends State<GecmisScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  List<AnalizModeli> _allData = [];
  bool _yukleniyor = true;
  String? _currentUid;
  
  String _selectedCategory = 'Hepsi';
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Hepsi', 'Gıda & Market', 'Kira & Konut', 'Fatura & Aidat', 
    'Ulaşım & Akaryakıt', 'Dışarıda Yemek', 'Eğitim & Gelişim', 
    'Teknoloji & Elektronik', 'Sağlık & Bakım', 'Giyim & Aksesuar', 
    'Eğlence & Hobiler', 'Borç & Taksit', 'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final userData = await _authService.getUserData();
    if (userData != null && userData.exists) {
      _currentUid = userData['uid'];
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (_currentUid == null) return;
    setState(() => _yukleniyor = true);
    try {
      final data = await _apiService.getHistory(_currentUid!);
      setState(() {
        _allData = data;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      _showSnackBar("⚠️ Veriler yüklenemedi", Colors.red);
    }
  }

  // Filtreleme Mantığı
  List<AnalizModeli> _getFilteredData() {
    return _allData.where((item) {
      bool catMatch = _selectedCategory == 'Hepsi' || item.kategori == _selectedCategory;
      bool dateMatch = true;
      if (_selectedDate != null) {
        DateTime itemDate = _parseCsvDate(item.tarih);
        dateMatch = itemDate.year == _selectedDate!.year &&
                    itemDate.month == _selectedDate!.month &&
                    itemDate.day == _selectedDate!.day;
      }
      return catMatch && dateMatch;
    }).toList();
  }

  DateTime _parseCsvDate(String dateStr) {
    try {
      List<String> parts = dateStr.split(' ');
      List<String> dateParts = parts[0].split('.');
      return DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
    } catch (e) { return DateTime(2000); }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("📜 İşlem Geçmişim", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedDate != null)
            IconButton(icon: const Icon(Icons.event_busy), onPressed: () => setState(() => _selectedDate = null)),
          IconButton(icon: const Icon(Icons.calendar_month), 
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            }
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : filteredList.isEmpty
                    ? const Center(child: Text("Henüz işlem kaydı bulunmuyor."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          
                          return Dismissible(
                            key: Key("${item.tarih}_${item.kategori}"),
                            direction: DismissDirection.endToStart,
                            
                            // ✅ DÜZENLENEN KISIM BURASI:
                            confirmDismiss: (direction) async {
                              // 1. Önce onay sor
                              bool onay = await _showDeleteDialog();
                              if (onay) {
                                // 2. Onay verildiyse backend'e gönder
                                final success = await _apiService.deleteTransaction(_currentUid!, item.tarih);
                                if (success) {
                                  setState(() {
                                    _allData.remove(item);
                                  });
                                  _showSnackBar("🗑️ İşlem başarıyla silindi", Colors.green);
                                  return true; // Kartın uçup gitmesine izin ver
                                } else {
                                  _showSnackBar("❌ Silme işlemi başarısız", Colors.red);
                                  return false; // Başarısız olursa kart geri gelsin
                                }
                              }
                              return false; // İptal edilirse kart geri gelsin
                            },
                            
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(15)
                              ),
                              child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                            ),
                            child: _buildTransactionCard(item),
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
              selectedColor: Colors.white,
              labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.indigo : Colors.white),
              backgroundColor: Colors.indigo[400],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(AnalizModeli item) {
    final bool isAnomaly = item.tahmin == "Anomali";
    final Color riskColor = item.riskSkoru >= 70 ? Colors.red : (item.riskSkoru >= 40 ? Colors.orange : Colors.green);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(isAnomaly ? Icons.warning : Icons.check_circle, color: riskColor),
        title: Text(item.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.tarih),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${item.harcamaTutari} TL", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            Text("%${item.riskSkoru}", style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silme Onayı"),
        content: const Text("Bu harcama kaydını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İPTAL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SİL", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
}