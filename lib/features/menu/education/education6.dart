import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';


class Education6Page extends StatelessWidget {
  const Education6Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part6_'],
      title: '교육 (6/6)',
    );
  }
}