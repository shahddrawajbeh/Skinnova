class WhatsInsideModel {
  final bool alcoholFree;
  final bool euAllergenFree;
  final bool fragranceFree;
  final bool oilFree;
  final bool parabenFree;
  final bool siliconeFree;
  final bool sulfateFree;
  final bool crueltyFree;
  final bool fungalAcneSafe;
  final bool reefSafe;
  final bool vegan;

  WhatsInsideModel({
    required this.alcoholFree,
    required this.euAllergenFree,
    required this.fragranceFree,
    required this.oilFree,
    required this.parabenFree,
    required this.siliconeFree,
    required this.sulfateFree,
    required this.crueltyFree,
    required this.fungalAcneSafe,
    required this.reefSafe,
    required this.vegan,
  });

  factory WhatsInsideModel.fromJson(Map<String, dynamic> json) {
    return WhatsInsideModel(
      alcoholFree: json['alcoholFree'] ?? false,
      euAllergenFree: json['euAllergenFree'] ?? false,
      fragranceFree: json['fragranceFree'] ?? false,
      oilFree: json['oilFree'] ?? false,
      parabenFree: json['parabenFree'] ?? false,
      siliconeFree: json['siliconeFree'] ?? false,
      sulfateFree: json['sulfateFree'] ?? false,
      crueltyFree: json['crueltyFree'] ?? false,
      fungalAcneSafe: json['fungalAcneSafe'] ?? false,
      reefSafe: json['reefSafe'] ?? false,
      vegan: json['vegan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alcoholFree': alcoholFree,
      'euAllergenFree': euAllergenFree,
      'fragranceFree': fragranceFree,
      'oilFree': oilFree,
      'parabenFree': parabenFree,
      'siliconeFree': siliconeFree,
      'sulfateFree': sulfateFree,
      'crueltyFree': crueltyFree,
      'fungalAcneSafe': fungalAcneSafe,
      'reefSafe': reefSafe,
      'vegan': vegan,
    };
  }
}
