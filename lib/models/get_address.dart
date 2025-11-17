// lib/utils/get_address.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// 현재 위치(Position)와 한글 주소를 함께 담는 결과 타입
class AddressResult {
  final Position? pos;
  final String? addressKo;
  const AddressResult({this.pos, this.addressKo});
}

/// 위치 권한이 허용된 경우 기기 위치를 얻고, 한글 주소(ko_KR)로 역지오코딩하여 반환합니다.
/// 실패/거절 시 pos/addressKo는 null일 수 있습니다.
Future<AddressResult> getAddressKo() async {
  Position? pos;
  String? addressKo;

  try {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      debugPrint('Location_Permission: $perm');
    }
    if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
      pos = await Geolocator.getCurrentPosition();
      debugPrint('Location_Permission: $perm');
      debugPrint('current_location: $pos');

      // === 역지오코딩 (한글 주소) ===
      try {
        await setLocaleIdentifier('ko_KR');
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(), // 시/도
            if ((p.locality ?? '').trim().isNotEmpty)          p.locality!.trim(),            // 시/군/구
            if ((p.subLocality ?? '').trim().isNotEmpty)       p.subLocality!.trim(),         // 동/읍/면
            if ((p.thoroughfare ?? '').trim().isNotEmpty)      p.thoroughfare!.trim(),        // 도로명
            if ((p.subThoroughfare ?? '').trim().isNotEmpty)   p.subThoroughfare!.trim(),     // 건물번호
          ];
          if (parts.isNotEmpty) {
            addressKo = parts.join(' ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }
    }
  } catch (e) {
    // 위치 실패시 주소 없이 진행
    debugPrint('Location fetch failed: $e');
  }
  
  return AddressResult(pos: pos, addressKo: addressKo);
}