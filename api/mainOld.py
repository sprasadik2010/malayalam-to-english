from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from google.cloud import translate_v2 as translate
from google.oauth2 import service_account
import os, json

app = FastAPI()

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/response models
class TranslationRequest(BaseModel):
    text: str

class TranslationResponse(BaseModel):
    translated_text: str

# Load Google Translate credentials from env var
credentials_info = json.loads(os.getenv("GOOGLE_CREDENTIALS_JSON"))
credentials = service_account.Credentials.from_service_account_info(credentials_info)
translate_client = translate.Client(credentials=credentials)

# Translation endpoint
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

# ✅ Server start point for Cloud Run
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))  # Cloud Run expects port 8080
    uvicorn.run(app, host="0.0.0.0", port=port)
