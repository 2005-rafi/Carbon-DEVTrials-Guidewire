import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = Provider<Map<String, String>>((ref) {
  return <String, String>{
    'name': 'Avery Johnson',
    'email': 'avery.johnson@example.com',
    'plan': 'Income Shield Plus',
  };
});
