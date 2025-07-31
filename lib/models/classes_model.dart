import 'package:thesis_sys_app/models/major_model.dart';
import 'package:thesis_sys_app/models/student_model.dart';
import 'package:thesis_sys_app/models/user_model.dart';

class Classes {
  final int? id;
  final String className;
  final int majorId;
  final Major? major;
  final List<Student>? students;
  final List<User>? supervisors;

  Classes({
    this.id,
    required this.className,
    required this.majorId,
    this.major,
    this.students,
    this.supervisors,
  });

  factory Classes.fromJson(Map<String, dynamic> json) {
    return Classes(
      id: json['id'],
      className: json['class_name'],
      majorId: json['major_id'],
      major: json['major'] != null ? Major.fromJson(json['major']) : null,
      students: json['students'] != null
          ? (json['students'] as List)
              .map((e) => Student.fromJson(e))
              .toList()
          : null,
      supervisors: json['supervisors'] != null
          ? (json['supervisors'] as List)
              .map((e) => User.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'major_id': majorId,
      'major': major?.toJson(),
      'students': students?.map((e) => e.toJson()).toList(),
      'supervisors': supervisors?.map((e) => e.toJson()).toList(),
    };
  }
}
