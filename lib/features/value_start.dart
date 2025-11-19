import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class ValueStartScreen extends StatefulWidget {
  final int weekNumber;
  final String weekTitle;
  final String weekDescription;
  final Widget Function() nextPageBuilder;

  const ValueStartScreen({
    super.key,
    required this.weekNumber,
    required this.weekTitle,
    required this.weekDescription,
    required this.nextPageBuilder,
  });

  @override
  State<ValueStartScreen> createState() => _ValueStartScreenState();
}

class _ValueStartScreenState extends State<ValueStartScreen> {
  String? _userName;
  String? _userValueGoal;
  bool _isLoading = true;

  final _page = PageController();
  int _index = 0;

  static const Color _navy = Color(0xFF263C69);
  static const Color _blue = Color(0xFF339DF1);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // UserProvider에서 사용자 이름 가져오기
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userName = userProvider.userName;
      
      // UserDataApi에서 value_goal 가져오기
      final apiClient = ApiClient(tokens: TokenStorage());
      final userDataApi = UserDataApi(apiClient);
      final valueGoalData = await userDataApi.getValueGoal();
      _userValueGoal = valueGoalData?['value_goal'] as String?;
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goNextOrStart() {
    if (_index == 0) {
      _page.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.nextPageBuilder()),
      );
    }
  }

  void _goPrev() {
    if (_index > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxCardWidth = MediaQuery.of(context).size.width - 34 * 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: '${widget.weekNumber}주차 - 시작하기'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                'assets/image/eduhome.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      _WelcomePage(
                        maxWidth: maxCardWidth,
                        navy: _navy,
                        blue: _blue,
                        name: _userName ?? '사용자',
                        value: _userValueGoal ?? '행복 가족 건강',
                        weekDescription: widget.weekDescription,
                      ),
                      _GuidePage(
                        maxWidth: maxCardWidth,
                        navy: _navy,
                        title: '${widget.weekNumber}주차 활동 안내',
                        subtitle: widget.weekTitle,
                        weekNumber: widget.weekNumber, // ✅ 추가
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 0, 34, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _index == 0 ? null : _goPrev,
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                            Colors.white.withOpacity(_index == 0 ? 0.5 : 1),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '이 전',
                            style: TextStyle(
                              color: _index == 0
                                  ? Colors.black38
                                  : _blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goNextOrStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '다 음',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  final double radius;
  final double borderWidth;
  final Color borderColor;
  final Widget child;

  const _OutlinedCard({
    required this.child,
    this.radius = 22,
    this.borderWidth = 4.0,
    this.borderColor = const Color(0xFF7EB9FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final double maxWidth;
  final Color navy;
  final Color blue;
  final String name;
  final String value;
  final String weekDescription;

  const _WelcomePage({
    required this.maxWidth,
    required this.navy,
    required this.blue,
    required this.name,
    required this.value,
    required this.weekDescription,
  });

  static const double _badgeWidth = 254.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 0),
      child: Center(
        child: _OutlinedCard(
          child: BlueWhiteCard(
            maxWidth: maxWidth,
            title: '$name님, 환영합니다!',
            titleStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263C69),
            ),
            outerColor: Colors.transparent,
            outerRadius: 22,
            outerExpand: EdgeInsets.zero,
            innerColor: Colors.white,
            innerRadius: 20,
            innerPadding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            dividerColor: const Color(0xFFE8EDF4),
            dividerWidth: 240,
            titleTopGap: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 36,
                      child: Container(
                        width: _badgeWidth,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: _badgeWidth,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        color: blue,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        '당신의 핵심 가치',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                Text(
                  weekDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: navy, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final double maxWidth;
  final Color navy;
  final String title;
  final String subtitle;
  final int weekNumber; // 추가

  const _GuidePage({
    required this.maxWidth,
    required this.navy,
    required this.title,
    required this.subtitle,
    required this.weekNumber, // 추가
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 0),
      child: Center(
        child: _OutlinedCard(
          child: BlueWhiteCard(
            maxWidth: maxWidth,
            title: title,
            titleStyle: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            outerColor: Colors.transparent,
            outerRadius: 22,
            outerExpand: EdgeInsets.zero,
            innerColor: Colors.white,
            innerRadius: 20,
            innerPadding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            dividerColor: const Color(0xFFE8EDF4),
            dividerWidth: 240,
            titleTopGap: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  weekNumber == 8
                      ? 'assets/image/jellyfish_8th.png'
                      : 'assets/image/pink3.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}