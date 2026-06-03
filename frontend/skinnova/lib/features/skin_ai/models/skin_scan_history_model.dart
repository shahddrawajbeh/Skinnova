class SkinScanModel {
  final String id;
  final String userId;
  final String imageUrl;
  final List<ScanConcern> detectedConcerns;
  final String overallStatus;
  final double? skinScore;
  final List<ScanRoutineStep> morningRoutine;
  final List<ScanRoutineStep> eveningRoutine;
  final DateTime createdAt;

  const SkinScanModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.detectedConcerns,
    required this.overallStatus,
    this.skinScore,
    required this.morningRoutine,
    required this.eveningRoutine,
    required this.createdAt,
  });

  int get concernCount => detectedConcerns.length;
  List<ScanConcern> get topConcerns => detectedConcerns.take(3).toList();

  factory SkinScanModel.fromJson(Map<String, dynamic> json) {
    return SkinScanModel(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      detectedConcerns: (json['detectedConcerns'] as List<dynamic>? ?? [])
          .map((e) => ScanConcern.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallStatus: json['overallStatus'] as String? ?? '',
      skinScore: json['skinScore'] != null
          ? (json['skinScore'] as num).toDouble()
          : null,
      morningRoutine: (json['morningRoutine'] as List<dynamic>? ?? [])
          .map((e) => ScanRoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      eveningRoutine: (json['eveningRoutine'] as List<dynamic>? ?? [])
          .map((e) => ScanRoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ScanConcern {
  final String name;
  final double severityScore;
  final String status;
  final String description;

  const ScanConcern({
    required this.name,
    required this.severityScore,
    required this.status,
    required this.description,
  });

  factory ScanConcern.fromJson(Map<String, dynamic> json) => ScanConcern(
        name: json['name'] as String? ?? '',
        severityScore: (json['severityScore'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'severityScore': severityScore,
        'status': status,
        'description': description,
      };
}

class ScanRoutineStep {
  final String stepName;
  final String why;
  final String productCategory;
  final String keyIngredient;
  final String frequency;
  final String timeOfDay;

  const ScanRoutineStep({
    required this.stepName,
    required this.why,
    required this.productCategory,
    required this.keyIngredient,
    this.frequency = 'daily',
    this.timeOfDay = '',
  });

  factory ScanRoutineStep.fromJson(Map<String, dynamic> json) =>
      ScanRoutineStep(
        stepName: json['stepName'] as String? ?? '',
        why: json['why'] as String? ?? '',
        productCategory: json['productCategory'] as String? ?? '',
        keyIngredient: json['keyIngredient'] as String? ?? '',
        frequency: json['frequency'] as String? ?? 'daily',
        timeOfDay: json['timeOfDay'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'stepName': stepName,
        'why': why,
        'productCategory': productCategory,
        'keyIngredient': keyIngredient,
        'frequency': frequency,
        'timeOfDay': timeOfDay,
      };
}
