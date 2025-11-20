import 'package:flutter/material.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';


class Education7Page extends StatelessWidget {
  const Education7Page({super.key});

  @override
  Widget build(BuildContext context) {
    return EducationPage(
      jsonPrefixes: ['week1_relaxation_'],
      title: '점진적 이완 훈련 안내',
    );
  }
}