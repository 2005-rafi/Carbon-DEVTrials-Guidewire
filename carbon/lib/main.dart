import 'package:carbon/app.dart';
import 'package:carbon/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize notification plugin early, but defer permission prompt
  // to OTP send flow for better UX and reliable Android runtime dialog.
  await NotificationService().initialize();
  runApp(const ProviderScope(child: AppRoot()));
}
