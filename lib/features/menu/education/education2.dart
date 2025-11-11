import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';
import 'education3.dart';

class Education2Page extends StatelessWidget {
  const Education2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_part2_'],
      nextPageBuilder: () => Education3Page(),
      title: '교육 (2/6)',
    );
  }
}
