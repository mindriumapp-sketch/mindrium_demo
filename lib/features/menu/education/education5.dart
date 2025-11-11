import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';
import 'education6.dart';

class Education5Page extends StatelessWidget {
  const Education5Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part5_'],
      nextPageBuilder: () => Education6Page(),
      title: '교육 (5/6)',
    );
  }
}