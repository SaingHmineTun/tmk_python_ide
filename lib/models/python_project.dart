class PythonProject {
  const PythonProject({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  PythonProject copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PythonProject(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PythonProject.fromMap(Map<String, Object?> map) => PythonProject(
    id: map['id'] as int?,
    name: map['name'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}