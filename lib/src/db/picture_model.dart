import 'dart:convert';

import 'package:objectbox/objectbox.dart';

@Entity()
class Picture {
  int id;
  final String title;
  final DateTime date;
  final String picture;

  Picture({
    this.id = 0,
    required this.title,
    required this.date,
    required this.picture,
  });

  Picture copyWith({
    int? id,
    String? title,
    DateTime? date,
    String? picture,
  }) {
    return Picture(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      picture: picture ?? this.picture,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'title': title});
    result.addAll({'date': date.millisecondsSinceEpoch});
    result.addAll({'picture': picture});

    return result;
  }

  factory Picture.fromMap(Map<String, dynamic> map) {
    return Picture(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      picture: map['picture'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Picture.fromJson(String source) =>
      Picture.fromMap(json.decode(source));
}
