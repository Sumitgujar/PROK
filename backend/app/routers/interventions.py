from fastapi import APIRouter, Depends

from app.core.dependencies import require_role
from app.models.intervention import InterventionCreate, InterventionUpdate
from app.services import intervention as svc

router = APIRouter(prefix="/interventions", tags=["interventions"])


@router.post("/", status_code=201)
async def create_intervention(data: InterventionCreate, current_user=Depends(require_role("teacher", "admin"))):
    return await svc.create_intervention(
        student_id=data.student_id,
        issue=data.issue,
        recommendation=data.recommendation,
        action=data.action,
        status=data.status,
        actor_id=str(current_user["_id"]),
        outcome=data.outcome,
    )


@router.put("/{intervention_id}")
async def update_intervention(intervention_id: str, data: InterventionUpdate, current_user=Depends(require_role("teacher", "admin"))):
    return await svc.update_intervention(
        intervention_id=intervention_id,
        updates=data.dict(exclude_none=True),
        actor_id=str(current_user["_id"]),
    )


@router.get("/")
async def list_interventions(student_id: str | None = None, status: str | None = None, current_user=Depends(require_role("teacher", "admin"))):
    return await svc.list_interventions(student_id=student_id, status=status)


@router.get("/{intervention_id}")
async def get_intervention(intervention_id: str, current_user=Depends(require_role("teacher", "admin"))):
    return await svc.get_intervention(intervention_id)
