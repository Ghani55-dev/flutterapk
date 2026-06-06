import 'package:flutter/foundation.dart';

class AuthTokens {
  final String access;
  final String refresh;

  AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final map = json;
    try {
      return AuthTokens(
        access: map['access']?.toString() ?? '',
        refresh: map['refresh']?.toString() ?? '',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AuthTokens.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return AuthTokens(access: '', refresh: '');
    }
  }
}

class UserModel {
  final int id;
  final String email;
  final String? name;

  UserModel({required this.id, required this.email, this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final map = json;
    try {
      final idVal = map['id'];
      final id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '') ?? 0;
      return UserModel(
        id: id,
        email: map['email']?.toString() ?? '',
        name: map['full_name']?.toString() ?? map['name']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[UserModel.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return UserModel(id: 0, email: '');
    }
  }
}
