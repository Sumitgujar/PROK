from pydantic import BaseModel
from typing import Optional


class RecoverySimulationRequest(BaseModel):
    attended_classes: int
    total_classes: int


class InterventionDecisionNote(BaseModel):
    note: Optional[str] = "PROK recommends and explains. Humans make decisions."
