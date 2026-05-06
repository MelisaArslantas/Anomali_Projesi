import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import joblib
import os

# 1. ESKİ MODELLERİ TEMİZLEYELİM (Hata almamak için önemli)
for file in ["anomaly_model.pkl", "model_features.pkl"]:
    if os.path.exists(file):
        os.remove(file)
        print(f"🗑️ Eski dosya silindi: {file}")

print("📥 Veri seti yükleniyor...")
# Veri setinin olduğu yolu kontrol et, gerekirse "dataset/creditcard_final.csv" yap
df = pd.read_csv("../dataset/creditcard_final.csv") 

print("🧪 Feature engineering ve Kategorilerin Tanımlanması...")
df['Hour'] = (df['Time'] / 3600) % 24
df['Is_Night'] = df['Hour'].apply(lambda x: 1 if x <= 6 else 0)
df['Log_Amount'] = np.log1p(df['Amount'])

# ✅ YENİ VE GERÇEKÇİ KATEGORİ LİSTEMİZ (Flutter ile birebir aynı olmalı)
yeni_kategoriler = [
    'Gıda & Market', 'Kira & Konut', 'Fatura & Aidat', 
    'Ulaşım & Akaryakıt', 'Dışarıda Yemek', 'Eğitim & Gelişim', 
    'Teknoloji & Elektronik', 'Sağlık & Bakım', 'Giyim & Aksesuar', 
    'Eğlence & Hobiler', 'Borç & Taksit', 'Diğer'
]

# Ana özellikler (IP3 hedeflerin için 'Income' yani Gelir bilgisini de ekledik)
base_features = ['Amount', 'Hour', 'Is_Night', 'Log_Amount']

# ✅ Kategori sütunlarını "Cat_" ön ekiyle oluşturuyoruz
category_columns = [f"Cat_{cat}" for cat in yeni_kategoriler]

# Veri setinde bu sütunlar yoksa, hata almamak için hepsini 0.0 olarak ekleyelim
for col in category_columns:
    if col not in df.columns:
        df[col] = 0.0

# 2. MODELİN KULLANACAĞI NİHAİ ÖZELLİK LİSTESİ
features = base_features + category_columns
X = df[features]

# Tüm verileri sayısal formata çekiyoruz
X = X.astype(float)

print(f"🤖 Model {len(features)} özellik ile eğitiliyor...")
print(f"Kullanılan Kategoriler: {yeni_kategoriler}")

# 3. ISOLATION FOREST MODELİNİ YAPILANDIRALIM
# Contamination=0.01: İşlemlerin %1'ini anomali olarak yakalar (JiTT uyarısı için ideal)
model = IsolationForest(
    n_estimators=200,
    contamination=0.01, 
    random_state=42
)

model.fit(X)

print("💾 Yeni modeller kaydediliyor...")
# Bu dosyalar main.py tarafından okunacak
joblib.dump(model, "anomaly_model.pkl")
joblib.dump(X.columns.tolist(), "model_features.pkl")

print("✅ EĞİTİM TAMAMLANDI VE YENİ KATEGORİLER MODELE ÖĞRETİLDİ!")