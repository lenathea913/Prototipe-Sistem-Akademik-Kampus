// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  static const String baseUrl = 'http://192.168.1.100:8000/api';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String profileEndpoint = '/auth/profile';
  static const String jadwalEndpoint = '/jadwal';
  static const String nilaiEndpoint = '/nilai';
  static const String presensiEndpoint = '/presensi';
  static const String matkulEndpoint = '/matkul';
  
  // App Info
  static const String appName = 'KampusKu';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userNimKey = 'user_nim';
}

class AppColors {
  static const primaryColor = Color(0xFF1565C0);
  static const secondaryColor = Color(0xFF0D47A1);
  static const accentColor = Color(0xFF42A5F5);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFF9800);
  static const errorColor = Color(0xFFF44336);
}
