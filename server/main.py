import hmac
import hashlib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"])

# Not an ideal way of doing this but it'll work for this project
SECRET_KEY = b"ea272416bf3266c26897c25811adf35e87bd6ff63252f17a0a4d2d176bab056f"

# ------------Models-----------------
class SaveRequest(BaseModel):
    data: str  # This will be the string version of the Godot save file

class VerifyRequest(BaseModel):
        data: str
        hmac: str

# --------- Endpoints ----------------
# Generates HMAC signature
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

# Checks provided HMAC against a newly generated one (expected) to handle verification and validation of save
@app.post("/verify-hmac")
async def verify_hmac(request: VerifyRequest):
        try:
                expected_signature = hmac.new(
                        SECRET_KEY,
                        request.data.encode('utf-8'),
                        hashlib.sha256
                ).hexdigest()

                # Compare given signatures server side
                is_valid = hmac.compare_digest(expected_signature, request.hmac)

                return {"valid": is_valid}
        except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))

# To test if the server is alive
@app.get("/health")
async def health_check():
    return {"status": "online"}
