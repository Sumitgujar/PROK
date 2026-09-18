from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Any

from app.services.ai_provider import AiProviderManager


class AskProkAccessError(PermissionError):
    pass


class MongoProkRepository:
    async def get_student_profile(self, student_id: str) -> dict:
        from app.db.connection import get_database

        db = get_database()
        return await db.students.find_one({"college_id": student_id}) or {"college_id": student_id}

    async def get_documents(self, student_id: str) -> list[dict]:
        from app.db.connection import get_database

        db = get_database()
        docs = await db.documents.find({"student_id": student_id}).sort("uploaded_at", -1).to_list(None)
        for doc in docs:
            doc["_id"] = str(doc["_id"])
        return docs

    async def get_notifications(self, user_id: str) -> list[dict]:
        from app.db.connection import get_database

        db = get_database()
        notes = await db.notifications.find({"recipient_id": user_id}).sort("created_at", -1).limit(5).to_list(None)
        for note in notes:
            note["_id"] = str(note["_id"])
        return notes

    async def get_attendance_risk(self, student_id: str) -> dict:
        from app.services import intelligence as intelligence_svc

        return await intelligence_svc.get_attendance_risk(student_id)

    async def get_scholarship_matches(self, student_id: str) -> dict:
        from app.services import intelligence as intelligence_svc

        return await intelligence_svc.get_scholarship_intelligence(student_id)

    async def get_course_recommendations(self, student_id: str) -> dict:
        from app.services import intelligence as intelligence_svc

        return await intelligence_svc.get_course_recommendations(student_id)

    async def save_conversation(self, payload: dict) -> str:
        from app.db.connection import get_database

        db = get_database()
        result = await db.ai_conversations.insert_one(payload)
        return str(result.inserted_id)


class AskProkService:
    def __init__(self, repository: Any | None = None, provider_manager: AiProviderManager | None = None):
        self.repository = repository or MongoProkRepository()
        self.provider_manager = provider_manager or AiProviderManager()

    def validate_chat_access(self, user: dict) -> str:
        if not user or user.get("role") != "student":
            raise AskProkAccessError("Only students can use Ask PROK in this version.")
        return user["college_id"]

    def identify_intent(self, question: str) -> str:
        q = question.lower().strip()
        if any(k in q for k in ["attendance", "absent", "risk", "class attendance"]):
            return "attendance_risk"
        if any(k in q for k in ["document", "documents", "paperwork", "verification", "missing doc"]):
            return "documents"
        if any(k in q for k in ["scholarship", "scholarships", "grant", "financial aid"]):
            return "scholarships"
        if any(k in q for k in ["course", "courses", "subject", "class should", "suitable for me"]):
            return "courses"
        if any(k in q for k in ["focus", "this month", "priority", "priorities", "what should i do"]):
            return "focus"
        return "general_guidance"

    async def retrieve_context(self, student_id: str, user_id: str, intent: str) -> dict:
        profile = await self.repository.get_student_profile(student_id)
        docs = await self.repository.get_documents(student_id)
        notes = await self.repository.get_notifications(user_id)
        context = {
            "profile": profile,
            "documents": docs,
            "notifications": notes,
        }
        if intent in {"attendance_risk", "focus", "general_guidance"}:
            context["attendance"] = await self.repository.get_attendance_risk(student_id)
        if intent in {"scholarships", "documents", "focus", "general_guidance"}:
            context["scholarships"] = await self.repository.get_scholarship_matches(student_id)
        if intent in {"courses", "focus", "general_guidance"}:
            context["courses"] = await self.repository.get_course_recommendations(student_id)
        return context

    def _make_action(self, label: str, route: str) -> dict:
        return {"label": label, "route": route, "action_type": "navigate"}

    def _documents_summary(self, documents: list[dict]) -> dict:
        summary = {"VERIFIED": 0, "UNDER_REVIEW": 0, "REJECTED": 0}
        for doc in documents:
            status = doc.get("status") or "UNDER_REVIEW"
            summary[status] = summary.get(status, 0) + 1
        return summary

    def _aggregate_missing_documents(self, scholarship_matches: dict) -> list[str]:
        missing: set[str] = set()
        for match in scholarship_matches.get("likely_matching_scholarships", []):
            for item in match.get("missing_documents", []):
                missing.add(item)
        return sorted(missing)

    def build_deterministic_response(self, intent: str, context: dict) -> dict:
        warnings: list[str] = []
        actions: list[dict] = []
        profile = context.get("profile") or {}
        documents = context.get("documents") or []
        notes = context.get("notifications") or []
        doc_summary = self._documents_summary(documents)

        if intent == "attendance_risk":
            attendance = context.get("attendance") or {}
            reasons = attendance.get("reasons", [])
            top_subjects = [s for s in attendance.get("subject_attendance", []) if s.get("percentage", 0) < 75]
            actions.append(self._make_action("View attendance details", "/student/attendance"))
            if not attendance.get("overall_total_classes"):
                warnings.append("No attendance sessions are available yet, so the risk result is limited.")
            answer = (
                f"Your current attendance risk level is {attendance.get('risk_level', 'UNKNOWN')}. "
                f"Overall attendance is {attendance.get('overall_attendance', 0)}%."
            )
            if reasons:
                answer += " Reasons: " + "; ".join(reasons[:3]) + "."
            if top_subjects:
                answer += " Subjects below target: " + ", ".join(
                    f"{s.get('course_code', s.get('course_title', 'Subject'))} ({s.get('percentage', 0)}%)"
                    for s in top_subjects[:3]
                ) + "."
            return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

        if intent == "documents":
            scholarship_matches = context.get("scholarships") or {}
            missing = self._aggregate_missing_documents(scholarship_matches)
            actions.append(self._make_action("Open documents", "/student/documents"))
            answer = (
                f"You currently have {doc_summary.get('VERIFIED', 0)} verified documents, "
                f"{doc_summary.get('UNDER_REVIEW', 0)} under review, and {doc_summary.get('REJECTED', 0)} rejected."
            )
            if missing:
                answer += " Based on the available information and current scholarship matches, you may still need: " + ", ".join(missing) + "."
            else:
                answer += " Based on the available information, I do not see any additional missing document types for the current likely scholarship matches."
            if not documents:
                warnings.append("No uploaded documents were found for this student.")
            return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

        if intent == "scholarships":
            scholarships = context.get("scholarships") or {}
            matches = scholarships.get("likely_matching_scholarships", [])
            actions.append(self._make_action("Browse scholarships", "/student/scholarships"))
            if not matches:
                warnings.append("No likely scholarship matches were found from the current data.")
                return {
                    "answer": "Based on the available information, I could not find a strong scholarship match right now. Updating your profile and document verification status may improve matching.",
                    "intent": intent,
                    "actions": actions,
                    "warnings": warnings,
                }
            top = matches[:3]
            parts = []
            for match in top:
                why = match.get("reasons", [])
                text = f"{match.get('name')} ({match.get('provider')})"
                if why:
                    text += ": " + "; ".join(why[:2])
                if match.get("missing_documents"):
                    text += f". Missing documents: {', '.join(match.get('missing_documents'))}"
                parts.append(text)
            answer = "Based on the available information, these scholarships look most relevant: " + " | ".join(parts) + ". Eligibility is not guaranteed and should be checked manually."
            return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

        if intent == "courses":
            courses = context.get("courses") or {}
            recommendations = courses.get("recommendations", [])
            actions.append(self._make_action("Explore courses", "/student/courses"))
            if not recommendations:
                warnings.append("No course recommendations were generated from the current profile data.")
                return {
                    "answer": "I do not have enough matching course signals yet. Adding or updating your skills, interests, and career goals can improve recommendations.",
                    "intent": intent,
                    "actions": actions,
                    "warnings": warnings,
                }
            top = recommendations[:3]
            parts = []
            for course in top:
                why = course.get("why", [])
                snippet = f"{course.get('course_code')} {course.get('title')}"
                if why:
                    snippet += ": " + "; ".join(why[:2])
                parts.append(snippet)
            answer = "Based on the available information, these courses appear suitable: " + " | ".join(parts) + "."
            return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

        if intent == "focus":
            attendance = context.get("attendance") or {}
            scholarships = context.get("scholarships") or {}
            courses = context.get("courses") or {}
            focus_items = []
            actions.extend([
                self._make_action("Check attendance", "/student/attendance"),
                self._make_action("Review documents", "/student/documents"),
                self._make_action("See scholarships", "/student/scholarships"),
            ])
            if attendance.get("risk_level") == "HIGH":
                focus_items.append("Improve attendance first, because your risk level is HIGH.")
            elif attendance.get("risk_level") == "MEDIUM":
                focus_items.append("Watch attendance closely, because your risk level is MEDIUM.")
            missing = self._aggregate_missing_documents(scholarships)
            if missing:
                focus_items.append("Prepare or verify these document types: " + ", ".join(missing[:4]) + ".")
            if scholarships.get("likely_matching_scholarships"):
                focus_items.append("Review the current scholarship matches before deadlines pass.")
            if courses.get("recommendations"):
                focus_items.append("Shortlist recommended courses that align with your profile.")
            if notes:
                unread = sum(1 for note in notes if not note.get("is_read"))
                if unread:
                    focus_items.append(f"Clear {unread} unread notification(s) so you do not miss updates.")
            if not focus_items:
                warnings.append("Limited student data is available, so the focus advice is generic.")
                focus_items.append("Complete your profile and keep your documents up to date to unlock more precise guidance.")
            answer = "This month, I suggest focusing on: " + " ".join(f"{i+1}. {item}" for i, item in enumerate(focus_items[:4]))
            return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

        actions.extend([
            self._make_action("Ask about attendance", "/student/attendance"),
            self._make_action("Ask about scholarships", "/student/scholarships"),
            self._make_action("Ask about courses", "/student/courses"),
        ])
        answer = "I can explain your attendance risk, document status, likely scholarships, suitable courses, and monthly priorities using your real PROK data. Ask a specific question for more detail."
        if not profile:
            warnings.append("Student profile data is limited, so some guidance may be less specific.")
        return {"answer": answer, "intent": intent, "actions": actions, "warnings": warnings}

    def _allowed_numbers(self, context: dict, fallback_answer: str) -> set[str]:
        tokens = set(re.findall(r"\d+(?:\.\d+)?", fallback_answer))
        for attendance in context.get("attendance", {}).get("subject_attendance", []):
            tokens.update(re.findall(r"\d+(?:\.\d+)?", str(attendance.get("percentage", ""))))
        for key in ["overall_attendance", "overall_attended_classes", "overall_total_classes", "consecutive_absences"]:
            if key in context.get("attendance", {}):
                tokens.update(re.findall(r"\d+(?:\.\d+)?", str(context["attendance"][key])))
        for match in context.get("scholarships", {}).get("likely_matching_scholarships", []):
            tokens.update(re.findall(r"\d+(?:\.\d+)?", str(match.get("amount", ""))))
            tokens.update(re.findall(r"\d+(?:\.\d+)?", str(match.get("score", ""))))
        return tokens | {"5", "10", "15", "75"}

    def _is_provider_guidance_safe(self, guidance: str, context: dict, fallback_answer: str) -> bool:
        if not guidance.strip():
            return True
        lower = guidance.lower()
        banned_phrases = [
            "guaranteed eligible",
            "definitely eligible",
            "official college policy",
            "you will be approved",
            "you will be punished",
            "you will be blocked",
        ]
        if any(phrase in lower for phrase in banned_phrases):
            return False
        allowed_numbers = self._allowed_numbers(context, fallback_answer)
        found_numbers = set(re.findall(r"\d+(?:\.\d+)?", guidance))
        return found_numbers.issubset(allowed_numbers)

    async def answer_question(self, *, question: str, user: dict) -> dict:
        student_id = self.validate_chat_access(user)
        user_id = str(user.get("_id", ""))
        intent = self.identify_intent(question)
        context = await self.retrieve_context(student_id, user_id, intent)
        fallback = self.build_deterministic_response(intent, context)
        try:
            provider_result = await self.provider_manager.generate_guidance({
                "question": question,
                "intent": intent,
                "facts": context,
                "fallback_answer": fallback["answer"],
            })
        except Exception as exc:
            provider_result = {
                "provider": "deterministic_fallback",
                "guidance": "",
                "warnings": [],
                "provider_errors": [str(exc)],
            }

        final = dict(fallback)
        warnings = list(final.get("warnings", []))
        provider_name = provider_result.get("provider", "deterministic_fallback")
        guidance = (provider_result.get("guidance") or "").strip()
        provider_warnings = provider_result.get("warnings") or []
        if provider_name == "deterministic_fallback":
            warnings.extend(provider_warnings)
            if provider_result.get("provider_errors"):
                warnings.append("AI guidance is unavailable right now, so Ask PROK used a deterministic fallback response.")
        elif self._is_provider_guidance_safe(guidance, context, fallback["answer"]):
            if guidance:
                final["answer"] = f"{fallback['answer']}\n\nAdditional guidance: {guidance}"
            warnings.extend(provider_warnings)
        else:
            warnings.append("AI guidance was discarded because it could not be grounded safely in PROK data.")
            provider_name = "deterministic_fallback"

        if not context.get("documents"):
            warnings.append("No student documents were found in the current record.")
        if not context.get("profile"):
            warnings.append("Student profile data is incomplete.")

        final["warnings"] = list(dict.fromkeys(warnings))
        final["provider"] = provider_name
        final["used_fallback"] = provider_name == "deterministic_fallback"

        await self.repository.save_conversation({
            "student_id": student_id,
            "user_id": user_id,
            "question": question,
            "intent": intent,
            "response": final,
            "provider": provider_name,
            "used_fallback": final["used_fallback"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        return final
