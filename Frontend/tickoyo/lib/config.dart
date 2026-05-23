import 'package:flutter/foundation.dart';

class Config {
  // TODO: Replace this URL with your live Render backend URL when deploying
  // Example: static const String _productionUrl = 'https://ticko-backend.onrender.com';
  static const String _productionUrl = ''; 

  static String get baseUrl {
    if (kReleaseMode && _productionUrl.isNotEmpty) {
      // Use production URL if in release mode and it's set
      return _productionUrl;
    } else {
      // Local development URLs
      if (kIsWeb) {
        return 'http://localhost:5000';
      }
      // For Android emulators, 10.0.2.2 is used to access host localhost.
      // Note: If running as a Windows Desktop app natively, this should probably be localhost.
      // But we keep the original logic here for now.
      return 'http://10.0.2.2:5000';
    }
  }

  static String get apiUrl => '$baseUrl/api';
}
