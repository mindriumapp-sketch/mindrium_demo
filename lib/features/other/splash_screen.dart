import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 실행 시 처음 보여지는 스플래시 화면
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool('isLoggedIn');
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSplashUI();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isLoggedIn = snapshot.data ?? false;
          Navigator.pushReplacementNamed(
            context,
            isLoggedIn ? '/home' : '/login',
          );
        });

        return _buildSplashUI();
      },
    );
  }

  Widget _buildSplashUI() {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Image.asset('assets/image/logo.png', width: 100, height: 100),
                const SizedBox(height: AppSizes.space),
                const CircularProgressIndicator(color: AppColors.indigo),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSizes.padding),
            child: Text(
              '걱정하지 마세요. 충분히 잘하고있어요.',
              style: TextStyle(
                fontSize: AppSizes.fontSize,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
