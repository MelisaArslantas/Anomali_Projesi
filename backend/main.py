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
app = FastAPI(title="Anomali Tespit API", version="3.0")

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

MODEL_PATH = os.path.join(os.path.dirname(__file__), "model", "anomaly_model.pkl")
FEATURES_PATH = os.path.join(os.path.dirname(__file__), "model", "model_features.pkl")
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
    print(f"✅ Model ve Özellikler yüklendi")
except Exception as e:
    print(f"❌ Model yükleme hatası: {e}")
    model = None
    feature_columns = []

# ----------------------------------------
# YARDIMCI FONKSİYONLAR
# ----------------------------------------
def get_risk_level(score: float) -> str:
    """Risk skoruna göre seviye belirleme."""
    if score >= 75: return "Kritik"
    elif score >= 50: return "Yüksek"
    elif score >= 30: return "Orta"
    else: return "Düşük"

def save_to_csv(row_data: dict):
    """CSV’ye güvenli şekilde kaydet."""
    columns = ["Tarih", "User_ID", "Kategori", "Miktar", "Risk", "Risk_Skoru", "Tahmin"]
    df_new = pd.DataFrame([row_data], columns=columns)
    try:
        if not os.path.exists(LOG_PATH):
            df_new.to_csv(LOG_PATH, index=False, encoding="utf-8-sig")
        else:
            df_new.to_csv(LOG_PATH, mode='a', index=False, header=False, encoding="utf-8-sig")
    except Exception as e:
        print(f"⚠️ CSV Yazma Hatası: {e}")

# ----------------------------------------
# ENDPOINTS
# ----------------------------------------
@app.get("/")
def home():
    return {"status": "active", "log": LOG_PATH}

@app.post("/predict")
async def predict(data: dict = Body(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model dosyası eksik.")
    
    try:
        # 1. Veri Tiplerini Düzenle
        yas = int(data.get("yas", data.get("Age", 0)))
        gelir = float(data.get("aylik_gelir", data.get("Income", 0)))
        tutar = float(data.get("harcama_tutari", data.get("Amount", 0)))
        kategori = str(data.get("kategori", "Diger"))
        gelir_grubu = str(data.get("gelir_grubu", "Orta"))
        u_id = int(data.get("kullanici_id", data.get("User_ID", 1)))

        # 2. Model Girdisini Hazırla
        input_dict = {"Age": yas, "Income": gelir, "Amount": tutar}
        input_df = pd.DataFrame([input_dict])

        # One-hot encoding
        cat_col = f"Category_{kategori}"
        income_col = f"Income_Group_{gelir_grubu}"
        for col in feature_columns:
            if col == cat_col or col == income_col:
                input_df[col] = 1
            elif col not in input_df.columns:
                input_df[col] = 0
        
        input_df = input_df[feature_columns]

        # 3. Tahmin ve Skor Hesaplama
        prediction = model.predict(input_df)[0]
        try:
            raw_score = model.decision_function(input_df)[0]
            risk_score = round(max(0, min(100, (0.5 - raw_score) * 100)), 2)
        except:
            risk_score = 50.0  # decision_function yoksa orta risk ver

        # 4. Uçuk değerler için zorunlu risk
        if tutar > (gelir * 1.5) or tutar > 50000:
            risk_score = max(risk_score, 85.0)
            prediction = -1

        # 5. Risk seviyesi ve tahmin
        risk_level = get_risk_level(risk_score)
        tahmin_metni = "Anomali" if prediction == -1 else ("Anomali" if prediction == 1 else "Normal")

        # 6. CSV Kayıt
        csv_row = {
            "Tarih": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "User_ID": u_id,
            "Kategori": kategori,
            "Miktar": tutar,
            "Risk": risk_level,
            "Risk_Skoru": risk_score,
            "Tahmin": tahmin_metni
        }
        save_to_csv(csv_row)

        # 7. Flutter uyumlu yanıt
        return {
            "tahmin": tahmin_metni,
            "risk_skoru": risk_score,
            "risk": risk_level,
            "risk_seviyesi": risk_level,
            "kategori": kategori,
            "harcama_tutari": tutar,
            "tarih": datetime.now().strftime("%d.%m.%Y %H:%M"),
            "aciklama": "Sıra dışı işlem saptandı!" if tahmin_metni=="Anomali" else "İşlem güvenli görünüyor.",
            "analiz_notu": "Kritik seviyede anomali tespiti!" if risk_score >= 75 else "Düzenli işlem."
        }
    except Exception as e:
        print(f"🔥 Hata: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history")
def get_history():
    """Geçmiş işlemleri getirir, eksik verileri tamamlar."""
    try:
        if not os.path.exists(LOG_PATH):
            return []
        df = pd.read_csv(LOG_PATH, encoding="utf-8-sig", dtype=str, on_bad_lines='skip')
        
        # Eksik kolonları ekle
        for col in ["Tarih","User_ID","Kategori","Miktar","Risk","Risk_Skoru","Tahmin"]:
            if col not in df.columns:
                df[col] = None

        # Flutter uyumlu isimlendirme
        df_renamed = df.rename(columns={
            "Tarih": "tarih",
            "Kategori": "kategori",
            "Miktar": "harcama_tutari",
            "Risk": "risk_seviyesi",
            "Risk_Skoru": "risk_skoru",
            "Tahmin": "tahmin"
        })
        
        records = df_renamed.replace({np.nan: None}).to_dict(orient="records")
        for r in records:
            r["risk_durumu"] = r.get("risk_seviyesi")
            r["risk"] = r.get("risk_seviyesi")
            r["analiz_notu"] = f"Geçmiş işlem analizi: {r.get('tahmin')}"
            
        return records
    except Exception as e:
        print(f"⚠️ Geçmiş Hatası: {e}")
        return []

# ----------------------------------------
# Uvicorn ile çalıştırma
# ----------------------------------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)