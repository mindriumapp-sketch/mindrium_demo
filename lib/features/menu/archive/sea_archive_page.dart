// File: sea_archive_page.dart
// 🌊 Mindrium SeaArchivePage — Immersive Aquarium with following speech bubble
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeaArchivePage extends StatefulWidget {
  const SeaArchivePage({super.key});

  @override
  State<SeaArchivePage> createState() => _SeaArchivePageState();
}

class _SeaArchivePageState extends State<SeaArchivePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  FishFieldController? _fieldController;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _startComfortMessageLoop();
  }

  void _startComfortMessageLoop() async {
    final random = Random();
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));

      if (_fieldController == null) continue;

      final fishCount = _fieldController!.count;

      if (fishCount == 0) continue;

      final idx = random.nextInt(fishCount);

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _archiveGroupsQuery(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_group')
        .where('archived', isEqualTo: true);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    //하단 네비 게이 높이를 직접 지정 (고정값)
    const double navBarHeight = 64.0; // 아이콘 + padding 고려

    const double guideTextTop = 60.0;
    const double guideTextHeight = 80.0;
    final double avoidTop = guideTextTop + guideTextHeight;
    final double avoidBottom = navBarHeight + bottomSafe;
    final fishArea = Size(size.width, size.height - avoidBottom);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          //배경
          Positioned.fill(
            child: Image.asset(
              'assets/image/sea_archive_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          //물고기 필드
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _archiveGroupsQuery(uid).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              _fieldController ??= FishFieldController(count: docs.length);
              if (_lastCount != docs.length) {
                _fieldController = FishFieldController(count: docs.length);
                _lastCount = docs.length;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: avoidBottom),
                child: Stack(
                  children: [
                    for (int i = 0; i < docs.length; i++)
                      _SmoothFish(
                        index: i,
                        doc: docs[i],
                        area: fishArea,
                        avoidBottom: 64,
                        avoidTop: avoidTop,
                        field: _fieldController!,
                        onTap: (img, title, desc, createdAt) {
                          showDialog(
                            context: context,
                            builder:
                                (_) => _FishInfoPopup(
                                  title: title,
                                  desc: desc,
                                  image: img,
                                ),
                          );
                        },
                      ),

                    //안내 문구
                    Positioned(
                      top: 60,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            '물고기를 클릭하면 내 불안을 확인할 수 있어요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF004A6E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          //하단 네비게이션 바
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _GlassNavigationBar(),
          ),
        ],
      ),
    );
  }
}

//controller
class FishFieldController {
  final int count;
  final Map<int, Offset> _positions = {};
  final Map<int, Rect> _bounds = {};

  FishFieldController({required this.count});

  void updatePosition(int index, Offset pos) {
    _positions[index] = pos;
  }

  Offset? getPosition(int index) => _positions[index];

  void setBounds(int index, Rect rect) {
    _bounds[index] = rect;
  }

  Rect? getBounds(int index) => _bounds[index];
}

//fish animation
class _SmoothFish extends StatefulWidget {
  final int index;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Size area;
  final double avoidBottom;
  final double avoidTop;
  final FishFieldController field;
  final void Function(ImageProvider, String, String, Timestamp?) onTap;

  const _SmoothFish({
    required this.index,
    required this.doc,
    required this.area,
    required this.field,
    required this.onTap,
    this.avoidBottom = 0,
    this.avoidTop = 0,
  });

  @override
  State<_SmoothFish> createState() => _SmoothFishState();
}

class _SmoothFishState extends State<_SmoothFish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Random _r;
  late Offset _pos;
  late Offset _vel;
  bool _facingRight = true;
  Duration? _lastTick;
  static const double speed = 35.0;
  static const double fishSize = 64.0;

  double get _maxX => (widget.area.width - fishSize).clamp(0, double.infinity);

  // 상단 금지구역(안내문구) 아래부터만 유영
  double get _minY {
    final upper = max(0.0, widget.area.height - fishSize); // y의 이론상 최댓값
    return widget.avoidTop.clamp(0.0, upper).toDouble();
  }

  double get _maxY {
    final limit = widget.area.height - fishSize - widget.avoidBottom;
    return max(_minY, limit).clamp(0, double.infinity); // 항상 _minY ≤ _maxY 보장
  }

  @override
  void initState() {
    super.initState();
    _r = Random(widget.index * 131);
    _initPositionAndVelocity();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onTick)
          ..repeat();
  }

  void _initPositionAndVelocity() {
    // 스폰도 _minY ~ _maxY*0.7 구간에서만
    final usable = max(0.0, _maxY - _minY);
    final spawnRange = usable * 0.7;
    final spawnY =
        _minY + (_r.nextDouble() * (spawnRange <= 0 ? 0.0 : spawnRange));

    _pos = Offset(_r.nextDouble() * (_maxX <= 0 ? 0.0 : _maxX), spawnY);
    _vel = Offset.fromDirection(_r.nextDouble() * 2 * pi, speed);
  }

  @override
  void didUpdateWidget(covariant _SmoothFish oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 경계 변화 시 현재 위치를 안전 구간으로 클램프
    if (oldWidget.avoidBottom != widget.avoidBottom ||
        oldWidget.area != widget.area ||
        // avoidTop 변화도 감지
        (oldWidget.avoidTop != widget.avoidTop)) {
      _pos = Offset(_pos.dx.clamp(0, _maxX), _pos.dy.clamp(_minY, _maxY));
    }
  }

  void _onTick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt =
        (_lastTick == null)
            ? 1 / 60
            : ((now - _lastTick!).inMicroseconds / 1e6).clamp(0.0, 1 / 30.0);
    _lastTick = now;

    var next = _pos + _vel * dt;

    // 좌우 벽
    if (next.dx < 0 || next.dx > _maxX) {
      _vel = Offset(-_vel.dx, _vel.dy);
      next = Offset(next.dx.clamp(0, _maxX), next.dy);
    }
    // 상단/하단 경계: _minY ~ _maxY
    if (next.dy < _minY || next.dy > _maxY) {
      _vel = Offset(_vel.dx, -_vel.dy);
      next = Offset(next.dx, next.dy.clamp(_minY, _maxY));
    }

    _facingRight = _vel.dx >= 0;

    _pos = next;
    widget.field
      ..updatePosition(widget.index, _pos)
      ..setBounds(
        widget.index,
        Rect.fromLTWH(_pos.dx, _pos.dy, fishSize, fishSize),
      );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final img = AssetImage(
      'assets/image/character${data['group_id'] ?? 1}.png',
    );
    final title = (data['group_title'] ?? '이름 없는 캐릭터').toString();
    final desc = (data['group_contents'] ?? '').toString();
    final createdAt =
        data.containsKey('created_at')
            ? data['created_at'] as Timestamp?
            : null;

    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: RepaintBoundary(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => widget.onTap(img, title, desc, createdAt),
          child: Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()..scale(_facingRight ? 1.0 : -1.0, 1.0, 1.0),
            child: Image(image: img, width: fishSize, height: fishSize),
          ),
        ),
      ),
    );
  }
}

class _FishInfoPopup extends StatelessWidget {
  final String title;
  final String desc;
  final ImageProvider image;

  const _FishInfoPopup({
    required this.title,
    required this.desc,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(image: image, width: 80, height: 80),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc.isEmpty ? '설명이 없습니다.' : desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(179, 0, 0, 0),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//하단 네비게이션
class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar(); // ✅ onHeight 제거됨

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.school_rounded,
      Icons.water_rounded,
      Icons.settings_rounded,
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.white.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: i == 2 ? 1.25 : 1.0),
                duration: const Duration(milliseconds: 300),
                builder:
                    (_, scale, child) => Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              i == 2
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF89D4F5),
                                      Color(0xFFB2F2E8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          icons[i],
                          size: 28,
                          color: i == 2 ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
