import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/common/constants.dart';

/// 🌊 Mindrium 스타일 공용 팝업 디자인
class MindriumPopupDesign extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xE0E9F3FF), // 하늘색 투명 오버레이
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌍 지도 (혹은 다른 위젯으로 대체 가능)
          if (mapController != null)
            FlutterMap(
              mapController: mapController!,
              options: MapOptions(
                initialCenter:
                    picked ?? current ?? const LatLng(37.5665, 126.9780),
                initialZoom: 16,
                onTap: onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.vworld.kr/req/wmts/1.0.0/{key}/Base/{z}/{y}/{x}.png',
                  additionalOptions: {'key': vworldApiKey},
                ),
                if (current != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: current!,
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
                if (picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: picked!,
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
                if (savedMarkers != null && savedMarkers!.isNotEmpty)
                  MarkerLayer(markers: savedMarkers!),
              ],
            ),

          /// 🩵 상단 검색창
          if (searchController != null)
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
                  controller: searchController,
                  onSubmitted: (_) => onSearch?.call(),
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

          /// 중앙 팝업 카드
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 26.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: Color(0xFF5B3EFF),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans KR',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF263C69),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '지도를 탭하여 위치를 선택한 후 [확인]을 눌러주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Noto Sans KR',
                      fontSize: 14,
                      color: Color(0xFF5C6B84),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 하단 버튼
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: NavigationButtons(
              leftLabel: '닫기',
              rightLabel: '확인',
              onBack: onBack ?? () => Navigator.pop(context),
              onNext: onNext ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}
