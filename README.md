Yapay Zeka Destekli Kişisel Finans Yönetimi ve Finansal Okuryazarlık Platformu
Bu proje, bireysel harcama verilerini makine öğrenmesi algoritmalarıyla analiz ederek finansal anomalileri tespit eden ve interaktif quiz modülleri ile kullanıcıların finansal okuryazarlığını artıran bir mobil platformdur.

Kullanılan Teknolojiler
Frontend: Flutter

Backend: FastAPI

Veritabanı: Firebase

Makine Öğrenmesi: Python (Scikit-learn, Isolation Forest)

Proje Yapısı
/anomali_mobil: Flutter tabanlı mobil uygulama kaynak kodları.

/backend: FastAPI servisleri ve Isolation Forest modelinin bulunduğu dizin.

/backend/model: Eğitilmiş model dosyaları (.pkl).

Kurulum ve Çalıştırma
1. Backend (API)
Backend servislerini başlatmak için:

Bash
cd backend
pip install -r ../requirements.txt
uvicorn main:app --reload
2. Mobil Uygulama (Flutter)
Mobil uygulamayı çalıştırmak için:

Bash
cd anomali_mobil
flutter pub get
flutter run
Not: Firebase entegrasyonu için gerekli google-services.json (Android) ve GoogleService-Info.plist (iOS) dosyaları ilgili dizinlere eklenmiştir.
