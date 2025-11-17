import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';
import 'education4.dart';

class Education3Page extends StatelessWidget {
  const Education3Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part3_'],
      nextPageBuilder: () => Education4Page(),
      title: '교육 (3/6)',
    );
  }
}