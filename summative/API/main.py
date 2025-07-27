import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from fastapi.middleware.cors import CORSMiddleware
import joblib
import os
from sklearn.preprocessing import LabelEncoder, StandardScaler

MODEL_PATH = "best_random_forest_model.pkl" 
SCALER_PATH = "scaler.pkl" 
LABEL_ENCODER_PATH = "label_encoder_country.pkl" 

model = None
scaler = None
label_encoder_country = None

try:
    model = joblib.load(MODEL_PATH)
    print(f"Successfully loaded model from {MODEL_PATH}")
except FileNotFoundError:
    print(f"WARNING: Model file not found at {MODEL_PATH}. Prediction will fail.")

try:
    scaler = joblib.load(SCALER_PATH)
    label_encoder_country = joblib.load(LABEL_ENCODER_PATH)
    print("Successfully loaded pre-fitted scaler and label encoder.")
except FileNotFoundError:
    print("WARNING: Fitted scaler or label encoder not found. Using new instances.")
    print("         For production, ensure these are saved from training and loaded here.")
    scaler = StandardScaler()
    label_encoder_country = LabelEncoder()
    
class PredictionInput(BaseModel):
    country: str = Field(..., example="Angola", description="Name of the country in Sub-Saharan Africa")
    year: int = Field(..., ge=1999, le=2100, example=2020, description="Year of the data")
    tourism_receipts: float = Field(..., ge=0, example=150000000.0, description="Tourism receipts in local currency units (LCU)")
    tourism_exports: float = Field(..., ge=0, example=5.5, description="Tourism exports as a percentage of total exports")
    tourism_expenditures: float = Field(..., ge=0, example=3.0, description="Tourism expenditures as a percentage of total expenditures")
    gdp: float = Field(..., ge=0, example=10000000000.0, description="Gross Domestic Product in LCU")
    inflation: float = Field(..., example=5.0, description="Inflation rate (percentage)")
    unemployment: Optional[float] = Field(None, ge=0, le=100, example=7.5, description="Unemployment rate (percentage), can be null")

app = FastAPI(
    title="Tourism Arrivals Prediction API",
    description="API for predicting tourism arrivals in Sub-Saharan African countries using a pre-trained machine learning model.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"], 
)

@app.get("/", summary="API Root / Health Check", response_description="Basic API status message")
async def read_root():
    return {"message": "Welcome to the Tourism Arrivals Prediction API! Visit /docs for the interactive API documentation (Swagger UI)."}

def make_prediction(data: PredictionInput) -> float:

    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded. Cannot make predictions.")
    
    input_df = pd.DataFrame([data.dict()])

    if 'unemployment' in input_df.columns:
        input_df['unemployment'].fillna(0, inplace=True) 
    try:
        if hasattr(label_encoder_country, 'classes_'):
            input_df['country'] = label_encoder_country.transform(input_df['country'])
        else:
            print("WARNING: LabelEncoder was not pre-fitted. Attempting a temporary fit or using placeholder.")
            _dummy_countries_for_le_fit = ['Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Cameroon',
                               'Congo, Dem. Rep.', 'Ethiopia', 'Ghana', 'Kenya', 'Mozambique',
                               'Nigeria', 'South Africa', 'Tanzania', 'Uganda', 'Zambia', 
                               'Zimbabwe', 'Togo', 'Niger', 'Rwanda', 'Senegal', 'Sierra Leone',
                               'Somalia', 'Sudan', 'Eritrea', 'Gabon', 'Gambia', 'Guinea',
                               'Guinea-Bissau', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi',
                               'Mali', 'Mauritania', 'Mauritius', 'Namibia', 'Seychelles',
                               'Tanzania', 'Chad', 'Central African Republic', 'Comoros',
                               'Equatorial Guinea', 'Eswatini', 'Djibouti', 'Burundi']
            label_encoder_country.fit(_dummy_countries_for_le_fit)
            input_df['country'] = label_encoder_country.transform(input_df['country'])
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during country encoding: {e}. Ensure label encoder is correctly loaded and fitted.")

    features_order = ['country', 'year', 'tourism_receipts', 'tourism_exports', 'tourism_expenditures', 'gdp', 'inflation', 'unemployment']
    input_features_df = input_df[features_order]
    try:
        if hasattr(scaler, 'mean_'):
            scaled_input = scaler.transform(input_features_df)
        else:
            print("WARNING: StandardScaler was not pre-fitted. This is CRITICAL for production.")
            scaled_input = input_features_df.values
            raise HTTPException(status_code=500, detail="StandardScaler not correctly loaded. Prediction results will be inaccurate. Ensure 'scaler.pkl' is saved from training and accessible.")

    except HTTPException as e:
        raise e 
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during data scaling: {e}. Ensure scaler is correctly loaded and fitted.")
    prediction = model.predict(scaled_input)[0]
    return prediction

@app.post("/predict", summary="Predict Tourism Arrivals", response_description="Predicted number of tourism arrivals")
async def predict_tourism_arrivals(input_data: PredictionInput):
    try:
        prediction_result = make_prediction(input_data)
        return {"predicted_tourism_arrivals": prediction_result}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed due to an internal error: {e}")