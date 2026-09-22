import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/app_router.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/providers/document_provider.dart';
import 'package:prok_mobile/providers/scholarship_provider.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/providers/notification_provider.dart';
import 'package:prok_mobile/providers/ai_chat_provider.dart';
void main() => runApp(const ProkApp());
class ProkApp extends StatelessWidget {
  const ProkApp({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ChangeNotifierProvider(create: (_) => ScholarshipProvider()),
      ChangeNotifierProvider(create: (_) => CourseProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => AiChatProvider()),
    ],
    child: MaterialApp(
      title: 'PROK', debugShowCheckedModeBanner: false,
      theme: ProkTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    ),
  );
}
