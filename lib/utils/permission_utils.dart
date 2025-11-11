import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> checkAndRequestCamera() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  static Future<bool> checkAndRequestGallery() async {
    final status = await Permission.photos.status;
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  static Future<XFile?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
  }
}