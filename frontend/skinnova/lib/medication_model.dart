class MedicationModel {
  final String id;
  final String name;
  final List<String> soldAs;
  final List<String> treats;
  final String description;
  final String medicalDescription;
  final List<String> references;

  MedicationModel({
    required this.id,
    required this.name,
    required this.soldAs,
    required this.treats,
    required this.description,
    required this.medicalDescription,
    required this.references,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      soldAs: List<String>.from(json["soldAs"] ?? []),
      treats: List<String>.from(json["treats"] ?? []),
      description: json["description"] ?? "",
      medicalDescription: json["medicalDescription"] ?? "",
      references: List<String>.from(json["references"] ?? []),
    );
  }
}
