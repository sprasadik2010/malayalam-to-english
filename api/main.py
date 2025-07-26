from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from deep_translator import GoogleTranslator

app = FastAPI()

class TranslationRequest(BaseModel):
    text: str

class TranslationResponse(BaseModel):
    translated_text: str

@app.post("/translate", response_model=TranslationResponse)
def translate_text(request: TranslationRequest):
    try:
        translated = GoogleTranslator(source='malayalam', target='english').translate(request.text)
        return {"translated_text": translated}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
