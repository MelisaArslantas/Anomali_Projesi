import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/analiz_modeli.dart';
import 'analiz_form_screen.dart';
import 'gecmis_screen.dart';
import 'profil.dart';
import 'jitt.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final PageController _chartPageController = PageController();

  static const Color customEmerald = Color(0xFF10B981);
  
  bool hasNotification = true;
  bool isLoading = true;
  int _currentChartIndex = 0;

  String userName = "Yükleniyor...";
  String monthlyIncome = "0";
  String transactionCount = "0";
  String averageRisk = "0";
  String status = "Yükleniyor...";

  // 📊 Gerçek veri havuzumuz
  Map<String, double> _categoryTotals = {};
  double _totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final userData = await _authService.getUserData();
      if (userData != null && userData.exists) {
        String uid = userData['uid'];
        final stats = await _apiService.getUserStats(uid);
        final historyData = await _apiService.getHistory(uid);
        
        // Verileri kategorilere göre grupla
        Map<String, double> totals = {};
        double total = 0.0;
        for (var item in historyData) {
          totals[item.kategori] = (totals[item.kategori] ?? 0) + item.harcamaTutari;
          total += item.harcamaTutari;
        }

        if (mounted) {
          setState(() {
            userName = stats['name'] ?? userData['name'] ?? "Kullanıcı";
            monthlyIncome = (stats['income'] ?? userData['monthly_income']).toString();
            transactionCount = (stats['count'] ?? 0).toString();
            averageRisk = (stats['avg_risk'] ?? 0).toString();
            status = stats['status'] ?? "Güvenli";
            _categoryTotals = totals;
            _totalExpense = total;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilScreen(userEmail: widget.userEmail))).then((_) => _fetchDashboardData())),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async { await _authService.logout(); if (mounted) Navigator.pop(context); }),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSummaryGrid(),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildQuickActionButton(context, "Analiz Yap", Icons.add_chart, Colors.indigo, const AnalizFormScreen())),
                        const SizedBox(width: 15),
                        Expanded(child: _buildJittQuickButton(context)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildChartCarousel(),
                    const SizedBox(height: 10),
                    _buildPageIndicator(),
                    const SizedBox(height: 20),
                    _buildActionButton(context, "İşlem Geçmişi", Icons.history, const Color(0xFF475569), 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GecmisScreen())).then((_) => _fetchDashboardData())),
                  ],
                ),
              ),
            ),
    );
  }

  // 🥧 YÜZDELİKLİ PASTA GRAFİĞİ (GERÇEK VERİ)
  Widget _buildExpensePieChart() {
    if (_categoryTotals.isEmpty) return const Center(child: Text("Harcama verisi bulunamadı."));
    final colors = [Colors.indigo, Colors.orange, customEmerald, Colors.redAccent, Colors.purple, Colors.blue];
    int colorIdx = 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: _categoryTotals.entries.map((e) {
          double percentage = (e.value / _totalExpense) * 100;
          final color = colors[colorIdx % colors.length];
          colorIdx++;
          return PieChartSectionData(
            value: e.value,
            title: "${percentage.toStringAsFixed(1)}%",
            color: color,
            radius: 55,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: _buildChartBadge(e.key, color),
            badgePositionPercentageOffset: 1.2,
          );
        }).toList(),
      ),
    );
  }

  // 🏎️ 180 DERECE BÜTÇE GÖSTERGESİ (GAUGE)
  Widget _buildBudgetGauge() {
    double income = double.tryParse(monthlyIncome) ?? 1.0;
    double expenseRatio = _totalExpense / income;
    if (expenseRatio > 1.0) expenseRatio = 1.0; // Limit aşımı kontrolü

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: 180,
            sectionsSpace: 0,
            centerSpaceRadius: 60,
            sections: [
              // Harcanan kısım
              PieChartSectionData(value: _totalExpense, color: expenseRatio > 0.8 ? Colors.redAccent : Colors.indigo, radius: 20, showTitle: false),
              // Kalan bütçe (180 dereceyi tamamlamak için)
              PieChartSectionData(value: (income - _totalExpense).clamp(0, income), color: Colors.grey.shade200, radius: 20, showTitle: false),
              // Alt yarıyı boş bırakmak için hayali bölüm
              PieChartSectionData(value: income, color: Colors.transparent, radius: 20, showTitle: false),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("₺${_totalExpense.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Kullanılan Bütçe", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        )
      ],
    );
  }

  // KÜÇÜK YARDIMCI WIDGETLAR
  Widget _buildChartBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChartCarousel() {
    return SizedBox(
      height: 300,
      child: PageView(
        controller: _chartPageController,
        onPageChanged: (idx) => setState(() => _currentChartIndex = idx),
        children: [
          _buildChartContainer("Harcama Dağılımı (%)", _buildExpensePieChart()),
          _buildChartContainer("Bütçe Kullanımı (180°)", _buildBudgetGauge()),
        ],
      ),
    );
  }

  // (Header, SummaryGrid, QuickAction ve diğer yardımcı metotlar önceki halindeki gibi kompakt kalsın...)
  Widget _buildHeader() { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Hoşgeldin Melisa,", style: TextStyle(fontSize: 16, color: Colors.grey[600])), Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.indigo))]); }
  Widget _buildPageIndicator() { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(2, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentChartIndex == index ? Colors.indigo : Colors.grey.shade300)))); }
  Widget _buildChartContainer(String title, Widget chart) { return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)), const Icon(Icons.swap_horiz, size: 18, color: Colors.grey)]), const SizedBox(height: 20), Expanded(child: chart)]))); }
  Widget _buildSummaryGrid() { return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6, children: [_buildSummaryCard("Aylık Gelir", "₺$monthlyIncome", Icons.wallet, customEmerald), _buildSummaryCard("İşlem", transactionCount, Icons.receipt_long, Colors.blue), _buildSummaryCard("Risk Skoru", "%$averageRisk", Icons.security, Colors.orange), _buildSummaryCard("Durum", status, Icons.info_outline, Colors.teal)]); }
  Widget _buildQuickActionButton(BuildContext context, String title, IconData icon, Color color, Widget target) { return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)).then((_) => _fetchDashboardData()), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Icon(icon, color: Colors.white), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]))); }
  Widget _buildJittQuickButton(BuildContext context) { return InkWell(onTap: () { setState(() => hasNotification = false); Navigator.push(context, MaterialPageRoute(builder: (context) => const JittPage())); }, child: Stack(clipBehavior: Clip.none, children: [Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.purple.shade700, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: const Column(children: [Icon(Icons.auto_awesome, color: Colors.white), const SizedBox(height: 8), Text("Gelişim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))])), if (hasNotification) Positioned(right: -2, top: -2, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))])); }
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 10)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])); }
  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) { return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(title), style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))); }
}