from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from google.cloud import translate_v2 as translate
from google.oauth2 import service_account
import os, json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with your app's domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TranslationRequest(BaseModel):
    text: str

class TranslationResponse(BaseModel):
    translated_text: str

# Load credentials from env variable
credentials_info = json.loads(os.getenv("GOOGLE_CREDENTIALS_JSON"))
credentials = service_account.Credentials.from_service_account_info(credentials_info)
translate_client = translate.Client(credentials=credentials)

@app.post("/translate", response_model=TranslationResponse)
def translate_text(request: TranslationRequest):
    try:
        result = translate_client.translate(
            request.text,
            source_language='ml',
            target_language='en'
        )
        return {"translated_text": result['translatedText']}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Translation failed: " + str(e))
