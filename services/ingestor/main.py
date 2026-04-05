from fastapi import FastAPI

app = FastAPI()

# This is what the Gateway is currently sending
@app.get("/ingest")
async def ingest_root():
    return {
        "message": "SuperNOVA Ingestor is Live",
        "status": "Ready",
        "version": "v1.0.1"
    }

@app.get("/ingest/health")
async def health():
    return {"status": "healthy"}

# Standard root as a fallback
@app.get("/")
async def root():
    return {"message": "Ingestor Service Root"}
