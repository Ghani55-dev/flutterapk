import 'package:flutter/foundation.dart';

class ProfileModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? contributorBadge;
  final String? preferredLanguage;
  final String? theme;
  final double? fontSize;

  ProfileModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.contributorBadge,
    this.preferredLanguage,
    this.theme,
    this.fontSize,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final map = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    try {
      return ProfileModel(
        id: map['id']?.toString() ?? '',
        displayName: map['full_name']?.toString() ?? map['display_name']?.toString() ?? map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        avatarUrl: map['profile_image']?.toString() ?? map['avatar_url']?.toString() ?? map['avatar']?.toString(),
        contributorBadge: map['contributor_badge']?.toString() ?? map['trust_level']?.toString() ?? map['reporter_badge']?.toString(),
        preferredLanguage: map['preferred_language']?.toString() ?? map['language']?.toString(),
        theme: map['theme']?.toString(),
        fontSize: _parseDouble(map['font_size']),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfileModel.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return ProfileModel(id: '', displayName: '', email: '');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': displayName,
        'email': email,
        'profile_image': avatarUrl,
        'contributor_badge': contributorBadge,
        'preferred_language': preferredLanguage,
        'theme': theme,
        'font_size': fontSize,
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
