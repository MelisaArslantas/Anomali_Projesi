import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  final String topic; // 🔥 Hangi konunun quizi olduğunu tutacak
  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;

  // 🔥 Konulara göre soru havuzu
  final Map<String, List<Map<String, dynamic>>> _questionPool = {
    "Dürtüsel Harcama": [
      {
        "question": "İndirimde gördüğünüz ama planınızda olmayan bir ürünü almadan önce ne kadar beklemelisiniz?",
        "options": ["Hemen almalıyım", "24-48 saat beklemeliyim", "Limit bitene kadar", "Başkasına sormalıyım"],
        "correct": 1,
      },
      {
        "question": "Dürtüsel harcamayı tetikleyen en yaygın duygu hangisidir?",
        "options": ["Açlık", "Anlık heyecan/stres", "Yorgunluk", "Hepsi"],
        "correct": 3,
      }
    ],
    "Akıllı Birikim": [
      {
        "question": "Birikim yaparken 'Önce Kendine Öde' kuralı neyi ifade eder?",
        "options": ["Borçları ödemek", "Harcamalardan kalanı saklamak", "Gelir gelir gelmez birikimi ayırmak", "Eğlenmek"],
        "correct": 2,
      }
    ],
    "Elektronik Bütçe": [
      {
        "question": "Elektronik cihaz alırken 'Toplam Sahiplik Maliyeti' neyi kapsar?",
        "options": ["Sadece satış fiyatı", "Fiyat + Bakım + Enerji giderleri", "Kargo ücreti", "Garanti süresi"],
        "correct": 1,
      }
    ]
  };

  Future<void> _updateUserXP() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'total_xp': FieldValue.increment(20),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Seçilen konunun sorularını al, yoksa boş liste döndür
    var questions = _questionPool[widget.topic] ?? [];
    
    if (questions.isEmpty) return const Scaffold(body: Center(child: Text("Soru bulunamadı")));
    var currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text("${widget.topic} Quizi")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(value: (_currentQuestionIndex + 1) / questions.length),
            const SizedBox(height: 40),
            Text(currentQuestion["question"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ...List.generate(currentQuestion["options"].length, (index) => _buildOption(index, currentQuestion["options"][index], questions.length)),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index, String text, int totalLength) {
    return ListTile(
      title: Text(text),
      onTap: () {
        setState(() {
          if (_currentQuestionIndex < totalLength - 1) {
            _currentQuestionIndex++;
          } else {
            _showResultDialog();
          }
        });
      },
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Tebrikler! 🎉"),
        content: Text("${widget.topic} konusunu başarıyla tamamladın."),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _updateUserXP();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Puanları Topla (+20 XP)"),
          )
        ],
      ),
    );
  }
}