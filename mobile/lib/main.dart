
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:prok_mobile/core/app_router.dart";
import "package:prok_mobile/core/constants.dart";
import "package:prok_mobile/providers/auth_provider.dart";
import "package:prok_mobile/providers/attendance_provider.dart";
import "package:prok_mobile/providers/document_provider.dart";
import "package:prok_mobile/providers/scholarship_provider.dart";
import "package:prok_mobile/providers/course_provider.dart";
import "package:prok_mobile/providers/notification_provider.dart";

void main() => runApp(const ProkApp());

class ProkApp extends StatelessWidget {
  const ProkApp({super.key});
  @override Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ChangeNotifierProvider(create: (_) => ScholarshipProvider()),
      ChangeNotifierProvider(create: (_) => CourseProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: MaterialApp(
      title: "PROK",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    ));
}
