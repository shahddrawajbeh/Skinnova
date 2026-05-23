class RecommendedForModel {
  final List<String> skinTypes;
  final List<String> concerns;
  final List<String> goals;

  RecommendedForModel({
    required this.skinTypes,
    required this.concerns,
    required this.goals,
  });

  factory RecommendedForModel.fromJson(Map<String, dynamic> json) {
    return RecommendedForModel(
      skinTypes: List<String>.from(json['skinTypes'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      goals: List<String>.from(json['goals'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skinTypes': skinTypes,
      'concerns': concerns,
      'goals': goals,
    };
  }
}
