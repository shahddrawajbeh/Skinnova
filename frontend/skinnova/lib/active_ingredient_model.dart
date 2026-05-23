class ActiveIngredientModel {
  final String id;
  final String name;
  final String slug;
  final String imageUrl;
  final String description;
  final List<String> suitableFor;

  ActiveIngredientModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.description,
    required this.suitableFor,
  });

  factory ActiveIngredientModel.fromJson(Map<String, dynamic> json) {
    return ActiveIngredientModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      suitableFor: List<String>.from(json['suitableFor'] ?? []),
    );
  }
}
