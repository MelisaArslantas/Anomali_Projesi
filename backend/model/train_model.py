import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import joblib

print("📥 Veri seti yükleniyor...")
# Senin verdiğin yapıya uygun olan dosyayı okuyoruz
df = pd.read_csv("dataset/creditcard_final.csv") 

print("🧪 Feature engineering...")
df['Hour'] = (df['Time'] / 3600) % 24
df['Is_Night'] = df['Hour'].apply(lambda x: 1 if x <= 6 else 0)
df['Log_Amount'] = np.log1p(df['Amount'])

# --- KRİTİK NOKTA: KATEGORİ SÜTUNLARINI SEÇELİM ---
# "Cat_" ile başlayan tüm sütunları otomatik olarak alıyoruz
category_columns = [col for col in df.columns if col.startswith('Cat_')]

# Modelin kullanacağı tüm özellikleri birleştiriyoruz
features = ['Amount', 'Hour', 'Is_Night', 'Log_Amount'] + category_columns
X = df[features]

# Boolean (True/False) değerleri 1 ve 0'a çevirelim (Modelin anlaması için)
X = X.astype(float)

print(f"🤖 Model {len(features)} özellik ile eğitiliyor...")
print(f"Kullanılan Kategoriler: {category_columns}")

# Hassasiyeti (contamination) %5 yapıyoruz ki anomali yakalaması kolaylaşsın
model = IsolationForest(
    n_estimators=200,
    contamination=0.05, 
    random_state=42
)

model.fit(X)

print("💾 Modeller kaydediliyor...")
# API'nin ve Flutter'ın beklediği dosya isimleri
joblib.dump(model, "anomaly_model.pkl")
joblib.dump(X.columns.tolist(), "model_features.pkl")

print("✅ EĞİTİM TAMAMLANDI!")