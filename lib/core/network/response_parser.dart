import 'dart:convert';
import 'package:dio/dio.dart';

class ApiResponseParser {
  /// Extract the logical `data` payload from common backend envelopes.
  /// Supports shapes:
  /// A: {"data": [...]}
  /// B: {"data": {"results": [...]}}
  /// C: {"results": [...]}
  /// D: []
  /// E: {"data": {"items": [...]}}
  static dynamic extractData(Response resp) {
    dynamic raw = resp.data;
    try {
      if (raw is String) raw = json.decode(raw);
    } catch (_) {
      // not JSON decodable
      return null;
    }
    if (raw is List) return raw;
    if (raw is Map) {
      final safe = Map<String, dynamic>.from(raw);
      // Prefer explicit `data` envelope
      final data = safe['data'];
      if (data != null) {
        if (data is List) return data;
        if (data is Map) {
          final nested = Map<String, dynamic>.from(data);
          final candidate = nested['results'] ?? nested['items'] ?? nested['articles'] ?? nested['data'];
          if (candidate is List) return candidate;
          return nested;
        }
        return data;
      }

      // Fallback to top-level results/items
      final topCandidate = safe['results'] ?? safe['items'] ?? safe['articles'] ?? safe['data'];
      if (topCandidate is List) return topCandidate;

      return safe;
    }

    return null;
  }

  static List<Map<String, dynamic>> extractList(Response resp) {
    final data = extractData(resp);
    if (data == null) return <Map<String, dynamic>>[];
    if (data is List) {
      return data.map<Map<String, dynamic>>((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{'value': e};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Map<String, dynamic> extractMap(Response resp) {
    dynamic raw = resp.data;
    try {
      if (raw is String) raw = json.decode(raw);
    } catch (_) {
      return <String, dynamic>{};
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) return Map<String, dynamic>.from(raw.first);
    return <String, dynamic>{};
  }
}

/// Backwards-compatible helpers used across the codebase.
List<Map<String, dynamic>> parseListResponse(Response resp) => ApiResponseParser.extractList(resp);
Map<String, dynamic> parseMapResponse(Response resp) => ApiResponseParser.extractMap(resp);

