"""ASTRA's Gemini gateway. Run with: uvicorn main:app --reload --port 8000."""
import asyncio
import json
import os
from typing import Any

from fastapi import FastAPI, HTTPException
from google import genai
# pyrefly: ignore [missing-import]
from google.genai import types
from pydantic import BaseModel, Field

app = FastAPI(title="ASTRA AI Gateway", version="1.0.0")

_raw_model = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
GEMINI_MODEL = "gemini-2.0-flash" if "flash-latest" in _raw_model else _raw_model


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


class ExtractRequest(BaseModel):
    text: str = Field(min_length=1, max_length=12000)
    source: str = Field(pattern="^(prompt|gmail)$")


async def completion(system_instruction: str, prompt: str, *, json_mode: bool = False) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(503, "AI service is not configured.")

    models_to_try = [GEMINI_MODEL]
    for fallback in ["gemini-2.0-flash", "gemini-1.5-flash"]:
        if fallback not in models_to_try:
            models_to_try.append(fallback)

    last_exc = None
    for model_name in models_to_try:
        try:
            client = genai.Client(api_key=api_key)
            config = types.GenerateContentConfig(
                system_instruction=system_instruction,
                max_output_tokens=700,
                response_mime_type="application/json" if json_mode else "text/plain",
            )
            response = await asyncio.to_thread(
                client.models.generate_content,
                model=model_name,
                contents=prompt,
                config=config,
            )
            content = (response.text or "").strip()
            if content:
                return content
        except Exception as exc:
            last_exc = exc

    raise HTTPException(502, f"Gemini service temporarily unavailable: {last_exc}")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "provider": "gemini", "model": GEMINI_MODEL}


@app.post("/v1/assistant/chat")
async def chat(request: ChatRequest) -> dict[str, str]:
    reply = await completion(
        "You are ASTRA, a calm, practical life scheduler. Respond naturally, clearly, and concisely. Never claim actions you did not take.",
        request.message,
    )
    return {"reply": reply}


@app.post("/v1/assistant/extract-task")
async def extract_task(request: ExtractRequest) -> dict[str, Any]:
    schema = """Return a JSON object only with: is_task (boolean), title (string), event_type (application|exam|meeting|reminder), company_name (string|null), role (string|null), location (string|null), stipend (string|null), requirements (string|null), deadline (ISO-8601 string|null), application_link (string|null), action_items (string|null), priority (LOW|MEDIUM|HIGH|URGENT)."""
    raw = await completion(
        f"Extract an actionable task from the supplied {request.source} content. {schema}",
        request.text,
        json_mode=True,
    )
    try:
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[-1]
            if raw.rstrip().endswith("```"):
                raw = raw.rstrip()[:-3]
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError("Response is not an object")
        return data
    except (json.JSONDecodeError, ValueError) as exc:
        raise HTTPException(502, "AI provider returned invalid task data.") from exc
