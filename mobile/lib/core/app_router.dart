
import "package:flutter/material.dart";
import "package:prok_mobile/core/constants.dart";
import "package:prok_mobile/screens/splash_screen.dart";
import "package:prok_mobile/screens/login_screen.dart";
import "package:prok_mobile/screens/student/home_screen.dart";
import "package:prok_mobile/screens/student/attendance_screen.dart";
import "package:prok_mobile/screens/student/documents_screen.dart";
import "package:prok_mobile/screens/student/scholarships_screen.dart";
import "package:prok_mobile/screens/student/courses_screen.dart";
import "package:prok_mobile/screens/student/notifications_screen.dart";
import "package:prok_mobile/screens/student/profile_screen.dart";
import "package:prok_mobile/screens/teacher/todays_classes_screen.dart";
import "package:prok_mobile/screens/teacher/class_details_screen.dart";
import "package:prok_mobile/screens/teacher/mark_attendance_screen.dart";
import "package:prok_mobile/screens/teacher/attendance_history_screen.dart";

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case AppRoutes.splash: page = const SplashScreen(); break;
      case AppRoutes.login: page = const LoginScreen(); break;
      case AppRoutes.studentHome: page = const StudentHomeScreen(); break;
      case AppRoutes.studentAttendance: page = const StudentAttendanceScreen(); break;
      case AppRoutes.studentDocuments: page = const StudentDocumentsScreen(); break;
      case AppRoutes.studentScholarships: page = const StudentScholarshipsScreen(); break;
      case AppRoutes.studentCourses: page = const StudentCoursesScreen(); break;
      case AppRoutes.studentNotifications: page = const StudentNotificationsScreen(); break;
      case AppRoutes.studentProfile: page = const StudentProfileScreen(); break;
      case AppRoutes.teacherHome: page = const TeacherTodaysClassesScreen(); break;
      case "/teacher/class-details": page = const ClassDetailsScreen(); break;
      case "/teacher/mark-attendance": page = const MarkAttendanceScreen(); break;
      case "/teacher/attendance-history": page = const AttendanceHistoryScreen(); break;
      default: page = const SplashScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
