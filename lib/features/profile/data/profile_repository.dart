import 'package:flutter/foundation.dart';
import 'profile_remote_datasource.dart';
import '../models/profile_model.dart';
import '../../../core/network/response_parser.dart';

class ProfileRepository {
  final ProfileRemoteDataSource remote;
  ProfileRepository({required this.remote});

  Future<ProfileModel> getProfile() async {
    final resp = await remote.fetchProfile();
    try {
      if (kDebugMode) debugPrint('Profile Request: ${resp.requestOptions.method} ${resp.requestOptions.path}');
      if (kDebugMode) debugPrint('Profile Response [status=${resp.statusCode}] type=${resp.data.runtimeType}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final raw = parseMapResponse(resp);
      final map = raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw;
      return ProfileModel.fromJson(map);
    }
    throw Exception('Failed to load profile');
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> body) async {
    final resp = await remote.updateProfile(body);
    try {
      if (kDebugMode) debugPrint('Profile Update Request: ${resp.requestOptions.method} ${resp.requestOptions.path} bodyPreview=${body.keys.join(',')}');
      if (kDebugMode) debugPrint('Profile Update Response [status=${resp.statusCode}] type=${resp.data.runtimeType}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final raw = parseMapResponse(resp);
      final map = raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw;
      return ProfileModel.fromJson(map);
    }
    throw Exception('Failed to update profile');
  }

  Future<void> updateLocation(Map<String, dynamic> body) async {
    final resp = await remote.updateLocation(body);
    if ((resp.statusCode ?? 0) >= 400) {
      throw Exception('Failed to update location');
    }
  }
}
