import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

/// Checks a feature flag and shows a SnackBar if it's disabled.
/// Returns true if the feature is allowed, false if blocked.
///
/// Usage:
/// ```dart
/// if (!await checkFeatureFlag(context, 'allowSkinScans',
///     blockedMessage: 'Skin scans are currently disabled.')) return;
/// ```
Future<bool> checkFeatureFlag(
  BuildContext context,
  String flagKey, {
  String blockedMessage = 'This feature is currently disabled.',
}) async {
  try {
    final settings = await ApiService.getPublicSettings();
    if (settings[flagKey] == false) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(blockedMessage, style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF5B2333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return false;
    }
    return true;
  } catch (_) {
    // If settings can't be fetched, allow by default
    return true;
  }
}
