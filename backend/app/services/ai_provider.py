from __future__ import annotations

import asyncio
import json
import os
import urllib.error
import urllib.request
from abc import ABC, abstractmethod


AI_TIMEOUT_SECONDS = int(os.getenv("AI_TIMEOUT_SECONDS", "15") or "15")
AI_PROVIDER_URL = os.getenv("AI_PROVIDER_URL", "")
AI_PROVIDER_API_KEY = os.getenv("AI_PROVIDER_API_KEY", "")
AI_MODEL = os.getenv("AI_MODEL", "")
LOCAL_AI_URL = os.getenv("LOCAL_AI_URL", "")
LOCAL_AI_MODEL = os.getenv("LOCAL_AI_MODEL", "")


class AiProviderError(Exception):
    pass


class BaseAiProvider(ABC):
    name = "base"

    @abstractmethod
    async def generate_guidance(self, payload: dict) -> dict:
        raise NotImplementedError


class HttpAiProvider(BaseAiProvider):
    name = "http"

    def __init__(self, *, name: str, url: str, model: str | None = None, api_key: str | None = None):
        self.name = name
        self.url = url
        self.model = model
        self.api_key = api_key

    async def generate_guidance(self, payload: dict) -> dict:
        return await asyncio.to_thread(self._sync_generate, payload)

    def _sync_generate(self, payload: dict) -> dict:
        body = json.dumps({
            "model": self.model,
            "instruction": (
                "Use only the provided PROK facts. Do not invent attendance, documents, scholarships, "
                "courses, eligibility, or policies. Return strict JSON with keys: guidance, warnings."
            ),
            "question": payload.get("question"),
            "intent": payload.get("intent"),
            "facts": payload.get("facts"),
            "fallback_answer": payload.get("fallback_answer"),
        }).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        request = urllib.request.Request(self.url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=AI_TIMEOUT_SECONDS) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.URLError as exc:
            raise AiProviderError(str(exc)) from exc
        except Exception as exc:
            raise AiProviderError(str(exc)) from exc

        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            data = {"guidance": raw}

        if isinstance(data, dict) and isinstance(data.get("choices"), list) and data["choices"]:
            message = data["choices"][0].get("message", {})
            content = message.get("content") if isinstance(message, dict) else None
            if content:
                try:
                    parsed = json.loads(content)
                    if isinstance(parsed, dict):
                        data = parsed
                except json.JSONDecodeError:
                    data = {"guidance": content}

        if not isinstance(data, dict):
            raise AiProviderError("AI provider returned an invalid payload")
        return data


class DeterministicFallbackProvider(BaseAiProvider):
    name = "deterministic_fallback"

    async def generate_guidance(self, payload: dict) -> dict:
        return {"guidance": "", "warnings": []}


class AiProviderManager:
    def __init__(self, providers: list[BaseAiProvider] | None = None):
        self.providers = providers or self._build_default_chain()

    def _build_default_chain(self) -> list[BaseAiProvider]:
        providers: list[BaseAiProvider] = []
        if AI_PROVIDER_URL:
            providers.append(
                HttpAiProvider(
                    name="configured_ai",
                    url=AI_PROVIDER_URL,
                    model=AI_MODEL,
                    api_key=AI_PROVIDER_API_KEY,
                )
            )
        if LOCAL_AI_URL:
            providers.append(
                HttpAiProvider(
                    name="local_ai",
                    url=LOCAL_AI_URL,
                    model=LOCAL_AI_MODEL,
                )
            )
        providers.append(DeterministicFallbackProvider())
        return providers

    async def generate_guidance(self, payload: dict) -> dict:
        errors: list[str] = []
        for provider in self.providers:
            try:
                result = await provider.generate_guidance(payload)
                result["provider"] = provider.name
                result["provider_errors"] = errors
                return result
            except AiProviderError as exc:
                errors.append(f"{provider.name}: {exc}")
                continue
        return {
            "guidance": "",
            "warnings": [],
            "provider": "deterministic_fallback",
            "provider_errors": errors,
        }
