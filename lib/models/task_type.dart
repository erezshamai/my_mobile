class TaskType {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  const TaskType({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  TaskType copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return TaskType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskType.fromJson(Map<String, dynamic> json) {
    return TaskType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskType &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'TaskType(id: $id, name: $name, description: $description, createdAt: $createdAt)';
  }
}