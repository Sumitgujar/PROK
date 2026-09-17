import unittest

from app.services.intelligence_rules import (
    build_recovery_projection,
    calculate_consecutive_absences,
    calculate_percentage,
    calculate_recent_trend,
    determine_risk_level,
    evaluate_scholarship_match,
    recommend_course,
    validate_intervention_status,
)


class AttendanceRiskRuleTests(unittest.TestCase):
    def test_percentage(self):
        self.assertEqual(calculate_percentage(6, 8), 75.0)

    def test_trend_declining(self):
        result = calculate_recent_trend([
            "present", "present", "present", "present", "present",
            "absent", "absent", "absent", "present", "absent",
        ])
        self.assertEqual(result["label"], "declining")
        self.assertLess(result["delta"], 0)

    def test_consecutive_absences(self):
        self.assertEqual(calculate_consecutive_absences(["present", "absent", "absent", "absent"]), 3)

    def test_high_risk_reasons(self):
        result = determine_risk_level(
            overall_attendance=52.0,
            subject_attendance=[
                {"course_code": "CS101", "percentage": 48.0},
                {"course_code": "MA201", "percentage": 58.0},
            ],
            trend_label="declining",
            consecutive_absences=3,
        )
        self.assertEqual(result["risk_level"], "HIGH")
        self.assertTrue(any("below the 75% target" in reason for reason in result["reasons"]))
        self.assertTrue(any("declining" in reason.lower() for reason in result["reasons"]))
        self.assertTrue(any("consecutive absences" in reason.lower() for reason in result["reasons"]))

    def test_low_risk_reasons_present(self):
        result = determine_risk_level(
            overall_attendance=88.0,
            subject_attendance=[{"course_code": "CS101", "percentage": 90.0}],
            trend_label="stable",
            consecutive_absences=0,
        )
        self.assertEqual(result["risk_level"], "LOW")
        self.assertGreaterEqual(len(result["reasons"]), 1)


class RecoveryProjectionTests(unittest.TestCase):
    def test_recovery_projection(self):
        result = build_recovery_projection(18, 30)
        self.assertEqual(result["calculation_type"], "mathematical_projection")
        self.assertEqual(result["projections"][0]["future_classes"], 5)
        self.assertAlmostEqual(result["projections"][0]["projected_percentage"], 65.71)
        self.assertIn("not an AI prediction", result["note"])


class ScholarshipIntelligenceTests(unittest.TestCase):
    def test_scholarship_match_identifies_missing_docs(self):
        result = evaluate_scholarship_match(
            {
                "department": "Computer Science",
                "cgpa": 3.7,
                "skills": ["python"],
                "interests": ["ai"],
                "career_goals": ["software engineer"],
            },
            {
                "name": "AI Merit Scholarship",
                "provider": "Tech Foundation",
                "description": "Supports AI and software innovation students",
                "eligibility": "Computer Science students with strong academic records",
                "required_doc_types": ["identity", "income"],
                "min_cgpa": 3.5,
            },
            verified_doc_types=["identity"],
        )
        self.assertIn("income", result["missing_documents"])
        self.assertTrue(result["score"] > 0)
        self.assertTrue(result["explanation"].startswith("Based on the available information"))


class CourseRecommendationTests(unittest.TestCase):
    def test_course_recommendation_contains_why(self):
        result = recommend_course(
            {
                "department": "Computer Science",
                "skills": ["python", "mongodb"],
                "interests": ["ai", "mobile"],
                "career_goals": ["machine learning engineer"],
            },
            {
                "course_code": "CS405",
                "title": "Applied AI Systems",
                "department": "Computer Science",
                "description": "Build machine learning and AI applications with Python",
                "tags": ["ai", "python", "ml"],
                "credits": 4,
            },
            completed_course_codes=["CS101"],
        )
        self.assertIsNotNone(result)
        self.assertGreater(len(result["why"]), 0)
        self.assertIn("Based on the available information", result["explanation"])

    def test_completed_course_is_excluded(self):
        result = recommend_course(
            {"department": "Computer Science", "skills": [], "interests": [], "career_goals": []},
            {"course_code": "CS101", "title": "Intro", "department": "Computer Science", "description": "", "tags": []},
            completed_course_codes=["CS101"],
        )
        self.assertIsNone(result)


class InterventionRuleTests(unittest.TestCase):
    def test_validate_intervention_status(self):
        self.assertEqual(validate_intervention_status("open"), "OPEN")
        with self.assertRaises(ValueError):
            validate_intervention_status("closed")


if __name__ == "__main__":
    unittest.main()
