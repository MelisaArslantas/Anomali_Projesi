import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import joblib
import os

# Eski modelleri temizleyelim
for file in ["anomaly_model.pkl", "model_features.pkl"]:
    if os.path.exists(file):
        os.remove(file)
        print(f"🗑️ Eski dosya silindi: {file}")

print("📥 Veri seti yükleniyor...")
# Dosya yolunu senin son denediğin başarılı yolla güncelledim
df = pd.read_csv("../dataset/creditcard_final.csv") 

print("🧪 Feature engineering...")
df['Hour'] = (df['Time'] / 3600) % 24
df['Is_Night'] = df['Hour'].apply(lambda x: 1 if x <= 6 else 0)
df['Log_Amount'] = np.log1p(df['Amount'])

# --- DÜZELTME: SADECE VAR OLAN SÜTUNLARI KULLAN ---
# Veri setinde 'Age' ve 'Income' olmadığı için onları listeden çıkardık
base_features = ['Amount', 'Hour', 'Is_Night', 'Log_Amount']

# "Cat_" ile başlayan kategori sütunlarını otomatik al (Fatura, Gıda vb.)
category_columns = [col for col in df.columns if col.startswith('Cat_')]

# Modelin kullanacağı nihai özellik listesi
features = base_features + category_columns
X = df[features]

# Modelin hata almaması için tüm verileri sayısal formata çekiyoruz
X = X.astype(float)

print(f"🤖 Model {len(features)} özellik ile eğitiliyor...")
print(f"Kullanılan Özellikler: {features}")

# Hassasiyeti %1 yaparak daha dengeli bir model kuruyoruz
model = IsolationForest(
    n_estimators=200,
    contamination=0.01, 
    random_state=42
)

model.fit(X)

print("💾 Yeni modeller kaydediliyor...")
joblib.dump(model, "anomaly_model.pkl")
joblib.dump(X.columns.tolist(), "model_features.pkl")

print("✅ EĞİTİM TAMAMLANDI VE YENİ MODELLER OLUŞTURULDU!")