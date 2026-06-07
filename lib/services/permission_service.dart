import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) uses photos/videos specifically
      status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      
      // Fallback for older Android versions
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermanentlyDeniedDialog(context, "Gallery");
      }
      return false;
    }

    return false;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermanentlyDeniedDialog(context, "Camera");
      }
    }
    return false;
  }

  static void _showPermanentlyDeniedDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$feature Permission Required"),
        content: Text(
          "You have permanently denied $feature access. "
          "Please enable it in your phone settings to use this feature."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("OPEN SETTINGS"),
          ),
        ],
      ),
    );
  }
}
