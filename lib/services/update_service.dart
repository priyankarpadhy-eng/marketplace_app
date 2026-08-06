import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  Future<void> checkForUpdates() async {
    // In-App Updates are only supported on Android.
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      // If an update is available
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        
        // Try an immediate update (forces the user to update)
        // You can change this to startFlexibleUpdate() if you want them to be able to use the app while it downloads
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint("In-App Update failed: $e");
    }
  }
}
