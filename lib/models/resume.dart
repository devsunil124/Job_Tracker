import 'dart:convert';

class StoredResume {
  final String id;
  final String name;
  final String filePath;
  final String category; // "Core", "IT", "General"
  final DateTime dateAdded;
  final String? base64Content; // For Web persistence

  StoredResume({
    required this.id,
    required this.name,
    required this.filePath,
    required this.category,
    required this.dateAdded,
    this.base64Content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'category': category,
      'dateAdded': dateAdded.toIso8601String(),
      'base64Content': base64Content,
    };
  }

  factory StoredResume.fromMap(Map<String, dynamic> map) {
    return StoredResume(
      id: map['id'],
      name: map['name'],
      filePath: map['filePath'],
      category: map['category'],
      dateAdded: DateTime.parse(map['dateAdded']),
      base64Content: map['base64Content'],
    );
  }

  String toJson() => json.encode(toMap());

  factory StoredResume.fromJson(String source) =>
      StoredResume.fromMap(json.decode(source));
}
