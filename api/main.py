from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from deep_translator import GoogleTranslator

app = FastAPI()

class TranslationRequest(BaseModel):
    text: str
    source: str = "ml"
    target: str = "en"

@app.post("/translate")
async def translate_text(req: TranslationRequest):
    try:
        translated = GoogleTranslator(source=req.source, target=req.target).translate(req.text)
        return {"translatedText": translated}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/awake")
async def awake_server():
    return {"status": "awaked"}
