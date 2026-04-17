import hmac
import hashlib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddlware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# ⚠️ CHANGE THIS: In a real production environment, 
# you'd load this from an environment variable.
SECRET_KEY = b"ea272416bf3266c26897c25811adf35e87bd6ff63252f17a0a4d2d176bab056f"

class SaveRequest(BaseModel):
    data: str  # This will be the string version of your Godot save file

@app.post("/generate-hmac")
async def generate_hmac(request: SaveRequest):
    try:
        # Create the HMAC-SHA256 hash
        # We encode the string data to bytes before hashing
        signature = hmac.new(
            SECRET_KEY, 
            request.data.encode('utf-8'), 
            hashlib.sha256
        ).hexdigest()
        
        return {"hmac": signature}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# To test if the server is alive
@app.get("/health")
async def health_check():
    return {"status": "online"}
