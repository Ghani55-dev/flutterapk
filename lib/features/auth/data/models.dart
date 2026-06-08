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

  /// Original raw id string (may be a UUID) from the API
  final String rawId;
  final String email;
  final String? name;
  final bool isAdmin;

  UserModel({
    required this.id,
    String? rawId,
    required this.email,
    this.name,
    this.isAdmin = false,
  }) : rawId = rawId ?? id.toString();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    final map = nestedUser is Map
        ? Map<String, dynamic>.from(nestedUser)
        : json;
    try {
      final idVal = map['id'];
      final rawId = idVal?.toString() ?? '';
      final id = idVal is int ? idVal : int.tryParse(rawId) ?? 0;
      return UserModel(
        id: id,
        rawId: rawId,
        email: map['email']?.toString() ?? '',
        name: map['full_name']?.toString() ?? map['name']?.toString(),
        isAdmin: _readAdminFlag(map),
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

bool _readAdminFlag(Map<String, dynamic> map) {
  bool truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'admin' ||
        normalized == 'administrator' ||
        normalized == 'superuser' ||
        normalized == 'staff';
  }

  if (truthy(map['is_admin']) ||
      truthy(map['is_staff']) ||
      truthy(map['is_superuser'])) {
    return true;
  }

  for (final key in ['role', 'user_type', 'account_type']) {
    if (truthy(map[key])) return true;
  }

  final roles = map['roles'] ?? map['groups'] ?? map['permissions'];
  if (roles is Iterable) {
    return roles.any(truthy);
  }

  return false;
}
