// services/skin_analysis_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../models/skin_analysis_model.dart';
import 'package:skinnova/config/api_config.dart';

const _roboflowApiKey = ApiConfig.roboflowApiKey;
const _roboflowProjectUrl = ApiConfig.roboflowProjectUrl;

const _routineApiUrl = ApiConfig.routineApiUrl;
const _anthropicApiKey = ApiConfig.anthropicApiKey;

/// Replace with your actual Roboflow API key and project details.

// ─────────────────────────────────────────────────────────────────────────────
// Image validation
// ─────────────────────────────────────────────────────────────────────────────

enum ImageValidationError {
  tooBlurry,
  tooSmall,
  tooDark,
  noFaceDetected,
  none,
}

class ImageValidationResult {
  final bool isValid;
  final ImageValidationError error;
  const ImageValidationResult(this.isValid,
      [this.error = ImageValidationError.none]);
}

class SkinAnalysisService {
  // ── Public API ────────────────────────────────────────────────────────────

  /// Validate that the image is suitable for skin analysis.
  static Future<ImageValidationResult> validateImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const ImageValidationResult(
            false, ImageValidationError.tooSmall);
      }

      // Minimum resolution: 200×200
      if (decoded.width < 200 || decoded.height < 200) {
        return const ImageValidationResult(
            false, ImageValidationError.tooSmall);
      }

      // Brightness check – average luminance
      final avgLum = _averageLuminance(decoded);
      if (avgLum < 40) {
        return const ImageValidationResult(false, ImageValidationError.tooDark);
      }

      // Blur check – Laplacian variance
      final blurScore = _laplacianVariance(decoded);
      if (blurScore < 80) {
        return const ImageValidationResult(
            false, ImageValidationError.tooBlurry);
      }

      return const ImageValidationResult(true);
    } catch (_) {
      return const ImageValidationResult(false, ImageValidationError.tooSmall);
    }
  }

  /// Run the full analysis pipeline: Roboflow detection → routine generation.
  static Future<SkinAnalysisResult> analyze(File imageFile) async {
    // 1. Convert to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 2. Call Roboflow
    final concerns = await _callRoboflow(base64Image);

    // 3. Generate personalised routine (AI or fallback)
    final routine = await _generateRoutine(concerns);

    return SkinAnalysisResult(
      concerns: concerns,
      routine: routine,
      analyzedAt: DateTime.now(),
    );
  }

  // ── Roboflow ──────────────────────────────────────────────────────────────

  static Future<List<SkinConcern>> _callRoboflow(String base64Image) async {
    try {
      final uri = Uri.parse('$_roboflowProjectUrl?api_key=$_roboflowApiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Roboflow error ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = json['predictions'] as List<dynamic>? ?? [];

      // Aggregate by class name
      final Map<String, _ClassStats> statsMap = {};
      for (final pred in predictions) {
        final cls = (pred['class'] as String).toLowerCase();
        final conf = (pred['confidence'] as num).toDouble();
        statsMap.update(
          cls,
          (s) => _ClassStats(s.totalConfidence + conf, s.count + 1),
          ifAbsent: () => _ClassStats(conf, 1),
        );
      }

      // Build SkinConcern list sorted by severity (highest first)
      final concerns = statsMap.entries.map((e) {
        final avg = e.value.totalConfidence / e.value.count;
        return SkinConcern.fromRoboflowPrediction(
          className: e.key,
          confidence: avg,
          detectionCount: e.value.count,
        );
      }).toList()
        ..sort((a, b) => b.severityScore.compareTo(a.severityScore));

      return concerns;
    } catch (e) {
      // Return mock data when API is unavailable (development fallback)
      return _mockConcerns();
    }
  }

  // ── Routine generation ────────────────────────────────────────────────────

  static Future<SkinRoutine> _generateRoutine(
      List<SkinConcern> concerns) async {
    if (concerns.isEmpty) return _defaultRoutine();

    final concernNames = concerns.map((c) => c.name).join(', ');

    try {
      final response = await http.post(
        Uri.parse(_routineApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': '''
You are a professional dermatologist and skincare expert.
The user has the following detected skin concerns: $concernNames.

Create a personalised skincare routine in JSON format only (no markdown, no extra text).
The JSON must match this exact schema:
{
  "morning": [
    {
      "stepName": "string",
      "why": "string (one sentence explaining why this step helps the detected concerns)",
      "productCategory": "string (e.g. Gentle Cleanser, Vitamin C Serum)",
      "keyIngredient": "string (e.g. Niacinamide, Salicylic Acid)",
      "searchTags": ["string", "string"],
      "concernTarget": "string (the main concern this step targets)",
      "frequency": "daily or 2-3 times per week or weekly",
      "timeOfDay": "morning"
    }
  ],
  "evening": [ ... same structure with timeOfDay set to evening ... ]
}

Include 4–5 steps for morning and 4–5 steps for evening. Be specific and relevant to the concerns.
'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['content'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join('');
        final routineJson = jsonDecode(content.trim()) as Map<String, dynamic>;
        return SkinRoutine.fromJson(routineJson);
      }
    } catch (_) {}

    return _fallbackRoutine(concerns);
  }

  // ── Image quality helpers ────────────────────────────────────────────────

  static double _averageLuminance(img.Image image) {
    double total = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        total += 0.2126 * r + 0.7152 * g + 0.0722 * b;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  static double _laplacianVariance(img.Image image) {
    // Simple sharpness measure
    final grey = img.grayscale(image);
    double sum = 0;
    double sumSq = 0;
    int n = 0;

    for (int y = 1; y < grey.height - 1; y++) {
      for (int x = 1; x < grey.width - 1; x++) {
        final center = grey.getPixel(x, y).r.toInt();
        final top = grey.getPixel(x, y - 1).r.toInt();
        final bottom = grey.getPixel(x, y + 1).r.toInt();
        final left = grey.getPixel(x - 1, y).r.toInt();
        final right = grey.getPixel(x + 1, y).r.toInt();
        final lap = (4 * center - top - bottom - left - right).toDouble();
        sum += lap;
        sumSq += lap * lap;
        n++;
      }
    }
    if (n == 0) return 0;
    final mean = sum / n;
    return sumSq / n - mean * mean;
  }

  // ── Fallbacks / mock data ─────────────────────────────────────────────────

  static List<SkinConcern> _mockConcerns() => [
        SkinConcern.fromRoboflowPrediction(
            className: 'acne', confidence: 0.72, detectionCount: 5),
        SkinConcern.fromRoboflowPrediction(
            className: 'blackheads', confidence: 0.61, detectionCount: 8),
        SkinConcern.fromRoboflowPrediction(
            className: 'pores', confidence: 0.55, detectionCount: 12),
        SkinConcern.fromRoboflowPrediction(
            className: 'acne_scar', confidence: 0.44, detectionCount: 3),
        SkinConcern.fromRoboflowPrediction(
            className: 'dark_circles', confidence: 0.38, detectionCount: 2),
      ];

  static SkinRoutine _defaultRoutine() => const SkinRoutine(
        morning: [
          RoutineStep(
            stepName: 'Gentle Cleanse',
            why: 'Removes overnight sebum without stripping the skin barrier.',
            productCategory: 'Gentle Foaming Cleanser',
            keyIngredient: 'Ceramides',
          ),
          RoutineStep(
            stepName: 'Toner',
            why: 'Balances skin pH and preps skin for serums.',
            productCategory: 'Hydrating Toner',
            keyIngredient: 'Hyaluronic Acid',
          ),
          RoutineStep(
            stepName: 'Moisturise',
            why: 'Locks in hydration and maintains barrier function.',
            productCategory: 'Lightweight Moisturiser',
            keyIngredient: 'Niacinamide',
          ),
          RoutineStep(
            stepName: 'Sun Protection',
            why: 'Shields skin from UV-induced damage and pigmentation.',
            productCategory: 'Broad-Spectrum SPF 50',
            keyIngredient: 'Zinc Oxide',
          ),
        ],
        evening: [
          RoutineStep(
            stepName: 'Double Cleanse',
            why: 'Removes SPF and makeup before water-based cleanse.',
            productCategory: 'Cleansing Oil + Gentle Cleanser',
            keyIngredient: 'Jojoba Oil',
          ),
          RoutineStep(
            stepName: 'Exfoliate (2–3×/week)',
            why: 'Resurfaces skin and unclogs pores gently.',
            productCategory: 'Chemical Exfoliant',
            keyIngredient: 'Lactic Acid',
          ),
          RoutineStep(
            stepName: 'Targeted Serum',
            why: 'Addresses specific skin concerns overnight.',
            productCategory: 'Treatment Serum',
            keyIngredient: 'Retinol',
          ),
          RoutineStep(
            stepName: 'Night Moisturiser',
            why: 'Supports skin repair during sleep.',
            productCategory: 'Rich Night Cream',
            keyIngredient: 'Peptides',
          ),
        ],
      );

  static SkinRoutine _fallbackRoutine(List<SkinConcern> concerns) {
    final names = concerns.map((c) => c.name.toLowerCase()).toSet();
    final hasAcne = names.any((n) => n.contains('acne'));
    final hasPigment = names.any((n) =>
        n.contains('freckle') || n.contains('scar') || n.contains('dark'));
    final hasWrinkle = names.any((n) => n.contains('wrinkle'));

    final morning = <RoutineStep>[
      const RoutineStep(
        stepName: 'Cleanse',
        why: 'Removes overnight oil and prepares skin for actives.',
        productCategory: 'Gentle Gel Cleanser',
        keyIngredient: 'Salicylic Acid',
      ),
      if (hasAcne)
        const RoutineStep(
          stepName: 'Acne Serum',
          why: 'Targets active breakouts and reduces inflammation.',
          productCategory: 'BHA Serum',
          keyIngredient: 'Salicylic Acid 2%',
        ),
      if (hasPigment)
        const RoutineStep(
          stepName: 'Brightening Serum',
          why: 'Fades dark spots and evens skin tone.',
          productCategory: 'Vitamin C Serum',
          keyIngredient: 'Ascorbic Acid 15%',
        ),
      const RoutineStep(
        stepName: 'Hydrate',
        why: 'Maintains moisture balance under SPF.',
        productCategory: 'Oil-Free Moisturiser',
        keyIngredient: 'Hyaluronic Acid',
      ),
      const RoutineStep(
        stepName: 'SPF',
        why: 'Prevents UV darkening of scars and pigmentation.',
        productCategory: 'SPF 50 Sunscreen',
        keyIngredient: 'Titanium Dioxide',
      ),
    ];

    final evening = <RoutineStep>[
      const RoutineStep(
        stepName: 'Double Cleanse',
        why: 'Fully removes sunscreen and daily impurities.',
        productCategory: 'Cleansing Balm + Gel Cleanser',
        keyIngredient: 'Micellar Water',
      ),
      if (hasAcne)
        const RoutineStep(
          stepName: 'Spot Treatment',
          why: 'Dries out active pimples overnight.',
          productCategory: 'Benzoyl Peroxide Spot Cream',
          keyIngredient: 'Benzoyl Peroxide 2.5%',
        ),
      if (hasWrinkle)
        const RoutineStep(
          stepName: 'Retinol Treatment',
          why: 'Stimulates collagen production and softens fine lines.',
          productCategory: 'Retinol Serum',
          keyIngredient: 'Retinol 0.3%',
        ),
      if (hasPigment)
        const RoutineStep(
          stepName: 'AHA Exfoliant (3×/week)',
          why: 'Resurfaces skin and reduces post-acne marks.',
          productCategory: 'AHA Toner',
          keyIngredient: 'Glycolic Acid',
        ),
      const RoutineStep(
        stepName: 'Night Repair Cream',
        why: 'Seals in actives and supports overnight skin renewal.',
        productCategory: 'Barrier Repair Moisturiser',
        keyIngredient: 'Ceramides + Peptides',
      ),
    ];

    return SkinRoutine(morning: morning, evening: evening);
  }
}

class _ClassStats {
  final double totalConfidence;
  final int count;
  const _ClassStats(this.totalConfidence, this.count);
}
