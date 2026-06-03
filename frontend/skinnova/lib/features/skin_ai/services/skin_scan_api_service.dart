import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:skinnova/api_service.dart';
import 'package:skinnova/features/skin_ai/models/skin_analysis_model.dart';
import 'package:skinnova/features/skin_ai/models/skin_scan_history_model.dart';

class SkinScanApiService {
  static String get _base => '${ApiService.baseUrl}/api/skin-scan';
  static Future<SkinScanModel?> saveScan({
    required String userId,
    required File imageFile,
    required SkinAnalysisResult result,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_base));

    request.fields['userId'] = userId;
    request.fields['overallStatus'] = result.overallStatus.label;

    request.fields['detectedConcerns'] = jsonEncode(
      result.concerns
          .map((c) => {
                'name': c.name,
                'severityScore': c.severityScore,
                'status': c.status.label,
                'description': c.description,
              })
          .toList(),
    );

    request.fields['morningRoutine'] = jsonEncode(
      result.routine.morning.map((s) => s.toJson()).toList(),
    );

    request.fields['eveningRoutine'] = jsonEncode(
      result.routine.evening.map((s) => s.toJson()).toList(),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 201) {
      return SkinScanModel.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
    }

    final data = jsonDecode(body);
    throw Exception(data['message'] ?? 'Failed to save scan');
  }

  /// Save a completed scan. Returns the saved document or null on failure.
  // static Future<SkinScanModel?> saveScan({
  //   required String userId,
  //   required File imageFile,
  //   required SkinAnalysisResult result,
  // }) async {
  //   try {
  //     final request = http.MultipartRequest('POST', Uri.parse(_base));
  //     request.fields['userId'] = userId;
  //     request.fields['overallStatus'] = result.overallStatus.label;
  //     request.fields['detectedConcerns'] = jsonEncode(
  //       result.concerns
  //           .map((c) => {
  //                 'name': c.name,
  //                 'severityScore': c.severityScore,
  //                 'status': c.status.label,
  //                 'description': c.description,
  //               })
  //           .toList(),
  //     );
  //     request.fields['morningRoutine'] = jsonEncode(
  //       result.routine.morning.map((s) => s.toJson()).toList(),
  //     );
  //     request.fields['eveningRoutine'] = jsonEncode(
  //       result.routine.evening.map((s) => s.toJson()).toList(),
  //     );
  //     request.files
  //         .add(await http.MultipartFile.fromPath('image', imageFile.path));

  //     final streamed = await request.send();
  //     final body = await streamed.stream.bytesToString();
  //     if (streamed.statusCode == 201) {
  //       return SkinScanModel.fromJson(
  //           jsonDecode(body) as Map<String, dynamic>);
  //     }
  //   } catch (_) {}
  //   return null;
  // }

  /// Fetch all scans for a user (newest first).
  static Future<List<SkinScanModel>> getHistory(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_base/history/$userId'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => SkinScanModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch a single scan by ID.
  static Future<SkinScanModel?> getScan(String scanId) async {
    try {
      final res = await http.get(Uri.parse('$_base/$scanId'));
      if (res.statusCode == 200) {
        return SkinScanModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Delete a scan by ID.
  static Future<bool> deleteScan(String scanId) async {
    try {
      final res = await http.delete(Uri.parse('$_base/$scanId'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
