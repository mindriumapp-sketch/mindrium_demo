import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// ✅ 블루 토스트 배너
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/users_api.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/api/auth_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/screen_time_provider.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> with WidgetsBindingObserver {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
<<<<<<< HEAD
  final TextEditingController coreValueController = TextEditingController();
=======
  final TextEditingController valueGoalController = TextEditingController();
>>>>>>> 7cf0a32 (1118 통합)
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isEditing = false;
  bool isLoading = true;
  bool showPasswordFields = false;
  bool _hasRefreshedWhileVisible = false;

  DateTime? createdAt;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final UsersApi _usersApi = UsersApi(_apiClient);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);
  late final AuthApi _authApi = AuthApi(_apiClient, _tokens);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ScreenTimeProvider>().load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleVisibilityRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshScreenTime();
    }
  }

  void _scheduleVisibilityRefresh() {
    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? true;
    if (!isCurrent) {
      _hasRefreshedWhileVisible = false;
      return;
    }
    if (_hasRefreshedWhileVisible) return;
    _hasRefreshedWhileVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshScreenTime();
    });
  }

  Future<void> _refreshScreenTime() async {
    if (!mounted) return;
    try {
      await context.read<ScreenTimeProvider>().refresh();
    } catch (_) {
<<<<<<< HEAD
      // ignore refresh errors on overview screen
=======
      // ignore overview refresh errors
>>>>>>> 7cf0a32 (1118 통합)
    }
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final me = await _usersApi.me();
      nameController.text = (me['name'] as String?) ?? '';
      emailController.text = (me['email'] as String?) ?? '';

      final rawCreatedAt = me['created_at'] ?? me['createdAt'];
      if (rawCreatedAt is String) {
        createdAt = DateTime.tryParse(rawCreatedAt);
      } else if (rawCreatedAt is DateTime) {
        createdAt = rawCreatedAt;
      }

      try {
<<<<<<< HEAD
        final coreValueRes = await _userDataApi.getCoreValue();
        final rawValue =
            coreValueRes?['value_goal'] ?? coreValueRes?['core_value'];
        coreValueController.text = (rawValue as String?) ?? '';
      } catch (_) {
        coreValueController.text = '';
=======
        final valueGoalRes = await _userDataApi.getValueGoal();
        final rawValue = valueGoalRes?['value_goal'];
        valueGoalController.text = (rawValue as String?) ?? '';
      } catch (_) {
        valueGoalController.text = '';
>>>>>>> 7cf0a32 (1118 통합)
      }
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      BlueBanner.show(context, message ?? '내 정보를 불러오지 못했어요.');
    } catch (e) {
      BlueBanner.show(context, '내 정보를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    setState(() => isLoading = true);

    final trimmedName = nameController.text.trim();
<<<<<<< HEAD
    final coreValue = coreValueController.text.trim();
=======
    final valueGoal = valueGoalController.text.trim();
>>>>>>> 7cf0a32 (1118 통합)
    final currentPw = currentPasswordController.text.trim();
    final newPw = newPasswordController.text.trim();
    final confirmPw = confirmPasswordController.text.trim();

    if (showPasswordFields && currentPw.isEmpty) {
      _showSnack('기존 비밀번호를 입력해야 합니다.');
      setState(() => isLoading = false);
      return;
    }

    if (newPw.isNotEmpty && newPw != confirmPw) {
      _showSnack('새 비밀번호가 일치하지 않습니다.');
      setState(() => isLoading = false);
      return;
    }

    try {
      if (trimmedName.isNotEmpty) {
        await _usersApi.updateMe({'name': trimmedName});
        final provider = context.read<UserProvider>();
        provider.updateUserName(trimmedName);
      }

<<<<<<< HEAD
      if (coreValue.isNotEmpty) {
        await _userDataApi.updateCoreValue(coreValue);
      } else {
        await _userDataApi.deleteCoreValue();
=======
      if (valueGoal.isNotEmpty) {
        await _userDataApi.updateValueGoal(valueGoal);
      } else {
        await _userDataApi.deleteValueGoal();
>>>>>>> 7cf0a32 (1118 통합)
      }

      if (showPasswordFields && newPw.isNotEmpty) {
        await _authApi.changePassword(
          currentPassword: currentPw,
          newPassword: newPw,
        );
        _showSnack('비밀번호가 변경되었습니다. 다시 로그인해주세요.');
        await _authApi.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      _showSnack('내 정보가 업데이트되었습니다.');
      setState(() {
        isEditing = false;
        showPasswordFields = false;
      });
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      _showSnack('업데이트 실패: ${message ?? '오류가 발생했습니다.'}');
    } catch (e) {
      _showSnack('업데이트 실패: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _logout() async {
    await _authApi.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  int daysBetween(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return da.difference(db).inDays;
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    _scheduleVisibilityRefresh();
=======
>>>>>>> 7cf0a32 (1118 통합)
    // 🎨 색상 팔레트
    const Color softWhite = Color(0xE6FFFFFF);
    const Color deepNavy = Color(0xFF004C73);
    const Color skyBlue = Color(0xFF89D4F5);

    final double maxCardWidth = MediaQuery.of(context).size.width - 48;

    final String joinDateText = createdAt != null
      ? '가입일: ${DateFormat('yyyy년 MM월 dd일').format(createdAt!)}'
      : '가입일 정보 없음';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '내 정보',
          style: TextStyle(
            color: deepNavy,
            fontWeight: FontWeight.w700,
            fontFamily: 'Noto Sans KR',
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: deepNavy),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Container(
                width: maxCardWidth,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: softWhite,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40FFFFFF),
                      blurRadius: 30,
                      offset: Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: skyBlue),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTextField(
                              controller: nameController,
                              label: '이름',
                              icon: Icons.person_outline,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: emailController,
                              label: '이메일',
                              icon: Icons.email_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
<<<<<<< HEAD
                              controller: coreValueController,
=======
                              controller: valueGoalController,
>>>>>>> 7cf0a32 (1118 통합)
                              label: '나의 핵심 가치',
                              icon: Icons.favorite_outline,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    joinDateText,
                                    style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'Noto Sans KR'),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildScreenTimeShortcutCard(context),
                            const SizedBox(height: 24),

                            if (showPasswordFields) ...[
                              _buildTextField(
                                controller: currentPasswordController,
                                label: '기존 비밀번호',
                                icon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: newPasswordController,
                                label: '새 비밀번호',
                                icon: Icons.lock_reset_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: confirmPasswordController,
                                label: '새 비밀번호 확인',
                                icon: Icons.verified_user_outlined,
                              ),
                              const SizedBox(height: 24),
                            ],

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : isEditing
                                        ? _updateUserData
                                        : () =>
                                            setState(() => isEditing = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: skyBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  isEditing ? '저장하기' : '수정하기',
                                  style: const TextStyle(
                                    fontFamily: 'Noto Sans KR',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(
                                  () =>
                                      showPasswordFields = !showPasswordFields,
                                );
                              },
                              child: Text(
                                showPasswordFields ? '비밀번호 변경 닫기' : '비밀번호 변경',
                                style: const TextStyle(
                                  color: deepNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _logout,
                              child: const Text(
                                '로그아웃',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeShortcutCard(BuildContext context) {
    final provider = context.watch<ScreenTimeProvider>();
    final summary = provider.summary;

    Widget buildStat(String label, String value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF004C73),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0F2FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '스크린타임 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/screen_time'),
                child: const Text('기록 보러가기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isLoading && summary == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else ...[
            Row(
              children: [
                buildStat('총 사용 시간', summary?.totalLabel ?? '--'),
                const SizedBox(width: 12),
                buildStat('오늘', summary != null ? '${summary.todayMinutes}분' : '--'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                buildStat('최근 7일', summary != null ? '${summary.weekMinutes}분' : '--'),
                const SizedBox(width: 12),
                buildStat('기록 횟수', summary != null ? '${summary.sessions}회' : '--'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: label.contains('비밀번호'),
      style: const TextStyle(
        fontFamily: 'Noto Sans KR',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF004C73)),
        filled: true,
        fillColor: enabled ? const Color(0xFFF5FBFF) : const Color(0xFFEFF7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9EEFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9EEFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF89D4F5), width: 1.6),
        ),
      ),
    );
  }
}
