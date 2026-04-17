import 'package:carbon/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appNameProvider = Provider<String>((ref) => AppConfig.appName);
