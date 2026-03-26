import pandas as pd
import numpy as np
import joblib
import os

# 1. DOSYA YOLLARI
MODEL_PATH = "model/anomaly_model.pkl"
FEATURES_PATH = "model/model_features.pkl"
DATASET_PATH = "dataset/creditcard_final.csv"

def rapor_olustur():
    # Dosya kontrolü
    if not os.path.exists(MODEL_PATH) or not os.path.exists(DATASET_PATH):
        print("❌ HATA: Model veya Dataset bulunamadı! Lütfen yolları kontrol edin.")
        return

    print("📊 Veri seti ve Model yükleniyor...")
    model = joblib.load(MODEL_PATH)
    features = joblib.load(FEATURES_PATH)
    df = pd.read_csv(DATASET_PATH)

    # 2. FEATURE ENGINEERING
    print("🧪 Özellikler hesaplanıyor...")
    
    # Zaman bazlı özellikler
    if 'Time' in df.columns:
        df['Hour'] = (df['Time'] / 3600) % 24
        df['Is_Night'] = df['Hour'].apply(lambda x: 1 if x <= 6 else 0)
    
    # Log dönüşümü
    df['Log_Amount'] = np.log1p(df['Amount'])
    
    # API'de kullandığımız kategori ve gelir grubu sütunlarını kontrol et
    # Eğer CSV'de yoksa, modelin çökmemesi için 0 ile dolduruyoruz
    for col in features:
        if col not in df.columns:
            df[col] = 0.0

    # 3. TAHMİN VE ANALİZ
    # Sadece modelin bildiği özellikleri (features) ve doğru sırada gönderiyoruz
    X = df[features].astype(float)
    
    print(f"🤖 Model {len(df):,} işlemi analiz ediyor...")
    
    # IsolationForest: 1 = Normal, -1 = Anomali
    df['Tahmin'] = model.predict(X) 
    df['Güven_Skoru'] = model.decision_function(X)

    anomaliler = df[df['Tahmin'] == -1]
    normal_islem = df[df['Tahmin'] == 1]

    # 4. SONUÇLARI EKRANA YAZDIR
    print("\n" + "═"*50)
    print("             MODEL PERFORMANS RAPORU")
    print("═"*50)
    print(f"✅ Toplam İncelenen İşlem : {len(df):>10,}")
    print(f"🚨 Tespit Edilen Anomali : {len(anomaliler):>10,}")
    print(f"🛡️  Normal İşlem Sayısı  : {len(normal_islem):>10,}")
    
    anomali_orani = (len(anomaliler) / len(df)) * 100
    print(f"📈 Anomali Oranı         : %{anomali_orani:>9.2f}")
    print("─"*50)

    if not anomaliler.empty:
        print("\n🚩 EN YÜKSEK RİSKLİ (EN ŞÜPHELİ) 5 İŞLEM:")
        # Skor ne kadar küçükse (negatif) o kadar şüphelidir
        top_anomalies = anomaliler.sort_values(by='Güven_Skoru').head(5)
        
        for i, row in top_anomalies.iterrows():
            print(f"❌ Skor: {row['Güven_Skoru']:.4f} | Tutar: {row['Amount']:,.2f} TL | Satır ID: {i}")
    else:
        print("\n✅ Harika! Hiç anomali tespit edilmedi.")

    print("\n" + "═"*50)
    
    # Değerlendirme Notu
    if 0.1 <= anomali_orani <= 5:
        print("💡 DURUM: Model sağlıklı çalışıyor (Anomali oranı dengeli).")
    elif anomali_orani > 10:
        print("⚠️  UYARI: Anomali oranı çok yüksek! Model çok hassas olabilir.")
    else:
        print("ℹ️  BİLGİ: Veri seti çok temiz veya model yeterince hassas değil.")

if __name__ == "__main__":
    rapor_olustur()