import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;

  // Belgendeki Ç3 paketine uygun örnek senaryo soruları
  final List<Map<String, dynamic>> _questions = [
    {
      "question": "Elektronik harcamalarındaki anomaliyi dengelemek için hangisi daha etkili bir stratejidir?",
      "options": [
        "Abonelikleri iptal etmek",
        "İhtiyaç analizi yapıp beklemek",
        "Kredi kartı limitini artırmak",
        "Daha pahalı bir model almak"
      ],
      "correct": 1,
    },
    {
      "question": "Bir harcamanın 'anomali' olarak saptanması ne anlama gelir?",
      "style": "Just-in-Time Learning",
      "options": [
        "Harcamanın yasadışı olması",
        "Bütçe limitinin çok aşılması",
        "Harcama alışkanlığının dışına çıkılması",
        "Bakiyenin yetersiz kalması"
      ],
      "correct": 2,
    }
  ];

  @override
  Widget build(BuildContext context) {
    var currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mikro-Eğitim Quiz", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlerleme çubuğu (Oyunlaştırma)
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.indigo,
              minHeight: 8,
            ),
            const SizedBox(height: 40),
            Text(
              "Soru ${_currentQuestionIndex + 1}/${_questions.length}",
              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              currentQuestion["question"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 40),
            // Seçenekler
            ...List.generate(
              currentQuestion["options"].length,
              (index) => _buildOptionCard(index, currentQuestion["options"][index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_currentQuestionIndex < _questions.length - 1) {
              _currentQuestionIndex++;
            } else {
              // Quiz bittiğinde jüriye puan kazandığını göster
              _showResultDialog();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.indigo.shade50,
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C...
                  style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tebrikler! 🎉"),
        content: const Text("Bu mikro-eğitimi tamamladın ve finansal okuryazarlık skorunu artırdın."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Quiz sayfasından çık
            },
            child: const Text("Puanları Topla (+20 XP)"), // Belgendeki puan alanı[cite: 3]
          )
        ],
      ),
    );
  }
}