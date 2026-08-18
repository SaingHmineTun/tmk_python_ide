class PythonProgram {
  const PythonProgram({
    this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String code;
  final DateTime createdAt;
  final DateTime updatedAt;

  PythonProgram copyWith({
    int? id,
    String? name,
    String? code,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PythonProgram(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'code': code,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PythonProgram.fromMap(Map<String, Object?> map) => PythonProgram(
    id: map['id'] as int?,
    name: map['name'] as String,
    code: map['code'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
