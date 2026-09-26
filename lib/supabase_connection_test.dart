import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('===== SUPABASE TEST =====');

  try {
    final result = await SupabaseService.get(
      'profiles',
      query: '?select=id&limit=1',
    );

    debugPrint('SUCCESS');
    debugPrint('RESULT: $result');
  } catch (e, stack) {
    debugPrint('FAILED');
    debugPrint('ERROR: $e');
    debugPrint('STACK: $stack');
  }

  debugPrint('=========================');

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('تم الاختبار، راجع PowerShell'),
        ),
      ),
    ),
  );
}
