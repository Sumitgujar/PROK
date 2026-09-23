import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _L();
}
class _L extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _e = TextEditingController();
  final _p = TextEditingController();
  bool _obs = true, _loading = false;
  String? _error;
  @override void dispose() { _e.dispose(); _p.dispose(); super.dispose(); }
  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_e.text.trim(), _p.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context,
        auth.user?.role == 'teacher' ? AppRoutes.teacherHome : AppRoutes.studentHome);
    } catch (e) { setState(() => _error = e.toString().replaceAll('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProkColors.neutral50,
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.md),
          child: const Icon(Icons.auto_awesome_rounded, color: ProkColors.primary, size: 26)),
        const SizedBox(height: 20),
        const Text('Welcome to PROK', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: ProkColors.neutral900, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        const Text('Sign in to access your college guide', style: TextStyle(fontSize: 14, color: ProkColors.neutral400)),
        const SizedBox(height: 36),
        const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral800)),
        const SizedBox(height: 6),
        TextFormField(controller: _e, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
          decoration: const InputDecoration(hintText: 'student@prok.edu')),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral800)),
        const SizedBox(height: 6),
        TextFormField(controller: _p, obscureText: _obs, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _login(),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
          decoration: InputDecoration(hintText: 'Password',
            suffixIcon: IconButton(icon: Icon(_obs ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: ProkColors.neutral400),
              onPressed: () => setState(() => _obs = !_obs)))),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: ProkColors.errorSurface, borderRadius: ProkRadius.sm),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: ProkColors.error, size: 16), const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: ProkColors.error)))])),
        ],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loading ? null : _login,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In')),
        const SizedBox(height: 16),
        Center(child: Text('Demo: student@prok.edu / student123', style: TextStyle(fontSize: 11, color: ProkColors.neutral400.withOpacity(0.8)))),
      ])),
    )),
  );
}
