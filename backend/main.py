from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
import joblib
import pandas as pd
import numpy as np
import os
from datetime import datetime

# --- FIREBASE BAĞLANTISI ---
import firebase_admin
from firebase_admin import credentials, firestore

try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase Bağlantısı Başarılı")
except Exception as e:
    print(f"❌ Firebase Başlatılamadı: {e}")
    db = None

# --- FastAPI YAPILANDIRMASI ---
app = FastAPI(title="Anomali Tespit API", version="6.5")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- PATH AYARLARI ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__)) 
MODEL_PATH = os.path.join(BASE_DIR, "model", "anomaly_model.pkl")
FEATURES_PATH = os.path.join(BASE_DIR, "model", "model_features.pkl")
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LOG_PATH = os.path.join(DATASET_DIR, "islem_gecmisi.csv")

if not os.path.exists(DATASET_DIR):
    os.makedirs(DATASET_DIR)

# --- MODEL YÜKLEME ---
try:
    model = joblib.load(MODEL_PATH)
    feature_columns = joblib.load(FEATURES_PATH)
    print(f"✅ Model ve Özellikler Yüklendi: {len(feature_columns)} sütun")
except Exception as e:
    print(f"❌ Model yükleme hatası: {e}")
    model = None
    feature_columns = []

# --- YARDIMCI FONKSİYONLAR ---
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
        print("💾 Yerel CSV güncellendi.")
    except Exception as e:
        print(f"⚠️ CSV Kayıt Hatası: {e}")

# --- ENDPOINTS ---

@app.get("/")
def home():
    return {"status": "active", "firebase": db is not None, "model": model is not None}

# 🆕 YENİ: DASHBOARD İSTATİSTİKLERİ ENDPOINT'İ
@app.get("/stats/{u_id}")
async def get_stats(u_id: str):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase bağlantısı yok")
    
    try:
        # 1. Kullanıcı dökümanını al (İsim ve Gelir için)
        user_doc = db.collection("users").document(u_id).get()
        if not user_doc.exists:
            return {"name": "Kullanıcı", "income": 0, "count": 0, "avg_risk": 0, "status": "Bilinmiyor"}
        
        user_data = user_doc.to_dict()
        
        # 2. Analizler alt koleksiyonundan verileri topla
        analizler = db.collection("users").document(u_id).collection("analizler").stream()
        
        risk_toplami = 0
        sayac = 0
        for doc in analizler:
            data = doc.to_dict()
            risk_toplami += data.get("risk_skoru", 0)
            sayac += 1
            
        avg_risk = round(risk_toplami / sayac, 1) if sayac > 0 else 0
        
        # Risk durumuna göre metin belirle
        status_text = "Güvenli"
        if avg_risk >= 60: status_text = "Kritik"
        elif avg_risk >= 35: status_text = "Dikkat"
        
        return {
            "name": user_data.get("name", "Kullanıcı"),
            "income": user_data.get("monthly_income", 0),
            "count": sayac,
            "avg_risk": avg_risk,
            "status": status_text
        }
    except Exception as e:
        print(f"🔥 Stats Hatası: {e}")
        return {"error": str(e)}

@app.post("/predict")
async def predict(data: dict = Body(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model yüklü değil.")
    
    try:
        tutar = float(data.get("amount") or data.get("harcama_tutari") or 0.0)
        kategori = str(data.get("category") or data.get("kategori") or "Diğer")
        u_id = str(data.get("userId") or data.get("kullanici_id") or "1")
        
        now = datetime.now()
        
        input_row = {col: 0.0 for col in feature_columns}
        input_row['Amount'] = tutar
        input_row['Hour'] = float(now.hour)
        input_row['Is_Night'] = 1.0 if now.hour <= 6 else 0.0
        input_row['Log_Amount'] = np.log1p(tutar)

        cat_key = f"Cat_{kategori}"
        if cat_key in input_row:
            input_row[cat_key] = 1.0
        
        input_df = pd.DataFrame([input_row])[feature_columns]
        prediction = model.predict(input_df)[0]
        decision_val = model.decision_function(input_df)[0]
        
        risk_score = round(float(np.clip((0.5 - decision_val) * 100, 0, 100)), 1)
        is_anomaly = (prediction == -1)
        risk_level = get_risk_level(risk_score)

        res_data = {
            "tarih": now.strftime("%d.%m.%Y %H:%M"),
            "kullanici_id": u_id,
            "kategori": kategori,
            "harcama_tutari": tutar, 
            "risk_seviyesi": risk_level,
            "risk_skoru": risk_score,
            "tahmin": "Anomali" if is_anomaly else "Normal"
        }
        
        tavsiyeler = {
            "Gıda & Market": "Market harcamaların limitini aştı. Liste yaparak alışverişe çıkmayı dene!",
            "Dışarıda Yemek": "Dışarıda yemek masrafın yükseldi. Bu hafta evde yemek hazırlamaya ne dersin?",
            "Teknoloji & Elektronik": "Yeni bir cihaz almadan önce gerçekten ihtiyacın var mı diye düşünmelisin.",
            "Eğlence & Hobiler": "Eğlence bütçen bu ay hızlı tükeniyor. Ücretsiz etkinliklere göz atabilirsin.",
            "Kira & Konut": "Barınma giderlerin gelirine göre yüksek. Finansal dengeni gözden geçirmelisin.",
            "Giyim & Aksesuar": "Giyim harcamaların profilinin üzerine çıktı. İhtiyaç listeni kontrol et.",
            "Ulaşım & Akaryakıt": "Ulaşım maliyetlerin arttı. Alternatif güzergahları değerlendirebilirsin."
        }
        ozel_tavsiye = tavsiyeler.get(kategori, "Gelişim Merkezindeki finansal okuryazarlık içeriklerine göz atın.")

        save_to_csv(res_data)

        if db:
            try:
                db.collection("users").document(u_id).collection("analizler").add(res_data)
                print(f"☁️ Firestore Kaydı Başarılı: {u_id}")
            except Exception as fe:
                print(f"⚠️ Firestore Hatası: {fe}")

        return {
            **res_data,
            "aciklama": "Şüpheli harcama! Profil limitlerinizi aşıyor." if is_anomaly else "İşlem normal.",
            "analiz_notu": ozel_tavsiye if is_anomaly else "Düzenli harcama alışkanlığı."
        }
    except Exception as e:
        print(f"🔥 Hata: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history/{u_id}")
async def get_history(u_id: str):
    if db:
        try:
            docs = db.collection("users").document(u_id).collection("analizler").order_by("tarih", direction=firestore.Query.DESCENDING).stream()
            history = [doc.to_dict() for doc in docs]
            if history: return history
        except Exception as e:
            print(f"⚠️ Firestore Geçmiş Hatası: {e}")

    try:
        if not os.path.exists(LOG_PATH): return []
        df = pd.read_csv(LOG_PATH, encoding="utf-8-sig", dtype={'kullanici_id': str})
        user_df = df[df['kullanici_id'] == u_id]
        return user_df.replace({np.nan: None}).to_dict(orient="records")[::-1]
    except Exception as e:
        return []

@app.delete("/delete-transaction/{u_id}/{tarih}")
async def delete_transaction(u_id: str, tarih: str):
    try:
        if db:
            docs = db.collection("users").document(u_id).collection("analizler").where("tarih", "==", tarih).stream()
            for doc in docs:
                doc.reference.delete()
        
        if os.path.exists(LOG_PATH):
            df = pd.read_csv(LOG_PATH, encoding="utf-8-sig", dtype={'kullanici_id': str})
            df = df[~((df['kullanici_id'] == u_id) & (df['tarih'] == tarih))]
            df.to_csv(LOG_PATH, index=False, encoding="utf-8-sig")
            
        return {"status": "success", "message": "İşlem silindi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)