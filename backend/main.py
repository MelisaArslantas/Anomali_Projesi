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
app = FastAPI(title="Mizan Anomali Tespit API", version="7.0")

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
    print(f"✅ Model ve Özellikler Yüklendi")
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
    except Exception as e:
        print(f"⚠️ CSV Kayıt Hatası: {e}")

# --- ENDPOINTS ---

@app.get("/")
def home():
    return {"status": "active", "project": "Mizan Financial AI", "model_ready": model is not None}

# 🆕 GÜNCELLENEN DASHBOARD İSTATİSTİKLERİ
@app.get("/stats/{u_id}")
async def get_stats(u_id: str):
    if not db:
        raise HTTPException(status_code=500, detail="Firebase bağlantısı yok")
    
    try:
        user_doc = db.collection("users").document(u_id).get()
        if not user_doc.exists:
            return {"name": "Kullanıcı", "income": 0, "count": 0, "avg_risk": 0, "status": "Bilinmiyor"}
        
        user_data = user_doc.to_dict()
        analizler = db.collection("users").document(u_id).collection("analizler").stream()
        
        risk_toplami = 0
        islem_sayisi = 0
        gelir_toplami = 0
        gider_toplami = 0

        for doc in analizler:
            data = doc.to_dict()
            kat = data.get("kategori", "Diğer")
            tutar = data.get("harcama_tutari", 0)

            if kat in ["Maaş", "Gelir"]:
                gelir_toplami += tutar
            else:
                gider_toplami += tutar
                risk_toplami += data.get("risk_skoru", 0)
                islem_sayisi += 1
            
        avg_risk = round(risk_toplami / islem_sayisi, 1) if islem_sayisi > 0 else 0
        
        status_text = "Güvenli"
        if avg_risk >= 60: status_text = "Kritik"
        elif avg_risk >= 35: status_text = "Dikkat"
        
        return {
            "name": user_data.get("name", "Kullanıcı"),
            "income": user_data.get("monthly_income", 0),
            "real_income": gelir_toplami, # O ay girilen toplam maaş
            "total_expense": gider_toplami,
            "count": islem_sayisi,
            "avg_risk": avg_risk,
            "status": status_text
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/predict")
async def predict(data: dict = Body(...)):
    if model is None:
        raise HTTPException(status_code=500, detail="Model yüklü değil.")
    
    try:
        tutar = float(data.get("amount") or data.get("harcama_tutari") or 0.0)
        kategori = str(data.get("category") or data.get("kategori") or "Diğer").strip()
        u_id = str(data.get("userId") or data.get("kullanici_id") or "1")
        
        now = datetime.now()
        
        # 🛡️ MAAŞ/GELİR KORUMASI: Modelin yanılmasını engelle
        if kategori in ["Maaş", "Gelir"]:
            is_anomaly = False
            risk_score = 0.0
            risk_level = "Düşük"
            tahmin_label = "Normal"
            analiz_notu = "Gelir girişi tespit edildi. Bütçenize olumlu yansıdı."
            aciklama = "Maaş/Gelir girişi."
        else:
            # Model Giriş Hazırlığı
            input_row = {col: 0.0 for col in feature_columns}
            input_row['Amount'] = tutar
            input_row['Hour'] = float(now.hour)
            input_row['Is_Night'] = 1.0 if now.hour <= 6 else 0.0
            input_row['Log_Amount'] = np.log1p(tutar)

            cat_key = f"Cat_{kategori}"
            if cat_key in input_row:
                input_row[cat_key] = 1.0
            
            input_df = pd.DataFrame([input_row])[feature_columns]
            
            # Tahmin
            prediction = model.predict(input_df)[0]
            decision_val = model.decision_function(input_df)[0]
            
            risk_score = round(float(np.clip((0.5 - decision_val) * 100, 0, 100)), 1)
            is_anomaly = (prediction == -1)
            risk_level = get_risk_level(risk_score)
            tahmin_label = "Anomali" if is_anomaly else "Normal"
            
            # Tavsiye Motoru
            tavsiyeler = {
                "Gıda & Market": "Market harcamaların limitini aştı. Liste yaparak alışverişe çıkmayı dene!",
                "Dışarıda Yemek": "Dışarıda yemek masrafın yükseldi. Bu hafta evde yemek hazırlamaya ne dersin?",
                "Teknoloji & Elektronik": "Yeni bir cihaz almadan önce gerçekten ihtiyacın var mı diye düşünmelisin.",
                "Eğlence & Hobiler": "Eğlence bütçen bu ay hızlı tükeniyor. Ücretsiz etkinliklere göz atabilirsin.",
                "Kira & Konut": "Barınma giderlerin gelirine göre yüksek. Finansal dengeni gözden geçirmelisin.",
                "Giyim & Aksesuar": "Giyim harcamaların profilinin üzerine çıktı. İhtiyaç listeni kontrol et.",
                "Ulaşım & Akaryakıt": "Ulaşım maliyetlerin arttı. Alternatif güzergahları değerlendirebilirsin."
            }
            analiz_notu = tavsiyeler.get(kategori, "Finansal okuryazarlık içeriklerine göz atın.") if is_anomaly else "Düzenli harcama alışkanlığı."
            aciklama = "Şüpheli harcama! Profil limitlerinizi aşıyor." if is_anomaly else "İşlem normal."

        res_data = {
            "tarih": now.strftime("%d.%m.%Y %H:%M"),
            "kullanici_id": u_id,
            "kategori": kategori,
            "harcama_tutari": tutar, 
            "risk_seviyesi": risk_level,
            "risk_skoru": risk_score,
            "tahmin": tahmin_label,
            "aciklama": aciklama,
            "analiz_notu": analiz_notu
        }
        
        save_to_csv(res_data)

        if db:
            try:
                db.collection("users").document(u_id).collection("analizler").add(res_data)
            except Exception as fe:
                print(f"⚠️ Firestore Hatası: {fe}")

        return res_data

    except Exception as e:
        print(f"🔥 Hata: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/history/{u_id}")
async def get_history(u_id: str):
    if db:
        try:
            docs = db.collection("users").document(u_id).collection("analizler").order_by("tarih", direction=firestore.Query.DESCENDING).stream()
            return [doc.to_dict() for doc in docs]
        except Exception as e:
            print(f"⚠️ Firestore Geçmiş Hatası: {e}")
    return []

@app.delete("/delete-transaction/{u_id}/{tarih}")
async def delete_transaction(u_id: str, tarih: str):
    try:
        if db:
            docs = db.collection("users").document(u_id).collection("analizler").where("tarih", "==", tarih).stream()
            for doc in docs:
                doc.reference.delete()
        return {"status": "success", "message": "İşlem silindi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)