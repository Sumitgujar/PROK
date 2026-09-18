import unittest

from app.services.ask_prok import AskProkAccessError, AskProkService


class FakeRepository:
    def __init__(self, *, profile=None, documents=None, notifications=None, attendance=None, scholarships=None, courses=None):
        self.profile = profile if profile is not None else {
            "college_id": "STU1",
            "department": "Computer Science",
            "skills": ["Python"],
            "interests": ["AI"],
            "career_goals": ["ML Engineer"],
        }
        self.documents = documents if documents is not None else [
            {"status": "VERIFIED", "doc_type": "identity"},
            {"status": "UNDER_REVIEW", "doc_type": "income"},
        ]
        self.notifications = notifications if notifications is not None else [
            {"is_read": False, "title": "Attendance alert"}
        ]
        self.attendance = attendance if attendance is not None else {
            "risk_level": "HIGH",
            "overall_attendance": 58.0,
            "overall_attended_classes": 14,
            "overall_total_classes": 24,
            "consecutive_absences": 3,
            "reasons": [
                "Attendance is below the 75% target.",
                "Recent attendance is declining.",
                "Multiple consecutive absences were detected.",
            ],
            "subject_attendance": [
                {"course_code": "CS101", "course_title": "Programming", "percentage": 52.0}
            ],
        }
        self.scholarships = scholarships if scholarships is not None else {
            "likely_matching_scholarships": [
                {
                    "name": "AI Merit Scholarship",
                    "provider": "Tech Foundation",
                    "amount": 5000,
                    "score": 78,
                    "reasons": ["Student CGPA meets the minimum requirement of 3.5."],
                    "missing_documents": ["income"],
                }
            ]
        }
        self.courses = courses if courses is not None else {
            "recommendations": [
                {
                    "course_code": "CS405",
                    "title": "Applied AI Systems",
                    "score": 60,
                    "why": ["The course overlaps with the student's profile: ai, python."],
                }
            ]
        }
        self.saved = []
        self.calls = []

    async def get_student_profile(self, student_id):
        self.calls.append("profile")
        return self.profile

    async def get_documents(self, student_id):
        self.calls.append("documents")
        return self.documents

    async def get_notifications(self, user_id):
        self.calls.append("notifications")
        return self.notifications

    async def get_attendance_risk(self, student_id):
        self.calls.append("attendance")
        return self.attendance

    async def get_scholarship_matches(self, student_id):
        self.calls.append("scholarships")
        return self.scholarships

    async def get_course_recommendations(self, student_id):
        self.calls.append("courses")
        return self.courses

    async def save_conversation(self, payload):
        self.saved.append(payload)
        return "conv-1"


class ProviderManagerOK:
    async def generate_guidance(self, payload):
        return {
            "provider": "configured_ai",
            "guidance": "Start with the area creating the biggest immediate academic risk, then follow the suggested actions.",
            "warnings": [],
        }


class ProviderManagerFailure:
    async def generate_guidance(self, payload):
        raise RuntimeError("provider unavailable")


class ProviderManagerHallucinated:
    async def generate_guidance(self, payload):
        return {
            "provider": "configured_ai",
            "guidance": "Your attendance is 99% and you are guaranteed eligible for every scholarship.",
            "warnings": [],
        }


class AskProkServiceTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user = {"_id": "user-1", "college_id": "STU1", "role": "student"}

    async def test_authorized_access(self):
        service = AskProkService(repository=FakeRepository(), provider_manager=ProviderManagerOK())
        self.assertEqual(service.validate_chat_access(self.user), "STU1")
        with self.assertRaises(AskProkAccessError):
            service.validate_chat_access({"_id": "t1", "college_id": "EMP1", "role": "teacher"})

    async def test_data_retrieval_and_attendance_answer(self):
        repo = FakeRepository()
        service = AskProkService(repository=repo, provider_manager=ProviderManagerOK())
        result = await service.answer_question(question="Why is my attendance at risk?", user=self.user)
        self.assertEqual(result["intent"], "attendance_risk")
        self.assertIn("58.0%", result["answer"])
        self.assertIn("HIGH", result["answer"])
        self.assertIn("attendance", repo.calls)
        self.assertNotIn("scholarships", repo.calls)
        self.assertEqual(len(repo.saved), 1)

    async def test_missing_data_warning(self):
        repo = FakeRepository(profile={}, documents=[], scholarships={"likely_matching_scholarships": []})
        service = AskProkService(repository=repo, provider_manager=ProviderManagerOK())
        result = await service.answer_question(question="What documents am I missing?", user=self.user)
        self.assertEqual(result["intent"], "documents")
        self.assertTrue(any("No uploaded documents" in warning for warning in result["warnings"]))
        self.assertTrue(any("Student profile data is incomplete" in warning for warning in result["warnings"]))

    async def test_provider_failure_uses_fallback(self):
        service = AskProkService(repository=FakeRepository(), provider_manager=ProviderManagerFailure())
        result = await service.answer_question(question="Which scholarships should I check?", user=self.user)
        self.assertTrue(result["used_fallback"])
        self.assertEqual(result["provider"], "deterministic_fallback")
        self.assertTrue(any("deterministic fallback" in warning for warning in result["warnings"]))

    async def test_deterministic_fallback_general_response(self):
        class DeterministicManager:
            async def generate_guidance(self, payload):
                return {"provider": "deterministic_fallback", "guidance": "", "warnings": []}

        service = AskProkService(repository=FakeRepository(), provider_manager=DeterministicManager())
        result = await service.answer_question(question="Help me", user=self.user)
        self.assertEqual(result["intent"], "general_guidance")
        self.assertTrue(result["used_fallback"])
        self.assertIn("real PROK data", result["answer"])

    async def test_hallucinated_provider_response_is_discarded(self):
        service = AskProkService(repository=FakeRepository(), provider_manager=ProviderManagerHallucinated())
        result = await service.answer_question(question="Which scholarships should I check?", user=self.user)
        self.assertEqual(result["provider"], "deterministic_fallback")
        self.assertTrue(any("discarded" in warning for warning in result["warnings"]))
        self.assertNotIn("99%", result["answer"])
        self.assertNotIn("guaranteed eligible", result["answer"].lower())


if __name__ == "__main__":
    unittest.main()
