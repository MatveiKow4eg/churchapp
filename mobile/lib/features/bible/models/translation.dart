class Translation {
  const Translation({
    required this.id,
    required this.name,
    required this.languageName,
    required this.englishName,
    required this.listOfBooksApiLink,
    required this.textDirection,
    required this.rawJson,
  });

  final String id;
  final String name;
  final String languageName;
  final String englishName;
  final String listOfBooksApiLink;
  final String textDirection;

  /// Keeps the original payload for forward compatibility.
  final Map<String, dynamic> rawJson;

  factory Translation.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v is String ? v : (v?.toString() ?? '');

    return Translation(
      id: str(json['id']),
      name: str(json['name']),
      languageName: str(json['language_name']),
      englishName: str(json['english_name']),
      listOfBooksApiLink: str(json['list_of_books_api_link']),
      textDirection: str(json['text_direction']),
      rawJson: json,
    );
  }
}
