import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:gad_app_team/features/4th_treatment/week4_alternative_thoughts.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';

/// 💡 Firestore의 'belief' 필드(B 리스트)를 불러와 선택 후 다음 단계로 이동하는 화면
class ApplyAlternativeThoughtScreen extends StatefulWidget {
  const ApplyAlternativeThoughtScreen({super.key});

  @override
  State<ApplyAlternativeThoughtScreen> createState() =>
      _ApplyAlternativeThoughtScreenState();
}

class _ApplyAlternativeThoughtScreenState
    extends State<ApplyAlternativeThoughtScreen> {
  bool _loading = false;
  String? _error;
  List<String> _bList = const [];
  String? _abcId;
  int _beforeSud = 0;
  int? _selectedIndex;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    _abcId = args['abcId'] as String?;
    _beforeSud = (args['beforeSud'] as int?) ?? 0;
    if (_bList.isEmpty && !_loading) _fetchBeliefs();
  }

  /// 🔹 FastAPI(다이어리)에서 'belief' 리스트 로드
  Future<void> _fetchBeliefs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final access = await _tokens.access;
      if (access == null) throw Exception('로그인이 필요합니다.');

      List<String> list = const [];

      if (_abcId != null && _abcId!.isNotEmpty) {
        final diary = await _diariesApi.getDiary(_abcId!);
        if (diary.isEmpty) throw Exception('해당 ABC를 찾을 수 없습니다.');
        list = _parseBeliefList(diary['belief']);

        if (list.isEmpty) {
          final groupRaw = diary['group_Id'] ?? diary['groupId'];
          final groupId =
              groupRaw is int
                  ? groupRaw
                  : groupRaw is num
                  ? groupRaw.toInt()
                  : int.tryParse(groupRaw?.toString() ?? '');
          if (groupId != null) {
            list = await _loadGroupBeliefs(groupId);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _bList = list;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      setState(() {
        _error = detail ?? '데이터를 불러오지 못했습니다.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<String>> _loadGroupBeliefs(int groupId) async {
    final diaries = await _diariesApi.listDiaries(groupId: groupId);
    return _extractBeliefsFromDiaries(diaries);
  }

  List<String> _extractBeliefsFromDiaries(List<Map<String, dynamic>> diaries) {
    final seen = <String>{};
    final acc = <String>[];
    for (final diary in diaries) {
      final items = _parseBeliefList(diary['belief']);
      for (final item in items) {
        if (seen.add(item)) acc.add(item);
      }
    }
    return acc;
  }

  List<String> _parseBeliefList(dynamic belief) {
    if (belief == null) return const [];
    if (belief is List) {
      return belief
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (belief is String) {
      final parts =
          belief
              .split(RegExp(r'[,\n;]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return parts.isEmpty ? [belief] : parts;
    }
    return [belief.toString()];
  }

  void _onSelect(String b) {
    final all = _bList;
    final remaining = List<String>.from(all)..remove(b);
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final diary = args['diary'];
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(arguments: {'origin': 'apply', 'diary': diary}),
        builder:
            (_) => Week4AlternativeThoughtsScreen(
              previousChips: [b],
              beforeSud: _beforeSud,
              remainingBList: remaining,
              allBList: all,
              originalBList: all,
              abcId: _abcId,
              origin: 'apply',
              diary: diary,
            ),
      ),
    );
  }

  void _skipSelection() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<UserProvider>().userName;
    final hasBeliefs = _bList.isNotEmpty;

    return InnerBtnCardScreen(
      appBarTitle: '도움이 되는 생각 찾기',
      title: '$userName님,\n어떤 생각을 대상으로 찾아볼까요?',
      primaryText:
          hasBeliefs ? '도움이 되는 생각을 찾아볼게요!' : '다음에 진행하기',
      onPrimary: () {
        if (!hasBeliefs) {
          _skipSelection();
          return;
        }
        if (_selectedIndex == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('생각을 선택해주세요.')));
          return;
        }
        final b = _bList[_selectedIndex!];
        _onSelect(b);
      },
      // ✅ 리스트 렌더링 복구 (Flexible + shrinkWrap)
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : _bList.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '일기/그룹에서 불러올 생각이 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
              )
              : Flexible(
                // 👇 ListView가 안 보이던 문제 해결
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _bList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = _bList[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? const Color(0xFF47A6FF).withValues(alpha: 0.15)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected
                                    ? const Color(0xFF47A6FF)
                                    : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 15.5,
                            color:
                                selected
                                    ? const Color(0xFF0B5394)
                                    : Colors.black87,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: 'Noto Sans KR',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
