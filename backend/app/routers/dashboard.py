from fastapi import APIRouter, Depends
from app.core.dependencies import require_role
from app.services import attendance as att_svc, document as doc_svc, scholarship as sch_svc, course as crs_svc, notification as not_svc

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

@router.get("/student")
async def student_dashboard(current_user=Depends(require_role("student"))):
    sid = current_user["college_id"]
    uid = str(current_user["_id"])
    attendance_summary = await att_svc.get_student_summary(sid)
    overall = round(sum(s["percentage"] for s in attendance_summary) / len(attendance_summary)) if attendance_summary else 0
    docs = await doc_svc.get_student_documents(sid)
    scholarships = await sch_svc.get_scholarships()
    apps = await sch_svc.get_student_applications(sid)
    applied_ids = {a["scholarship_id"] for a in apps}
    available = [s for s in scholarships if s["_id"] not in applied_ids]
    recs = await crs_svc.get_recommendations(sid)
    notes = await not_svc.get_notifications(uid)
    unread = sum(1 for n in notes if not n.get("is_read"))
    return {
        "attendance": {"overall_percentage": overall, "courses": attendance_summary},
        "documents": {"total": len(docs), "verified": sum(1 for d in docs if d["status"]=="VERIFIED"),
            "under_review": sum(1 for d in docs if d["status"]=="UNDER_REVIEW"),
            "rejected": sum(1 for d in docs if d["status"]=="REJECTED")},
        "scholarships": {"available": len(available), "applied": len(apps)},
        "courses": {"recommendations": recs[:3]},
        "notifications": {"unread_count": unread},
    }
