from fastapi import APIRouter, Depends, UploadFile, File, Form
from app.services import document as svc
from app.core.dependencies import get_current_user, require_role

router = APIRouter(prefix="/documents", tags=["documents"])

@router.post("/upload", status_code=201)
async def upload(
    file: UploadFile = File(...),
    doc_type: str = Form(...),
    title: str = Form(...),
    description: str = Form(""),
    current_user=Depends(require_role("student")),
):
    return await svc.upload_document(file, current_user["college_id"], doc_type, title, description)

@router.get("/my")
async def my_documents(current_user=Depends(require_role("student"))):
    return await svc.get_student_documents(current_user["college_id"])

@router.get("/all")
async def all_documents(current_user=Depends(require_role("admin"))):
    return await svc.get_all_documents()

@router.post("/{doc_id}/verify")
async def verify(doc_id: str, body: dict = {}, current_user=Depends(require_role("admin"))):
    return await svc.review_document(doc_id, str(current_user["_id"]), "VERIFIED", body.get("review_note"))

@router.post("/{doc_id}/reject")
async def reject(doc_id: str, body: dict = {}, current_user=Depends(require_role("admin"))):
    return await svc.review_document(doc_id, str(current_user["_id"]), "REJECTED", body.get("review_note"))
