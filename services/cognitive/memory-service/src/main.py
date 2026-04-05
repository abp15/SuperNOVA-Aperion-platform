from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import redis
import os
import json

app = FastAPI(title="SuperNOVA Memory Service")

# Connect to Redis using the IP from Terraform
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
r = redis.Redis(host=REDIS_HOST, port=6379, db=0, decode_responses=True)

class Message(BaseModel):
    role: str # 'user' or 'assistant'
    content: str

class SessionMemory(BaseModel):
    session_id: str
    messages: list[Message]

@app.post("/memory/{session_id}")
async def save_memory(session_id: str, message: Message):
    # Retrieve existing history, append new message, and save
    history_raw = r.get(session_id)
    history = json.loads(history_raw) if history_raw else []
    
    history.append(message.dict())
    
    # Keep only the last 20 messages to save tokens/memory
    r.set(session_id, json.dumps(history[-20:]))
    return {"status": "memory_updated", "count": len(history)}

@app.get("/memory/{session_id}", response_model=list[Message])
async def get_memory(session_id: str):
    history_raw = r.get(session_id)
    if not history_raw:
        return []
    return json.loads(history_raw)

@app.delete("/memory/{session_id}")
async def clear_memory(session_id: str):
    r.delete(session_id)
    return {"status": "memory_cleared"}
# SuperNOVA Trigger: Sat Apr  4 17:52:57 PDT 2026
# Infrastructure Synced: Sat Apr  4 18:03:34 PDT 2026
# Triggering full CI/CD deployment
# triggering the new declarative pipeline
