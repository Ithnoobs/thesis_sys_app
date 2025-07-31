class ClassSupervisor {
  final int? id;
  final int classesId;
  final int supervisorId;

  ClassSupervisor({
    this.id,
    required this.classesId,
    required this.supervisorId,
  });

  factory ClassSupervisor.fromJson(Map<String, dynamic> json) {
    return ClassSupervisor(
      id: json['id'],
      classesId: json['classes_id'],
      supervisorId: json['supervisor_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classes_id': classesId,
      'supervisor_id': supervisorId,
    };
  }
}
