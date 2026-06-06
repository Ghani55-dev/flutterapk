import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/response_parser.dart';

class HealthCheckResult {
  final bool isHealthy;
  final String message;

  const HealthCheckResult({required this.isHealthy, required this.message});
}

class HealthRepository {
  final ApiClient apiClient;

  HealthRepository({required this.apiClient});

  Future<HealthCheckResult> checkHealth() async {
    final candidates = <String>['/health/', '/system/health/'];

    for (final path in candidates) {
      try {
        final response = await apiClient.dio.get(path);
        final statusCode = response.statusCode ?? 0;
        final payload = ApiResponseParser.extractMap(response);
        final status = _statusFrom(payload);

        if (statusCode >= 200 && statusCode < 300 && _isHealthyStatus(status)) {
          return const HealthCheckResult(isHealthy: true, message: 'Service healthy');
        }

        if (statusCode >= 200 && statusCode < 300 && status.isEmpty) {
          return const HealthCheckResult(isHealthy: true, message: 'Service reachable');
        }

        return HealthCheckResult(
          isHealthy: false,
          message: 'Service status: ${status.isEmpty ? statusCode.toString() : status}',
        );
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) continue;

        return HealthCheckResult(
          isHealthy: false,
          message: error.message ?? 'Unable to reach health service',
        );
      } catch (_) {
        return const HealthCheckResult(
          isHealthy: false,
          message: 'Unable to verify service health',
        );
      }
    }

    return const HealthCheckResult(
      isHealthy: false,
      message: 'Health endpoint is unavailable',
    );
  }

  String _statusFrom(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map && data['status'] != null) {
      return data['status'].toString().toLowerCase();
    }
    return payload['status']?.toString().toLowerCase() ?? '';
  }

  bool _isHealthyStatus(String status) {
    return status == 'ok' || status == 'healthy' || status == 'pass';
  }
}
