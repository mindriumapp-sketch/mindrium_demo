import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';
import 'education5.dart';

class Education4Page extends StatelessWidget {
  const Education4Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part4_'],
      nextPageBuilder: () => Education5Page(),
      title: '교육 (4/6)',
    );
  }
}