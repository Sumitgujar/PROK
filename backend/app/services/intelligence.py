from __future__ import annotations

from datetime import datetime, timezone
from bson import ObjectId

from app.db.connection import get_database
from app.services.intelligence_rules import (
    build_recovery_projection,
    calculate_consecutive_absences,
    calculate_percentage,
    calculate_recent_trend,
    determine_risk_level,
    evaluate_scholarship_match,
    is_attended,
    recommend_course,
)


async def _load_course(db, course_id: str):
    try:
        return await db.courses.find_one({"_id": ObjectId(course_id)})
    except Exception:
        return await db.courses.find_one({"_id": course_id})


async def get_attendance_risk(student_college_id: str) -> dict:
    db = get_database()
    enrollments = await db.enrollments.find({"student_college_id": student_college_id}).to_list(None)

    subject_attendance = []
    all_statuses: list[str] = []
    all_events: list[tuple[str, str]] = []
    total_attended = 0
    total_sessions = 0

    for enrollment in enrollments:
        course_id = enrollment.get("course_id")
        if not course_id:
            continue
        course = await _load_course(db, course_id)
        if not course:
            continue

        sessions = await db.attendance_sessions.find({"course_id": course_id}).sort("date", 1).to_list(None)
        subject_statuses: list[str] = []
        subject_attended = 0

        for session in sessions:
            record = await db.attendance_records.find_one({
                "session_id": str(session["_id"]),
                "student_id": student_college_id,
            })
            status = (record or {}).get("status", "absent")
            subject_statuses.append(status)
            all_statuses.append(status)
            all_events.append((str(session.get("date", "")), status))
            total_sessions += 1
            if is_attended(status):
                subject_attended += 1
                total_attended += 1

        subject_attendance.append({
            "course_id": course_id,
            "course_code": course.get("course_code", ""),
            "course_title": course.get("title", ""),
            "attended_classes": subject_attended,
            "total_classes": len(sessions),
            "percentage": calculate_percentage(subject_attended, len(sessions)),
        })

    all_events.sort(key=lambda item: item[0])
    ordered_statuses = [status for _, status in all_events] if all_events else all_statuses
    trend = calculate_recent_trend(ordered_statuses)
    consecutive_absences = calculate_consecutive_absences(ordered_statuses)
    overall_attendance = calculate_percentage(total_attended, total_sessions)
    risk = determine_risk_level(
        overall_attendance=overall_attendance,
        subject_attendance=subject_attendance,
        trend_label=trend["label"],
        consecutive_absences=consecutive_absences,
    )

    return {
        "calculation_method": "rule_based",
        "note": "Transparent attendance rules are used here. This is not a trained ML prediction.",
        "overall_attendance": overall_attendance,
        "overall_attended_classes": total_attended,
        "overall_total_classes": total_sessions,
        "subject_attendance": subject_attendance,
        "recent_attendance_trend": trend,
        "consecutive_absences": consecutive_absences,
        "risk_level": risk["risk_level"],
        "reasons": risk["reasons"],
        "risk_score": risk["score"],
    }


async def get_recovery_simulation(student_college_id: str) -> dict:
    report = await get_attendance_risk(student_college_id)
    return build_recovery_projection(
        attended=report["overall_attended_classes"],
        total=report["overall_total_classes"],
    )


async def get_scholarship_intelligence(student_college_id: str) -> dict:
    db = get_database()
    student = await db.students.find_one({"college_id": student_college_id}) or {"college_id": student_college_id}
    scholarships = await db.scholarships.find({"is_active": {"$ne": False}}).to_list(None)
    documents = await db.documents.find({"student_id": student_college_id}).to_list(None)
    verified_doc_types = [doc.get("doc_type") for doc in documents if doc.get("status") == "VERIFIED"]

    matches = []
    for scholarship in scholarships:
        evaluation = evaluate_scholarship_match(student, scholarship, verified_doc_types)
        if evaluation["match_level"] == "REVIEW_NEEDED":
            continue
        matches.append({
            "scholarship_id": str(scholarship["_id"]),
            "name": scholarship.get("name", ""),
            "provider": scholarship.get("provider", ""),
            "amount": scholarship.get("amount"),
            "currency": scholarship.get("currency", "USD"),
            "deadline": scholarship.get("deadline"),
            **evaluation,
        })

    matches.sort(key=lambda item: item.get("score", 0), reverse=True)
    return {
        "calculation_method": "rule_based",
        "note": "Based on the available information, these are explainable scholarship matches and not guarantees of eligibility.",
        "student_profile": {
            "department": student.get("department"),
            "cgpa": student.get("cgpa"),
            "skills": student.get("skills", []),
            "interests": student.get("interests", []),
            "career_goals": student.get("career_goals", []),
        },
        "document_status_summary": {
            "verified": sorted({doc.get("doc_type") for doc in documents if doc.get("status") == "VERIFIED" and doc.get("doc_type")}),
            "under_review": sorted({doc.get("doc_type") for doc in documents if doc.get("status") == "UNDER_REVIEW" and doc.get("doc_type")}),
            "rejected": sorted({doc.get("doc_type") for doc in documents if doc.get("status") == "REJECTED" and doc.get("doc_type")}),
        },
        "likely_matching_scholarships": matches,
    }


async def get_course_recommendations(student_college_id: str) -> dict:
    db = get_database()
    student = await db.students.find_one({"college_id": student_college_id}) or {"college_id": student_college_id}
    enrollments = await db.enrollments.find({"student_college_id": student_college_id}).to_list(None)
    active_or_completed_course_ids = {enrollment.get("course_id") for enrollment in enrollments if enrollment.get("course_id")}
    completed_course_codes = {
        enrollment.get("course_code")
        for enrollment in enrollments
        if (enrollment.get("status") or "").lower() == "completed" and enrollment.get("course_code")
    }

    courses = await db.courses.find({"is_active": {"$ne": False}}).to_list(None)
    recommendations = []
    for course in courses:
        course_id = str(course["_id"])
        if course_id in active_or_completed_course_ids:
            continue
        why = recommend_course(student, course, completed_course_codes=completed_course_codes)
        if not why:
            continue
        recommendations.append({
            "course_id": course_id,
            "course_code": course.get("course_code", ""),
            "title": course.get("title", ""),
            "department": course.get("department", ""),
            "credits": course.get("credits", 0),
            "description": course.get("description", ""),
            "tags": course.get("tags", []),
            **why,
        })

    recommendations.sort(key=lambda item: item.get("score", 0), reverse=True)
    await db.recommendations.insert_one({
        "student_id": student_college_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "method": "rule_based",
        "recommendations": [
            {
                "course_id": item["course_id"],
                "course_code": item["course_code"],
                "score": item["score"],
                "why": item["why"],
            }
            for item in recommendations[:5]
        ],
    })

    return {
        "calculation_method": "rule_based",
        "note": "Based on the available information, these recommendations use transparent profile-to-course matching rules. Humans should make the final decision.",
        "student_profile": {
            "department": student.get("department"),
            "skills": student.get("skills", []),
            "interests": student.get("interests", []),
            "career_goals": student.get("career_goals", []),
        },
        "recommendations": recommendations[:5],
    }
