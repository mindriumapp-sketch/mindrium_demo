import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:rive/rive.dart' as rive;
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'relaxation_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gad_app_team/utils/edu_progress.dart';

// --- 주차 타이틀 ---
const Map<int, String> kRelaxationWeekTitles = {
  1: '1주차 - 점진적 이완',
  2: '2주차 - 점진적 이완',
  3: '3주차 - 이완만 하는 이완',
  4: '4주차 - 신호 조절 이완',
  5: '5주차 - 차등 이완',
  6: '6주차 - 차등 이완',
  7: '7주차 - 신속 이완',
  8: '8주차 - 신속 이완',
};

String relaxationTitleForWeek(int? week) {
  final w = week ?? 1;
  return kRelaxationWeekTitles[w] ?? '$w주차 이완 훈련';
}

// 초기 싱크 보정
const Duration _kInitialAudioDelay = Duration(milliseconds: 0);
// 중간 자동 저장 주기
const Duration _kAutosaveInterval = Duration(seconds: 30);

// ✅ 전역 네비게이터 키 (검은화면 방지용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PracticePlayer extends StatefulWidget {
  final String taskId;
  final int weekNumber;
  final String mp3Asset;
  final String riveAsset;

  const PracticePlayer({
    super.key,
    required this.taskId,
    required this.weekNumber,
    required this.mp3Asset,
    required this.riveAsset,
  });

  @override
  State<PracticePlayer> createState() => _PracticePlayerState();
}

class _PracticePlayerState extends State<PracticePlayer>
    with WidgetsBindingObserver {
  late final rive.FileLoader _fileLoader = rive.FileLoader.fromAsset(
    'assets/relaxation/${widget.riveAsset}',
    riveFactory: rive.Factory.rive,
  );

  rive.RiveWidgetController? _riveController;
  rive.StateMachine? _stateMachine;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isAudioFinished = false;
  bool _isRiveFinished = false;

  late final RelaxationLogger _logger;

  bool _finalSaved = false;
  Timer? _autosaveTimer;
  bool _audioStartedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _logger = RelaxationLogger(
      taskId: widget.taskId,
      weekNumber: widget.weekNumber,
    );
    _logger.logEvent("start");

    // 🔥 세션 시작 시점에 위치 한 번만 캡처해서 logger에 넣음
    _captureStartLocation();

    _startAutosaveTimer();
  }

  void _startAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(_kAutosaveInterval, (_) async {
      _logger.logEvent("autosave_tick");
      try {
        await _logger.saveLogs();
      } catch (e) {
        debugPrint('autosave error: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveOnce(reason: 'app_paused');
    } else if (state == AppLifecycleState.resumed) {
      _startAutosaveTimer();
    }
  }

  Future<void> _startAudioOnce() async {
    if (_audioStartedOnce) return;
    _audioStartedOnce = true;
    await _audioPlayer.setSource(AssetSource('relaxation/${widget.mp3Asset}'));
    await _audioPlayer.setVolume(0.8);
    await Future.delayed(_kInitialAudioDelay);
    await _audioPlayer.resume();
    setState(() => _isPlaying = true);

    _audioPlayer.onPlayerComplete.listen((_) {
      _isAudioFinished = true;
      _logger.logEvent("audio_complete");
      _checkIfBothFinished();
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
      _riveController?.active = false;
      _logger.logEvent("pause");
    } else {
      _audioPlayer.resume();
      _riveController?.active = true;
      _logger.logEvent("resume");
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _saveOnce({required String reason}) async {
    if (_finalSaved) return;
    _finalSaved = true;
    try {
      _logger.logEvent("final_save_$reason");
      await _logger.saveLogs();
    } catch (e) {
      debugPrint('saveLogs error ($reason): $e');
    }
  }

  void _checkIfBothFinished() async {
    if (_isAudioFinished && _isRiveFinished) {
      // ✅ 완주 플래그 먼저 세움
      _logger.setFullyCompleted();
      _logger.logEvent("session_complete");

      await _saveOnce(reason: 'complete');
      if (!mounted) return;

      //await EduProgress.markWeekDone(1);
      // ✅ 교육 화면으로 이동 (진행도 갱신 및 다음 주차 unlock 반영)
      Navigator.pushNamedAndRemoveUntil(context, '/treatment', (_) => false);
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _audioPlayer.dispose();
    _saveOnce(reason: 'dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          title: relaxationTitleForWeek(widget.weekNumber),
          showHome: true,
          confirmOnBack: false,
          onBack: () async {
            _saveOnce(reason: 'back');
            final shouldExit = await showDialog<bool>(
              context: context,
              builder:
                  (context) => CustomPopupDesign(
                    title: '종료하시겠습니까?',
                    message: '이완 연습을 종료하고 이전 화면으로 돌아갑니다.',
                    positiveText: '나가기',
                    onPositivePressed: () => Navigator.pop(context, true),
                    negativeText: '취소',
                    onNegativePressed: () => Navigator.pop(context, false),
                  ),
            );

            if (shouldExit == true) {
              // ✅ 검은화면 방지 오버레이 생성
              final overlayContext =
                  navigatorKey.currentState?.overlay?.context;
              if (overlayContext != null) {
                showGeneralDialog(
                  context: overlayContext,
                  barrierColor: Colors.transparent,
                  barrierDismissible: false,
                  transitionDuration: Duration.zero,
                  pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                );
              }

              // ✅ 실제 뒤로가기
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/treatment');
              }

              // ✅ 오버레이 제거
              await Future.delayed(const Duration(milliseconds: 100));
              if (Navigator.canPop(context)) Navigator.pop(context);
            }
          },
        ),
        body: Stack(
          children: [
            Center(
              child: rive.RiveWidgetBuilder(
                fileLoader: _fileLoader,
                builder: (context, state) {
                  if (state is rive.RiveLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is rive.RiveFailed) {
                    debugPrint('Rive load failed: ${state.error}');
                    _isRiveFinished = true;
                    _startAudioOnce();
                    return const SizedBox.shrink();
                  }
                  if (state is rive.RiveLoaded) {
                    if (_riveController == null) {
                      _riveController = rive.RiveWidgetController(
                        state.file,
                        stateMachineSelector: rive.StateMachineSelector.byName(
                          'State Machine 1',
                        ),
                      );

                      _stateMachine = _riveController!.stateMachine;

                      if (_stateMachine == null) {
                        _logger.logEvent("rive_state_machine_missing");
                      } else {
                        _stateMachine!.addEventListener((event) {
                          if (event.name == 'done') {
                            if (_isRiveFinished) return;
                            _isRiveFinished = true;
                            _logger.logEvent("rive_complete");
                            _checkIfBothFinished();
                          }
                        });
                        _riveController!.active = true;
                      }

                      _startAudioOnce();
                    }

                    return rive.RiveWidget(
                      controller: _riveController!,
                      fit: rive.Fit.contain,
                      alignment: Alignment.center,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            if (!_isPlaying)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureStartLocation() async {
    try {
      // 1) 권한 확인 + 필요 시 요청
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        // 권한 없으면 위치 없이 진행
        return;
      }

      // 2) 현재 위치 가져오기
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // 3) 주소 문자열 만들기 (가능하면)
      String? addressName;
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          addressName = [
            p.administrativeArea,
            p.locality,
            p.subLocality,
            p.thoroughfare,
          ].where((e) => e != null && e.isNotEmpty).join(' ');
        }
      } catch (e) {
        debugPrint('reverse geocoding 실패: $e');
      }

      // 4) Logger에 딱 한 번 세팅
      _logger.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        addressName: addressName,
      );
    } catch (e) {
      debugPrint('위치 캡처 실패: $e');
    }
  }
}
