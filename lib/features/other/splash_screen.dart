import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 실행 시 처음 보여지는 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorage _tokens = TokenStorage();

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFlag = prefs.getBool('isLoggedIn') ?? false;
    final accessToken = await _tokens.access;
    final isLoggedIn = storedFlag && accessToken != null && accessToken.isNotEmpty;

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSplashUI();
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
