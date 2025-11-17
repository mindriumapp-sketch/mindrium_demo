import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/users_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 앱 실행 시 처음 보여지는 스플래시 화면 (Mindrium 텍스트만 제거)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<bool> _initApp() async {
    final tokens = TokenStorage();
    final client = ApiClient(tokens: tokens);
    final usersApi = UsersApi(client);

    final access = await tokens.access;
    if (access == null) return false;

    try {
      await usersApi.me();
      return true;
    } catch (e) {
      await tokens.clear();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initApp(),
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
