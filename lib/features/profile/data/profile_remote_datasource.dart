import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ProfileRemoteDataSource {
  final ApiClient apiClient;
  ProfileRemoteDataSource({required this.apiClient});

  Future<Response> fetchProfile() async => apiClient.dio.get('/api/v1/auth/me/');

  Future<Response> updateProfile(Map<String, dynamic> body) async => apiClient.dio.patch('/api/v1/auth/me/', data: body);

  Future<Response> updateLocation(Map<String, dynamic> body) async => apiClient.dio.post('/api/v1/user/location/', data: body);
}
