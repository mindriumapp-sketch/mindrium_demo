import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';
import 'education2.dart';

class Education1Page extends StatelessWidget {
  const Education1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part1_'],
      nextPageBuilder: () => Education2Page(),
      title: '교육 (1/6)',
    );
  }
}