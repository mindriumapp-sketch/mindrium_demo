import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rive/rive.dart' as rive;
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

import 'relaxation_logger.dart';  // 분리한 로거
import 'relaxation_education.dart' show relaxationTitleForWeek;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// 알림 재생 화면 상단 타이틀
/// - weekNumber가 있으면: 그 주차 이완 타이틀 그대로 사용 (숙제 알림)
/// - weekNumber가 없으면: 일기 기반 이완 알림
String notiTitle(String taskId, int? weekNumber) {
  // 숙제 알림: 주차 정보가 들어온 경우
  if (weekNumber != null) {
    return relaxationTitleForWeek(weekNumber);
  }
  // 일기 기반 알림: 주차 정보 없음
  return '알림 이후 이완';
}


// 초기 싱크 보정
const Duration _kInitialAudioDelay = Duration(milliseconds: 0);
// 중간 자동 저장 주기
const Duration _kAutosaveInterval = Duration(seconds: 30);


class NotiPlayer extends StatefulWidget {
  final String taskId;
  final int? weekNumber;
  final String? mp3Asset;    // 예: 'week1.mp3'
  final String? riveAsset;   // 예: 'week1.riv'
  final String nextPage;    // ✅ 다음 라우트 이름(그대로 사용)

  const NotiPlayer({
    super.key,
    required this.taskId,
    this.weekNumber,
    this.mp3Asset = 'noti.mp3',
    this.riveAsset = 'noti.riv',
    required this.nextPage,
  });

  @override
  State<NotiPlayer> createState() => _NotiPlayerState();
}

class _NotiPlayerState extends State<NotiPlayer> with WidgetsBindingObserver {
  // Rive 0.14
  late final rive.FileLoader _fileLoader =
  rive.FileLoader.fromAsset('assets/relaxation/${widget.riveAsset}', riveFactory: rive.Factory.rive);

  rive.RiveWidgetController? _riveController;
  rive.StateMachine? _stateMachine;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  bool _isPlaying = false;
  bool _isAudioFinished = false;
  bool _isRiveFinished = false;

  // Logger
  late final RelaxationLogger _logger;

  // 저장 제어
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

    _startAutosaveTimer(); // 주기 저장
  }

  // === 중간 자동 저장 ===
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

  // 라이프사이클 저장
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;
    final String? diary   = args['diary'] as String?;
    final String? origin  = args['origin'] as String?;

    if (_isAudioFinished && _isRiveFinished) {
      _logger.logEvent("session_complete");
      await _saveOnce(reason: 'complete');
      if (!mounted) return;
      // ✅ nextPage로 교체 이동
      Navigator.of(context).pushReplacementNamed(
        widget.nextPage,
        arguments: {
          'abcId': abcId,
          'diary': diary,
          'origin': origin,
        },
      );
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        _saveOnce(reason: 'back');
      },
      child: GestureDetector(
        onTap: _togglePlay,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: CustomAppBar(
            title: notiTitle(widget.taskId, widget.weekNumber),
            showHome: false,
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
                      _isRiveFinished = true; // Rive는 완료 취급
                      _startAudioOnce();
                      return const SizedBox.shrink();
                    }
                    if (state is rive.RiveLoaded) {
                      if (_riveController == null) {
                        _riveController = rive.RiveWidgetController(
                          state.file,
                          stateMachineSelector: rive.StateMachineSelector.byName('State Machine 1'),
                          // artboardSelector: rive.ArtboardSelector.byName('Main'), // 필요 시
                        );

                        _stateMachine = _riveController!.stateMachine;
                        if (_stateMachine == null) {
                          // ✅ 디버깅용 로그만 남기고 '완료'로 몰지 않기
                          _logger.logEvent("rive_state_machine_missing");
                        } else {
                          // 이벤트 리스너 등록
                          _stateMachine!.addEventListener((event) {
                            if (event.name == 'done') {
                              if (_isRiveFinished) return;
                              _isRiveFinished = true;
                              _logger.logEvent("rive_complete");
                              _checkIfBothFinished();
                            }
                          });
                          // 시작
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
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 64),
                  ),
                ),
            ],
          ),
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
