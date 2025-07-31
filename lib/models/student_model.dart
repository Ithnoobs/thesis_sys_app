import 'package:thesis_sys_app/models/classes_model.dart';
import 'package:thesis_sys_app/models/user_model.dart';

class Student {
  final int? id;
  final int classesId;
  final int userId;
  final Classes? classInfo;
  final User? user;

  Student({
    this.id,
    required this.classesId,
    required this.userId,
    this.classInfo,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      classesId: json['classes_id'],
      userId: json['user_id'],
      classInfo: json['class'] != null ? Classes.fromJson(json['class']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classes_id': classesId,
      'user_id': userId,
      'class': classInfo?.toJson(),
      'user': user?.toJson(),
    };
  }
}
