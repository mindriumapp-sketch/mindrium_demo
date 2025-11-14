// File: sea_archive_page.dart
// 🌊 Mindrium SeaArchivePage — Immersive Aquarium with following speech bubble
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

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
  late Future<List<Map<String, dynamic>>> _groupsFuture;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);

  int? _currentMessageIndex;
  String? _currentMessage;

  final List<String> comfortMessages = const [
    '오늘도 잘 버텨냈어요 🌿',
    '지금 이 순간 그대로도 괜찮아요 💙',
    '당신의 속도도 충분히 아름다워요 🐚',
    '바람이 잔잔해질 거예요 ☁️',
    '당신의 마음을 물고기들이 지켜보고 있어요 🌊',
    '깊은 바다 속에서도 빛은 도달해요 ✨',
    '오늘은 조금 쉬어가도 괜찮아요 🐢',
    '당신의 불안도 결국 물결이 되어 흘러가요 💧',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _groupsFuture = _fetchArchivedGroups();
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
      setState(() {
        _currentMessageIndex = idx;
        _currentMessage =
            comfortMessages[random.nextInt(comfortMessages.length)];
      });

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _currentMessage = null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchArchivedGroups() async {
    final access = await _tokens.access;
    if (access == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final groups = await _userDataApi.getArchivedGroups();
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? [];
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          return Stack(
            children: [
              // 🌊 배경
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final shift = sin(_controller.value * 2 * pi) * 8;
                    return Transform.translate(
                      offset: Offset(shift, 0),
                      child: Image.asset(
                        'assets/image/sea_bg_3d.png',
                        fit: BoxFit.cover,
                        width: size.width * 1.1,
                        height: size.height * 1.1,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(child: _LightRays(controller: _controller)),
              Positioned.fill(child: _PlanktonLayer(controller: _controller)),

              if (snapshot.hasError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '아카이브를 불러오지 못했어요.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else if (groups.isEmpty && !waiting)
                Builder(
                  builder: (_) {
                    _fieldController = null;
                    _lastCount = 0;
                    return const Center(
                      child: Text(
                        '아카이브된 물고기가 없어요.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                )
              else if (groups.isNotEmpty)
                _buildFishField(groups, size),

              // 🌊 하단 유리 내비게이션 바
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _GlassNavigationBar(),
              ),

              if (waiting)
                const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFishField(List<Map<String, dynamic>> groups, Size size) {
    _fieldController ??= FishFieldController(count: groups.length);
    if (_lastCount != groups.length) {
      _fieldController = FishFieldController(count: groups.length);
      _lastCount = groups.length;
    }

    return Stack(
      children: [
        for (int i = 0; i < groups.length; i++)
          _SmoothFish(
            index: i,
            data: groups[i],
            area: size,
            field: _fieldController!,
            onTap: (img, title, desc, createdAt) {
              showDialog(
                context: context,
                builder:
                    (_) => _FishInfoPopup(title: title, desc: desc, image: img),
              );
            },
          ),
        // 💬 안내 문구
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

        // 🐚 위로 말풍선 (물고기를 따라다님) + 화면 밖 넘침 방지
        if (_currentMessage != null &&
            _currentMessageIndex != null &&
            _fieldController != null &&
            _fieldController!.getBounds(_currentMessageIndex!) != null)
          Builder(
            builder: (_) {
              final rect = _fieldController!.getBounds(_currentMessageIndex!)!;
              const bubbleW = 220.0;
              const bubbleH = 56.0;
              double left = rect.right + 8;
              double top = rect.top - 8;

              if (left + bubbleW > size.width) {
                left = max(8, rect.left - bubbleW - 8);
              }
              if (top + bubbleH > size.height - 80) {
                top = size.height - 80 - bubbleH;
              }
              if (top < 20) top = 20;

              final facingLeft = left < rect.left;

              return Positioned(
                left: left,
                top: top,
                width: bubbleW,
                child: _SpeechBubble(
                  message: _currentMessage!,
                  facingLeft: facingLeft,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// 🫧 말풍선 위젯
class _SpeechBubble extends StatelessWidget {
  final String message;
  final bool facingLeft;
  const _SpeechBubble({required this.message, this.facingLeft = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(facingLeft: facingLeft),
      child: Container(
        margin: EdgeInsets.only(
          left: facingLeft ? 0 : 8,
          right: facingLeft ? 8 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF004A6E),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final bool facingLeft;
  _BubbleTailPainter({required this.facingLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.92)
          ..style = PaintingStyle.fill;
    final path = Path();
    if (facingLeft) {
      path.moveTo(size.width, size.height / 2 - 4);
      path.lineTo(size.width + 8, size.height / 2);
      path.lineTo(size.width, size.height / 2 + 4);
    } else {
      path.moveTo(0, size.height / 2 - 4);
      path.lineTo(-8, size.height / 2);
      path.lineTo(0, size.height / 2 + 4);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

/// 🐠 부드럽게 유영하는 물고기
class _SmoothFish extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final Size area;
  final FishFieldController field;
  final void Function(ImageProvider, String, String, DateTime?) onTap;

  const _SmoothFish({
    required this.index,
    required this.data,
    required this.area,
    required this.field,
    required this.onTap,
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

  @override
  void initState() {
    super.initState();
    _r = Random(widget.index * 131);
    _pos = Offset(
      _r.nextDouble() * (widget.area.width - fishSize),
      _r.nextDouble() * (widget.area.height * 0.7 - fishSize),
    );
    _vel = Offset.fromDirection(_r.nextDouble() * 2 * pi, speed);
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onTick)
          ..repeat();
  }

  void _onTick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt =
        (_lastTick == null)
            ? 1 / 60
            : ((now - _lastTick!).inMicroseconds / 1e6).clamp(0.0, 1 / 30.0);
    _lastTick = now;

    // 위치/경계 계산 (setState는 마지막에 1회)
    var next = _pos + _vel * dt;

    if (next.dx < 0 || next.dx > widget.area.width - fishSize) {
      _vel = Offset(-_vel.dx, _vel.dy);
      next = Offset(next.dx.clamp(0, widget.area.width - fishSize), next.dy);
    }
    if (next.dy < 0 || next.dy > widget.area.height - fishSize) {
      _vel = Offset(_vel.dx, -_vel.dy);
      next = Offset(next.dx, next.dy.clamp(0, widget.area.height - fishSize));
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
    final data = widget.data;
    final characterRaw =
        (data['character_id'] ?? data['group_id'] ?? '1').toString();
    final characterDigits = RegExp(r'\d+').stringMatch(characterRaw) ?? '1';
    final characterId = int.tryParse(characterDigits) ?? 1;
    final img = AssetImage('assets/image/character$characterId.png');
    final title =
        (data['group_title'] ?? data['group_name'] ?? '이름 없는 캐릭터').toString();
    final desc =
        (data['group_contents'] ?? data['description'] ?? '').toString();
    DateTime? createdAt;
    final rawCreated = data['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated);
    }

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
            color: Colors.white.withOpacity(0.15),
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
                  color: Colors.white70,
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

/// 💡 Light rays
class _LightRays extends StatelessWidget {
  final AnimationController controller;
  const _LightRays({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (_, __) => CustomPaint(painter: _LightRaysPainter(controller.value)),
    );
  }
}

class _LightRaysPainter extends CustomPainter {
  final double t;
  _LightRaysPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.white.withOpacity(0.14), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.25 + i * 0.3) + sin(t * 2 * pi + i) * 20;
      final path =
          Path()
            ..moveTo(x - 40, 0)
            ..lineTo(x + 40, 0)
            ..lineTo(x + 100, size.height)
            ..lineTo(x - 100, size.height)
            ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LightRaysPainter oldDelegate) => oldDelegate.t != t;
}

/// ✨ Plankton + Bubbles
class _PlanktonLayer extends StatelessWidget {
  final AnimationController controller;
  const _PlanktonLayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final rnd = Random(42);
        return CustomPaint(painter: _PlanktonPainter(controller.value, rnd));
      },
    );
  }
}

class _PlanktonPainter extends CustomPainter {
  final double t;
  final Random rnd;
  _PlanktonPainter(this.t, this.rnd);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 80; i++) {
      final x = rnd.nextDouble() * size.width;
      final y =
          (rnd.nextDouble() * size.height + sin(t * 2 * pi) * 10) % size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 2 + 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanktonPainter old) => old.t != t;
}

/// ⚪ 하단 네비게이션
class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar();

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
