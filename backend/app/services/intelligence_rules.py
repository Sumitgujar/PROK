from __future__ import annotations

import re
from typing import Iterable, Sequence

TARGET_ATTENDANCE = 75.0
HIGH_RISK_THRESHOLD = 60.0
SUPPORTED_RECOVERY_WINDOWS = (5, 10, 15)
ATTENDED_STATUSES = {"present", "late"}
ABSENT_STATUSES = {"absent"}
VALID_INTERVENTION_STATUSES = {"OPEN", "IN_PROGRESS", "RESOLVED"}


def normalize_status(status: str | None) -> str:
    return (status or "").strip().lower()


def is_attended(status: str | None) -> bool:
    return normalize_status(status) in ATTENDED_STATUSES


def calculate_percentage(attended: int, total: int, precision: int = 2) -> float:
    if attended < 0 or total < 0 or attended > total:
        raise ValueError("Attended classes must be between 0 and total classes.")
    if total == 0:
        return 0.0
    return round((attended / total) * 100, precision)


def calculate_recent_trend(statuses: Sequence[str]) -> dict:
    normalized = [normalize_status(s) for s in statuses]
    if len(normalized) < 2:
        return {
            "label": "stable",
            "recent_rate": None,
            "previous_rate": None,
            "delta": 0.0,
            "reason": "Not enough attendance history to compare recent performance.",
        }

    recent_window = min(5, len(normalized))
    recent_slice = normalized[-recent_window:]
    previous_slice = normalized[-(recent_window * 2):-recent_window]

    recent_rate = calculate_percentage(sum(1 for s in recent_slice if is_attended(s)), len(recent_slice))
    if not previous_slice:
        return {
            "label": "stable",
            "recent_rate": recent_rate,
            "previous_rate": None,
            "delta": 0.0,
            "reason": "There are not enough earlier sessions to determine a trend yet.",
        }

    previous_rate = calculate_percentage(sum(1 for s in previous_slice if is_attended(s)), len(previous_slice))
    delta = round(recent_rate - previous_rate, 2)

    if delta <= -10:
        label = "declining"
        reason = "Recent attendance is lower than the previous set of classes."
    elif delta >= 10:
        label = "improving"
        reason = "Recent attendance is better than the previous set of classes."
    else:
        label = "stable"
        reason = "Recent attendance is broadly similar to the previous set of classes."

    return {
        "label": label,
        "recent_rate": recent_rate,
        "previous_rate": previous_rate,
        "delta": delta,
        "reason": reason,
    }


def calculate_consecutive_absences(statuses: Sequence[str]) -> int:
    streak = 0
    for status in reversed([normalize_status(s) for s in statuses]):
        if status in ABSENT_STATUSES:
            streak += 1
        else:
            break
    return streak


def determine_risk_level(
    overall_attendance: float,
    subject_attendance: Sequence[dict],
    trend_label: str,
    consecutive_absences: int,
) -> dict:
    reasons: list[str] = []
    score = 0

    if overall_attendance < HIGH_RISK_THRESHOLD:
        score += 3
        reasons.append("Attendance is well below the 75% target.")
    elif overall_attendance < TARGET_ATTENDANCE:
        score += 1
        reasons.append("Attendance is below the 75% target.")
    else:
        reasons.append("Overall attendance is currently at or above the 75% target.")

    low_subjects = [s.get("course_code") or s.get("course_title") or "Subject" for s in subject_attendance if s.get("percentage", 0) < TARGET_ATTENDANCE]
    critical_subjects = [s.get("course_code") or s.get("course_title") or "Subject" for s in subject_attendance if s.get("percentage", 0) < HIGH_RISK_THRESHOLD]

    if critical_subjects:
        score += 2
        reasons.append(f"Some subjects are in a critical range: {', '.join(critical_subjects)}.")
    elif low_subjects:
        score += 1
        reasons.append(f"Some subjects are below the target: {', '.join(low_subjects)}.")
    else:
        reasons.append("Subject-level attendance is currently within the target range.")

    if trend_label == "declining":
        score += 2
        reasons.append("Recent attendance is declining.")
    elif trend_label == "improving":
        reasons.append("Recent attendance is improving.")
    else:
        reasons.append("Recent attendance trend is stable.")

    if consecutive_absences >= 3:
        score += 2
        reasons.append("Multiple consecutive absences were detected.")
    elif consecutive_absences == 2:
        score += 1
        reasons.append("Back-to-back absences were detected.")
    elif consecutive_absences == 1:
        reasons.append("There was a recent absence, but it is not yet a streak.")
    else:
        reasons.append("No current consecutive absence streak was detected.")

    if score >= 5:
        risk_level = "HIGH"
    elif score >= 2:
        risk_level = "MEDIUM"
    else:
        risk_level = "LOW"

    return {"risk_level": risk_level, "reasons": reasons, "score": score}


def build_recovery_projection(attended: int, total: int, future_windows: Sequence[int] = SUPPORTED_RECOVERY_WINDOWS) -> dict:
    current_percentage = calculate_percentage(attended, total)
    projections = []
    for future_classes in future_windows:
        if future_classes <= 0:
            raise ValueError("Future classes must be positive.")
        projected_attended = attended + future_classes
        projected_total = total + future_classes
        projections.append({
            "future_classes": future_classes,
            "projected_attended_classes": projected_attended,
            "projected_total_classes": projected_total,
            "projected_percentage": calculate_percentage(projected_attended, projected_total),
            "formula": f"({attended} + {future_classes}) / ({total} + {future_classes})",
            "label": "Mathematical projection assuming all future classes are attended.",
        })
    return {
        "calculation_type": "mathematical_projection",
        "note": "This is a mathematical projection, not an AI prediction.",
        "current_attended_classes": attended,
        "current_total_classes": total,
        "current_percentage": current_percentage,
        "projections": projections,
    }


def _tokenize(values: Iterable[str | None]) -> set[str]:
    tokens: set[str] = set()
    for value in values:
        if not value:
            continue
        for token in re.findall(r"[a-z0-9]+", value.lower()):
            if len(token) > 1:
                tokens.add(token)
    return tokens


def evaluate_scholarship_match(student_profile: dict, scholarship: dict, verified_doc_types: Iterable[str]) -> dict:
    verified = {str(v).strip().lower() for v in verified_doc_types if v}
    required_docs = [str(v).strip().lower() for v in scholarship.get("required_doc_types", []) if v]
    missing_docs = sorted([doc for doc in required_docs if doc not in verified])

    score = 0
    reasons: list[str] = []
    student_cgpa = student_profile.get("cgpa")
    min_cgpa = scholarship.get("min_cgpa")

    if min_cgpa is None:
        score += 25
        reasons.append("No minimum CGPA requirement is listed.")
    elif student_cgpa is not None and student_cgpa >= min_cgpa:
        score += 35
        reasons.append(f"Student CGPA meets the minimum requirement of {min_cgpa}.")
    else:
        reasons.append(f"Student CGPA does not clearly meet the minimum requirement of {min_cgpa}.")

    if not missing_docs:
        score += 25
        reasons.append("All listed required document types are already verified.")
    else:
        score += max(0, 25 - (len(missing_docs) * 10))
        reasons.append(f"Missing verified documents: {', '.join(missing_docs)}.")

    department = (student_profile.get("department") or "").strip().lower()
    scholarship_text = " ".join([
        scholarship.get("name", ""),
        scholarship.get("provider", ""),
        scholarship.get("description", ""),
        scholarship.get("eligibility", ""),
    ]).lower()
    if department and department in scholarship_text:
        score += 20
        reasons.append("Scholarship description appears aligned with the student's department.")
    elif department:
        reasons.append("No explicit department match was found in the scholarship text.")

    student_interest_tokens = _tokenize(
        list(student_profile.get("skills", []))
        + list(student_profile.get("interests", []))
        + list(student_profile.get("career_goals", []))
    )
    scholarship_tokens = _tokenize([scholarship_text])
    common_tokens = sorted(student_interest_tokens & scholarship_tokens)
    if common_tokens:
        score += min(20, 5 * len(common_tokens))
        reasons.append(f"Scholarship wording overlaps with the student's profile: {', '.join(common_tokens[:4])}.")

    if score >= 70:
        match_level = "LIKELY_MATCH"
    elif score >= 45:
        match_level = "POSSIBLE_MATCH"
    else:
        match_level = "REVIEW_NEEDED"

    explanation = (
        "Based on the available information, this scholarship was scored using transparent rules "
        "that compare profile fit, listed requirements, and verified documents. "
        "This is not a guarantee of eligibility."
    )

    return {
        "match_level": match_level,
        "score": score,
        "requirements": {
            "min_cgpa": min_cgpa,
            "required_doc_types": required_docs,
            "eligibility": scholarship.get("eligibility", ""),
        },
        "missing_documents": missing_docs,
        "reasons": reasons,
        "explanation": explanation,
    }


def recommend_course(student_profile: dict, course: dict, completed_course_codes: Iterable[str] | None = None) -> dict | None:
    completed = {str(v).strip().lower() for v in (completed_course_codes or []) if v}
    course_code = str(course.get("course_code", "")).strip().lower()
    if course_code and course_code in completed:
        return None

    score = 0
    reasons: list[str] = []
    student_department = (student_profile.get("department") or "").strip().lower()
    course_department = (course.get("department") or "").strip().lower()

    if student_department and course_department and student_department == course_department:
        score += 20
        reasons.append("The course is in the student's department.")

    student_tokens = _tokenize(
        list(student_profile.get("skills", []))
        + list(student_profile.get("interests", []))
        + list(student_profile.get("career_goals", []))
    )
    course_tokens = _tokenize(
        [course.get("title", ""), course.get("description", "")]
        + list(course.get("tags", []))
    )
    overlap = sorted(student_tokens & course_tokens)
    if overlap:
        score += min(45, 15 * len(overlap))
        reasons.append(f"The course overlaps with the student's profile: {', '.join(overlap[:4])}.")

    if course.get("credits"):
        score += 5
        reasons.append(f"The course offers {course.get('credits')} credits toward academic progress.")

    if not reasons:
        return None

    explanation = (
        "Based on the available information, this course was recommended using transparent matching rules "
        "between the student's profile and the course description. Humans should make the final decision."
    )

    return {
        "score": score,
        "why": reasons,
        "explanation": explanation,
    }


def validate_intervention_status(status: str) -> str:
    normalized = (status or "").strip().upper()
    if normalized not in VALID_INTERVENTION_STATUSES:
        raise ValueError("Invalid intervention status.")
    return normalized
