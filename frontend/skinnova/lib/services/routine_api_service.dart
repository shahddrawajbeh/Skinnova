import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skinnova/api_service.dart';
import 'package:skinnova/product_model.dart';
import 'package:skinnova/features/skin_ai/models/skin_analysis_model.dart';

class RoutineApiService {
  static String get _base => '${ApiService.baseUrl}/api/routines';

  // ── Save AI routine ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> saveAiRoutine({
    required String userId,
    required SkinRoutine routine,
    required List<String> detectedConcerns,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/ai'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'detectedConcerns': detectedConcerns,
        'morning': routine.morning.map((s) => s.toJson()).toList(),
        'evening': routine.evening.map((s) => s.toJson()).toList(),
      }),
    );
    print("SAVE ROUTINE URL: $_base/ai");
    print("SAVE ROUTINE STATUS: ${res.statusCode}");
    print("SAVE ROUTINE BODY: ${res.body}");
    if (res.statusCode == 201)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  // ── Get active routine ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getActiveRoutine(String userId) async {
    final res = await http.get(Uri.parse('$_base/active/$userId'));
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  // ── Custom steps ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> addCustomStep({
    required String userId,
    required RoutineStep step,
    String notes = '',
    String reminderTime = '',
  }) async {
    final stepJson = step.toJson()
      ..['notes'] = notes
      ..['reminderTime'] = reminderTime;
    final res = await http.post(
      Uri.parse('$_base/custom-step'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'step': stepJson}),
    );
    if (res.statusCode == 201)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  static Future<Map<String, dynamic>?> updateCustomStep({
    required String routineId,
    required String stepId,
    required RoutineStep step,
    String notes = '',
    String reminderTime = '',
  }) async {
    final stepJson = step.toJson()
      ..['notes'] = notes
      ..['reminderTime'] = reminderTime;
    final res = await http.put(
      Uri.parse('$_base/custom-step/$routineId/$stepId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(stepJson),
    );
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  static Future<bool> deleteCustomStep({
    required String routineId,
    required String stepId,
  }) async {
    final res = await http.delete(
      Uri.parse('$_base/custom-step/$routineId/$stepId'),
    );
    return res.statusCode == 200;
  }

  // ── Progress ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> toggleStepDone({
    required String userId,
    required String routineId,
    required String stepId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/progress/toggle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'userId': userId, 'routineId': routineId, 'stepId': stepId}),
    );
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  static Future<Map<String, dynamic>?> getRoutineProgress({
    required String userId,
    required String routineId,
  }) async {
    final res = await http.get(Uri.parse('$_base/progress/$userId/$routineId'));
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  // ── Recommended products ───────────────────────────────────────────────────

  static Future<List<ProductModel>> getRecommendedProducts({
    required String productCategory,
    required String keyIngredient,
    List<String> searchTags = const [],
    String concernTarget = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/recommended-products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productCategory': productCategory,
          'keyIngredient': keyIngredient,
          'searchTags': searchTags,
          'concernTarget': concernTarget,
        }),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
