class ChurchModel {
  const ChurchModel({
    required this.id,
    required this.name,
    this.city,
  });

  final String id;
  final String name;
  final String? city;

  factory ChurchModel.fromJson(Map<String, dynamic> json) {
    return ChurchModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
    };
  }
}
