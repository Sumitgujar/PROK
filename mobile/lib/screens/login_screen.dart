
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:prok_mobile/core/constants.dart";
import "package:prok_mobile/providers/auth_provider.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().login(
          _emailCtrl.text.trim(), _pwdCtrl.text);
      if (!mounted) return;
      final user = context.read<AuthProvider>().user!;
      Navigator.pushReplacementNamed(context,
          user.role == "teacher" ? AppRoutes.teacherHome : AppRoutes.studentHome);
    } catch (e) {
      setState(() { _error = e.toString().replaceAll("Exception: ", ""); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(key: _formKey, child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          const Text("PROK", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          const Text("College Ecosystem", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          if (_error != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
          if (_error != null) const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v?.contains("@") ?? false) ? null : "Enter a valid email"),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pwdCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: "Password", border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure))),
            validator: (v) => (v?.length ?? 0) >= 6 ? null : "Min 6 characters"),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16)))),
        ]))));
}
