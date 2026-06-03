// models/skin_analysis_model.dart

enum SkinConcernStatus { good, moderate, needsCare }

extension SkinConcernStatusExtension on SkinConcernStatus {
  String get label {
    switch (this) {
      case SkinConcernStatus.good:
        return 'Good';
      case SkinConcernStatus.moderate:
        return 'Moderate';
      case SkinConcernStatus.needsCare:
        return 'Needs Care';
    }
  }

  // Returns hex color string matching Skinova's palette
  String get colorHex {
    switch (this) {
      case SkinConcernStatus.good:
        return '#4CAF82'; // soft green
      case SkinConcernStatus.moderate:
        return '#E8A838'; // amber
      case SkinConcernStatus.needsCare:
        return '#5B2333'; // wine
    }
  }
}

class SkinConcern {
  final String name;
  final double severityScore; // 0.0 – 1.0
  final SkinConcernStatus status;
  final String description;

  const SkinConcern({
    required this.name,
    required this.severityScore,
    required this.status,
    required this.description,
  });

  factory SkinConcern.fromRoboflowPrediction({
    required String className,
    required double confidence,
    required int detectionCount,
  }) {
    final status = _statusFromScore(confidence, detectionCount);
    return SkinConcern(
      name: _labelFromClass(className),
      severityScore: confidence,
      status: status,
      description: _descriptionFromClass(className),
    );
  }

  static SkinConcernStatus _statusFromScore(
      double confidence, int detectionCount) {
    final blended =
        (confidence * 0.6) + (_normalizeCount(detectionCount) * 0.4);
    if (blended < 0.35) return SkinConcernStatus.good;
    if (blended < 0.65) return SkinConcernStatus.moderate;
    return SkinConcernStatus.needsCare;
  }

  static double _normalizeCount(int count) {
    if (count <= 1) return 0.1;
    if (count <= 3) return 0.35;
    if (count <= 6) return 0.60;
    if (count <= 10) return 0.80;
    return 1.0;
  }

  static String _labelFromClass(String cls) {
    const map = {
      'acne': 'Acne',
      'blackhead': 'Blackheads',
      'blackheads': 'Blackheads',
      'whitehead': 'Whiteheads',
      'whiteheads': 'Whiteheads',
      'pore': 'Open Pores',
      'pores': 'Open Pores',
      'freckle': 'Freckles',
      'freckles': 'Freckles',
      'acne_scar': 'Acne Scars',
      'acne-scar': 'Acne Scars',
      'scar': 'Acne Scars',
      'wrinkle': 'Wrinkles',
      'wrinkles': 'Wrinkles',
      'dark_circle': 'Dark Circles',
      'dark-circle': 'Dark Circles',
      'dark_circles': 'Dark Circles',
    };
    return map[cls.toLowerCase()] ?? cls;
  }

  static String _descriptionFromClass(String cls) {
    const map = {
      'acne': 'Inflamed hair follicles causing pimples and redness.',
      'blackhead':
          'Clogged pores with oxidised sebum visible on the skin surface.',
      'blackheads':
          'Clogged pores with oxidised sebum visible on the skin surface.',
      'whitehead':
          'Closed comedones filled with sebum trapped beneath the skin.',
      'whiteheads':
          'Closed comedones filled with sebum trapped beneath the skin.',
      'pore': 'Enlarged hair follicle openings that appear as small holes.',
      'pores': 'Enlarged hair follicle openings that appear as small holes.',
      'freckle':
          'Small flat spots caused by sun exposure and melanin clusters.',
      'freckles':
          'Small flat spots caused by sun exposure and melanin clusters.',
      'acne_scar': 'Post-inflammatory marks left after acne lesions heal.',
      'scar': 'Post-inflammatory marks left after acne lesions heal.',
      'wrinkle': 'Fine lines caused by loss of skin elasticity over time.',
      'wrinkles': 'Fine lines caused by loss of skin elasticity over time.',
      'dark_circle':
          'Discolouration beneath the eyes caused by pigmentation or fatigue.',
      'dark_circles':
          'Discolouration beneath the eyes caused by pigmentation or fatigue.',
    };
    return map[cls.toLowerCase()] ??
        'Detected concern that may need attention.';
  }
}

// ──────────────────────────────────────────────

class RoutineStep {
  final String stepName;
  final String why;
  final String productCategory;
  final String keyIngredient;
  final List<String> searchTags;
  final String concernTarget;
  final String frequency;
  final String timeOfDay;

  const RoutineStep({
    required this.stepName,
    required this.why,
    required this.productCategory,
    required this.keyIngredient,
    this.searchTags = const [],
    this.concernTarget = '',
    this.frequency = 'daily',
    this.timeOfDay = '',
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      stepName: json['stepName'] as String? ?? '',
      why: json['why'] as String? ?? '',
      productCategory: json['productCategory'] as String? ?? '',
      keyIngredient: json['keyIngredient'] as String? ?? '',
      searchTags: (json['searchTags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      concernTarget: json['concernTarget'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'daily',
      timeOfDay: json['timeOfDay'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'stepName': stepName,
        'why': why,
        'productCategory': productCategory,
        'keyIngredient': keyIngredient,
        'searchTags': searchTags,
        'concernTarget': concernTarget,
        'frequency': frequency,
        'timeOfDay': timeOfDay,
      };
}

class SkinRoutine {
  final List<RoutineStep> morning;
  final List<RoutineStep> evening;

  const SkinRoutine({required this.morning, required this.evening});

  factory SkinRoutine.fromJson(Map<String, dynamic> json) {
    return SkinRoutine(
      morning: (json['morning'] as List<dynamic>)
          .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      evening: (json['evening'] as List<dynamic>)
          .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'morning': morning.map((s) => s.toJson()).toList(),
        'evening': evening.map((s) => s.toJson()).toList(),
      };
}

// ──────────────────────────────────────────────

class SkinAnalysisResult {
  final List<SkinConcern> concerns;
  final SkinRoutine routine;
  final DateTime analyzedAt;

  const SkinAnalysisResult({
    required this.concerns,
    required this.routine,
    required this.analyzedAt,
  });

  /// Overall skin status – driven by the worst concern found
  SkinConcernStatus get overallStatus {
    if (concerns.isEmpty) return SkinConcernStatus.good;
    if (concerns.any((c) => c.status == SkinConcernStatus.needsCare)) {
      return SkinConcernStatus.needsCare;
    }
    if (concerns.any((c) => c.status == SkinConcernStatus.moderate)) {
      return SkinConcernStatus.moderate;
    }
    return SkinConcernStatus.good;
  }

  bool get hasMoreConcerns => concerns.length > 3;
  List<SkinConcern> get topConcerns => concerns.take(3).toList();
}
