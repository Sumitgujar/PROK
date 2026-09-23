import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/theme/app_theme.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _S();
}
class _S extends State<SplashScreen> {
  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.loadUser();
    if (!mounted) return;
    if (auth.user != null) {
      Navigator.pushReplacementNamed(context, auth.user!.role == 'teacher' ? AppRoutes.teacherHome : AppRoutes.studentHome);
    } else { Navigator.pushReplacementNamed(context, AppRoutes.login); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProkColors.primary,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: ProkRadius.lg),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36)),
      const SizedBox(height: 20),
      const Text('PROK', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 6),
      Text('MANAGE  GUIDE  SUPPORT  GROW', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 56),
      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.5))),
    ])),
  );
}
