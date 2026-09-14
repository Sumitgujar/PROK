import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProkApp());
}

class ProkApp extends StatelessWidget {
  const ProkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter();
          return MaterialApp.router(
            title: 'PROK',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6c63ff),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
