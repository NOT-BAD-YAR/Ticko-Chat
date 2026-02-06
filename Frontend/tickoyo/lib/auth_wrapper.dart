import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
