
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:prok_mobile/core/constants.dart";
import "package:prok_mobile/providers/auth_provider.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> {
  @override void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().tryAutoLogin();
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (user.role == "student") {
      Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
    } else if (user.role == "teacher") {
      Navigator.pushReplacementNamed(context, AppRoutes.teacherHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text("PROK", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      SizedBox(height: 12),
      CircularProgressIndicator(color: Color(0xFF1E3A8A)),
    ])));
}
