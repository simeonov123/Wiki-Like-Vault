import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureMediaAndCameraPermissions() async {
  final statuses = await [
    Permission.photos,   // maps to READ_MEDIA_IMAGES / storage
    Permission.camera,
  ].request();

  return statuses.values.every((s) => s.isGranted);
}
