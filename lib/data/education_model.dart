import 'dart:convert';
import 'package:flutter/services.dart';

class EducationContent {
  final String title;
  final List<String> paragraphs;

  EducationContent({required this.title, required this.paragraphs});

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      title: json['title'],
      paragraphs: List<String>.from(json['paragraphs']),
    );
  }
}

class EducationDataLoader {
  static Future<List<EducationContent>> loadContents(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((e) => EducationContent.fromJson(e)).toList();
  }

  static Future<bool> fileExists(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}