from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

app = FastAPI()

class TranslationRequest(BaseModel):
    text: str
    source: str = "ml"
    target: str = "en"

@app.post("/translate")
async def translate_text(req: TranslationRequest):
    try:
        url = "https://translate.googleapis.com/translate_a/single"
        params = {
            "client": "gtx",
            "sl": req.source,
            "tl": req.target,
            "dt": "t",
            "q": req.text
        }
        response = requests.get(url, params=params)

        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.text)

        result = response.json()
        translated_text = result[0][0][0] if result and result[0] else ""

        return {"translatedText": translated_text}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/awake")
async def awake_server():
    return {"status": "awaked"}
