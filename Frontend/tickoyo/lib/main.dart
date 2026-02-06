import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store/auth_provider.dart';
import 'store/theme_provider.dart';
import 'store/chat_provider.dart';
import 'services/socket_service.dart';
import 'auth_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) {
          return MaterialApp(
            title: 'Ticko Chat',
            debugShowCheckedModeBanner: false,
            // High contrast light theme
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: themeProvider.seedColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
                surfaceContainerHighest: Colors.grey[200],
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.black87),
                titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: themeProvider.seedColor,
                foregroundColor: Colors.white,
              ),
            ),
            // High contrast dark theme
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: themeProvider.seedColor, // Adjust for dark mode visibility?
                onPrimary: Colors.white,
                surface: const Color(0xFF1E1E1E),
                onSurface: Colors.white,
                surfaceContainerHighest: const Color(0xFF2C2C2C),
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white70),
                titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
