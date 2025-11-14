import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/blue_banner.dart'; // <- 너가 말한 파일

class MindriumPopupDesign extends StatefulWidget {
  final String title;
  final TextEditingController? searchController;
  final MapController? mapController;
  final LatLng? picked;
  final LatLng? current;
  final List<Marker>? savedMarkers;
  final VoidCallback? onSearch;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final Function(TapPosition, LatLng)? onTap;

  const MindriumPopupDesign({
    super.key,
    required this.title,
    this.searchController,
    this.mapController,
    this.picked,
    this.current,
    this.savedMarkers,
    this.onSearch,
    this.onBack,
    this.onNext,
    this.onTap,
  });

  @override
  State<MindriumPopupDesign> createState() => _MindriumPopupDesignState();
}

class _MindriumPopupDesignState extends State<MindriumPopupDesign> {
  @override
  void initState() {
    super.initState();
    // 화면이 그려진 다음에 배너 띄우기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      // 가운데쯤에 뜨게 패딩 조절
      CustomBanner.show(
        context,
        message: '지도를 탭해서 위치를 선택한 후\n[확인]을 눌러주세요.',
        duration: const Duration(seconds: 3),
        // 화면 높이의 절반쯤 위에 배치
        padding: EdgeInsets.fromLTRB(16, 0, 16, size.height * 0.2),
        showJellyfish: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xE0E9F3FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌍 지도
          if (widget.mapController != null)
            FlutterMap(
              mapController: widget.mapController!,
              options: MapOptions(
                initialCenter:
                widget.picked ?? widget.current ?? const LatLng(37.5665, 126.9780),
                initialZoom: 16,
                onTap: widget.onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://api.vworld.kr/req/wmts/1.0.0/{key}/Base/{z}/{y}/{x}.png',
                  additionalOptions: {'key': vworldApiKey},
                ),
                if (widget.current != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.current!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF4A90E2),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                if (widget.picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.picked!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFF5B3EFF),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                if (widget.savedMarkers != null && widget.savedMarkers!.isNotEmpty)
                  MarkerLayer(markers: widget.savedMarkers!),
              ],
            ),

          // 🩵 상단 검색창
          if (widget.searchController != null)
            Positioned(
              top: 56,
              left: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.searchController,
                  onSubmitted: (_) => widget.onSearch?.call(),
                  decoration: const InputDecoration(
                    hintText: '주소 검색',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF4A90E2)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

          // ✅ 하단 버튼은 그대로
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: NavigationButtons(
              leftLabel: '닫기',
              rightLabel: '확인',
              onBack: widget.onBack ?? () => Navigator.pop(context),
              onNext: widget.onNext ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}
