from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
import joblib
import pandas as pd
import numpy as np
import os
from datetime import datetime

# ----------------------------------------
# FastAPI YAPILANDIRMASI
# ----------------------------------------
app = FastAPI(title="Anomali Tespit API", version="4.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------------
# PATH AYARLARI
# ----------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__)) 
MODEL_PATH = os.path.join(BASE_DIR, "model", "anomaly_model.pkl")
FEATURES_PATH = os.path.join(BASE_DIR, "model", "model_features.pkl")
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LOG_PATH = os.path.join(DATASET_DIR, "islem_gecmisi.csv")

if not os.path.exists(DATASET_DIR):
    os.makedirs(DATASET_DIR)

# ----------------------------------------
# MODEL YÜKLEME
# ----------------------------------------
try:
    model = joblib.load(MODEL_PATH)
    feature_columns = joblib.load(FEATURES_PATH)
    print(f"✅ Model ve Özellikler Yüklendi: {len(feature_columns)} sütun")
except Exception as e:
    print(f"❌ Model yükleme hatası: {e}")
    model = None
    feature_columns = []

# ----------------------------------------
# YARDIMCI FONKSİYONLAR
# ----------------------------------------
def get_risk_level(score: float) -> str:
    if score >= 75: return "Kritik"
    elif score >= 50: return "Yüksek"
    elif score >= 30: return "Orta"
    else: return "Düşük"

def save_to_csv(row_data: dict):
    columns = ["tarih", "kullanici_id", "kategori", "harcama_tutari", "risk_seviyesi", "risk_skoru", "tahmin"]
    df_new = pd.DataFrame([row_data], columns=columns)
    try:
        if not os.path.exists(LOG_PATH):
            df_new.to_csv(LOG_PATH, index=False, encoding="utf-8-sig")
        else:
            df_new.to_csv(LOG_PATH, mode='a', index=False, header=False, encoding="utf-8-sig")
    except Exception as e:
        print(f"⚠️ Kayıt Hatası: {e}")

# ----------------------------------------
# ENDPOINTS
# ----------------------------------------
@app.get("/")
def home():
    return {"status": "active", "model_loaded": model is not None}

@app.post("/predict")
async def predict(data: dict = Body(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model yüklü değil.")
    
    try:
        # 1. Verileri Flutter'dan Alıyoruz
        tutar = float(data.get("amount") or data.get("harcama_tutari") or 0.0)
        kategori = str(data.get("category") or data.get("kategori") or "Diğer")
        u_id = int(data.get("userId") or data.get("kullanici_id") or 1)
        
        now = datetime.now()
        
        # 2. Model Özelliklerini Hazırlıyoruz
        input_row = {col: 0.0 for col in feature_columns}
        input_row['Amount'] = tutar
        input_row['Hour'] = float(now.hour)
        input_row['Is_Night'] = 1.0 if now.hour <= 6 else 0.0
        input_row['Log_Amount'] = np.log1p(tutar)

        # 3. Kategori Sütununu Eşleştiriyoruz (Örn: Cat_Dışarıda Yemek)
        cat_key = f"Cat_{kategori}"
        if cat_key in input_row:
            input_row[cat_key] = 1.0
        
        # 4. Tahmin Yapıyoruz
        input_df = pd.DataFrame([input_row])[feature_columns]
        prediction = model.predict(input_df)[0]
        decision_val = model.decision_function(input_df)[0]
        
        # Risk Skoru Hesaplama (0-100 arası)
        risk_score = round(float(np.clip((0.5 - decision_val) * 100, 0, 100)), 1)
        
        is_anomaly = (prediction == -1)
        tahmin_metni = "Anomali" if is_anomaly else "Normal"
        risk_level = get_risk_level(risk_score)

        res_data = {
            "tarih": now.strftime("%d.%m.%Y %H:%M"),
            "kullanici_id": u_id,
            "kategori": kategori,
            "harcama_tutari": tutar, 
            "risk_seviyesi": risk_level,
            "risk_skoru": risk_score,
            "tahmin": tahmin_metni
        }
        
        save_to_csv(res_data)

        # 5. JiTT Popup İçin Yanıt Gönderiyoruz
        return {
            **res_data,
            "aciklama": "Şüpheli harcama! Profil limitlerinizi aşıyor." if is_anomaly else "İşlem normal.",
            "analiz_notu": "Gelişim Merkezini (JiTT) kontrol edin." if is_anomaly else "Düzenli harcama."
        }

    except Exception as e:
        print(f"🔥 Predict Hatası: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history")
def get_history():
    try:
        if not os.path.exists(LOG_PATH): return []
        df = pd.read_csv(LOG_PATH, encoding="utf-8-sig")
        return df.replace({np.nan: None}).to_dict(orient="records")[::-1]
    except Exception as e:
        return []

# ----------------------------------------
# ÇALIŞTIRMA
# ----------------------------------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)