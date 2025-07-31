import 'package:thesis_sys_app/models/user_model.dart';

class Thesis {
  final int? id;
  final int userId;
  final String title;
  final String abstractText;
  final String filePath;
  final String department;
  final String status;
  final User? user;

  Thesis({
    this.id,
    required this.userId,
    required this.title,
    required this.abstractText,
    required this.filePath,
    required this.department,
    required this.status,
    this.user,
  });

  factory Thesis.fromJson(Map<String, dynamic> json) {
    return Thesis(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      abstractText: json['abstract'],
      filePath: json['file_path'],
      department: json['department'],
      status: json['status'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'abstract': abstractText,
      'file_path': filePath,
      'department': department,
      'status': status,
      'user': user?.toJson(),
    };
  }
}
