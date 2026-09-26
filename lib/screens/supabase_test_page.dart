import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  String result = 'جاري اختبار الاتصال...';

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    try {
      final data = await SupabaseService.get('users');

      if (!mounted) return;

      setState(() {
        result = 'تم الاتصال بنجاح ✅\n\n'
            'عدد السجلات: ${data.length}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        result = 'فشل الاتصال ❌\n\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار Supabase'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
