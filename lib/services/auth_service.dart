import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fitness_storage.dart';
import 'supabase_service.dart';

class AuthService {
  static const String _emailKey = 'account_email';
  static const String _usernameKey = 'account_username';
  static const String _nameKey = 'account_name';
  static const String _ageKey = 'account_age';
  static const String _heightKey = 'account_height';
  static const String _weightKey = 'account_weight';
  static const String _genderKey = 'account_gender';
  static const String _goalKey = 'account_goal';
  static const String _activityKey = 'account_activity';
  static const String _profileIdKey = 'supabase_profile_id';

  static String? lastRegisterError;
  static String? lastLoginError;

  static SupabaseClient get _client =>
      Supabase.instance.client;

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String goal,
    required String activity,
    int? dailyCalories,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    lastRegisterError = null;

    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();

      if (cleanName.isEmpty) {
        lastRegisterError = 'أدخل الاسم';
        return false;
      }

      if (cleanEmail.isEmpty) {
        lastRegisterError = 'أدخل البريد الإلكتروني';
        return false;
      }

      if (!_isValidEmail(cleanEmail)) {
        lastRegisterError = 'تأكد من صحة البريد الإلكتروني';
        return false;
      }

      if (password.length < 6) {
        lastRegisterError =
            'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        return false;
      }

      final authResponse = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );

      final user = authResponse.user;

      if (user == null) {
        lastRegisterError = 'تعذر إنشاء حساب المستخدم';
        return false;
      }

      final profile = await SupabaseService.post(
        'profiles',
        {
          'id': user.id,
          'username': cleanName,
          'name': cleanName,
          'full_name': cleanName,
          'email': cleanEmail,
          'age': age,
          'height_cm': height,
          'current_weight_kg': weight,
          'gender': gender,
          'goal': goal,
          'activity_level': activity,
          'daily_calories': dailyCalories,
          'protein_target': proteinTarget,
          'carbs_target': carbsTarget,
          'fat_target': fatTarget,
        },
      );

      final profileId = profile['id'] ?? user.id;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _nameKey,
        cleanName,
      );

      await prefs.setString(
        _emailKey,
        cleanEmail,
      );

      await prefs.setInt(
        _ageKey,
        age,
      );

      await prefs.setDouble(
        _heightKey,
        height,
      );

      await prefs.setDouble(
        _weightKey,
        weight,
      );

      await prefs.setString(
        _genderKey,
        gender,
      );

      await prefs.setString(
        _goalKey,
        goal,
      );

      await prefs.setString(
        _activityKey,
        activity,
      );

      await prefs.setString(
        _profileIdKey,
        profileId.toString(),
      );

      if (authResponse.session == null) {
        lastRegisterError =
            'تم إنشاء الحساب بنجاح.\n'
            'أرسلنا رسالة تأكيد إلى بريدك الإلكتروني.\n'
            'أكد البريد ثم سجل الدخول.';
      }

      return true;
    } on AuthException catch (e) {
      lastRegisterError =
          'Supabase Auth Error:\n'
          '${e.message}\n'
          'Status: ${e.statusCode ?? 'غير معروف'}';

      return false;
    } catch (e) {
      lastRegisterError = 'Register Error:\n$e';
      return false;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    lastLoginError = null;

    try {
      final username = email.trim();


      if (username.isEmpty) {
        lastLoginError = 'أدخل اسم المستخدم';
        return false;
      }

      if (password.isEmpty) {
        lastLoginError = 'أدخل كلمة المرور';
        return false;
      }

      final profiles = await SupabaseService.get(
        'profiles',
        query:
            '?username=eq.${Uri.encodeQueryComponent(username)}'
            '&select=email,id',
      );

      if (profiles.isEmpty) {
        lastLoginError = 'لم يتم العثور على اسم المستخدم في قاعدة البيانات';
        return false;
      }

      final profileEmail = profiles.first['email']?.toString();

      if (profileEmail == null || profileEmail.isEmpty) {
        lastLoginError = 'تعذر العثور على البريد المرتبط بالحساب';
        return false;
      }

      final cleanEmail = profileEmail.trim().toLowerCase();

      debugPrint('LOGIN USERNAME: $username');
      debugPrint('LOGIN EMAIL: $cleanEmail');

      final response = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        lastLoginError = 'تعذر تسجيل الدخول';
        return false;
      }

      await _loadProfile(user.id);
      await _syncFitnessDataAfterLogin();

      return true;
    } on AuthException catch (e) {
      lastLoginError = _translateAuthError(e.message);
      return false;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      lastLoginError = 'تعذر تسجيل الدخول';
      return false;
    }
  }

  // ============================================================
  // SYNC FITNESS DATA AFTER LOGIN
  // ============================================================

  static Future<void> _syncFitnessDataAfterLogin() async {
    try {
      debugPrint(
        'FITNESS SYNC AFTER LOGIN START',
      );

      await FitnessStorage.syncFromSupabase();

      debugPrint(
        'FITNESS SYNC AFTER LOGIN SUCCESS',
      );
    } catch (e) {
      debugPrint(
        'FITNESS SYNC AFTER LOGIN ERROR: $e',
      );

      // لا نفشل تسجيل الدخول إذا فشلت المزامنة.
      // البيانات المحلية تبقى متاحة.
    }
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  static Future<void> _loadProfile(
    String userId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final profiles = await SupabaseService.get(
      'profiles',
      query:
          '?id=eq.${Uri.encodeQueryComponent(userId)}'
          '&select=*',
    );

    if (profiles.isEmpty) {
      await prefs.setString(
        _profileIdKey,
        userId,
      );

      return;
    }

    final profile = profiles.first;

    final name =
        profile['name'] ??
        profile['full_name'];

    final email =
        profile['email'];

    if (name != null) {
      await prefs.setString(
        _nameKey,
        name.toString(),
      );
    }

    if (email != null) {
      await prefs.setString(
        _emailKey,
        email.toString(),
      );
    }

    if (profile['age'] is num) {
      await prefs.setInt(
        _ageKey,
        (profile['age'] as num).toInt(),
      );
    }

    final height =
        profile['height_cm'] ??
        profile['height'];

    if (height is num) {
      await prefs.setDouble(
        _heightKey,
        height.toDouble(),
      );
    }

    final weight =
        profile['current_weight_kg'] ??
        profile['weight'];

    if (weight is num) {
      await prefs.setDouble(
        _weightKey,
        weight.toDouble(),
      );
    }

    final gender =
        profile['gender'];

    if (gender != null) {
      await prefs.setString(
        _genderKey,
        gender.toString(),
      );
    }

    final goal =
        profile['goal'];

    if (goal != null) {
      await prefs.setString(
        _goalKey,
        goal.toString(),
      );
    }

    final activity =
        profile['activity_level'] ??
        profile['activity'];

    if (activity != null) {
      await prefs.setString(
        _activityKey,
        activity.toString(),
      );
    }

    await prefs.setString(
      _profileIdKey,
      userId,
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  static Future<bool> hasAccount() async {
    return _client.auth.currentUser != null;
  }

  static Future<bool> isEmailConfirmed() async {
    final user =
        _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.emailConfirmedAt != null;
  }

  static Future<String?> getProfileId() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _profileIdKey,
    );
  }

  static Future<String?> getName() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _nameKey,
    );
  }

  static Future<String?> getEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _emailKey,
    );
  }

  static Future<String?> getUsername() async {
    return getEmail();
  }

  static Future<String?> getGender() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _genderKey,
    );
  }

  static Future<String?> getGoal() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _goalKey,
    );
  }

  static Future<String?> getActivity() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _activityKey,
    );
  }

  static Future<int?> getAge() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
      _ageKey,
    );
  }

  static Future<double?> getHeight() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getDouble(
      _heightKey,
    );
  }

  static Future<double?> getWeight() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getDouble(
      _weightKey,
    );
  }

  // ============================================================
  // RESEND EMAIL
  // ============================================================

  static Future<bool> resendConfirmationEmail({
    required String email,
  }) async {
    try {
      final cleanEmail =
          email.trim().toLowerCase();

      await _client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
      );

      return true;
    } on AuthException catch (e) {
      lastLoginError =
          _translateAuthError(
        e.message,
      );

      return false;
    } catch (e) {
      lastLoginError =
          'تعذر إرسال رسالة التأكيد: $e';

      return false;
    }
  }

  // ============================================================
  // PASSWORD RECOVERY
  // ============================================================

  static Future<bool> sendPasswordRecovery({
    required String email,
  }) async {
    try {
      final cleanEmail =
          email.trim().toLowerCase();

      await _client.auth.resetPasswordForEmail(
        cleanEmail,
      );

      return true;
    } on AuthException catch (e) {
      lastLoginError =
          _translateAuthError(
        e.message,
      );

      return false;
    } catch (e) {
      lastLoginError =
          'تعذر إرسال رابط استعادة كلمة المرور: $e';

      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    await _client.auth.signOut();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_heightKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_goalKey);
    await prefs.remove(_activityKey);
    await prefs.remove(_profileIdKey);
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  static Future<void> deleteAccount() async {
    await logout();
  }

  // ============================================================
  // CLEAR LOCAL DATA
  // ============================================================

  static Future<void> clearLocalAccountForTesting() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_heightKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_goalKey);
    await prefs.remove(_activityKey);
    await prefs.remove(_profileIdKey);
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  static bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ============================================================
  // ERROR TRANSLATION
  // ============================================================

  static String _translateAuthError(
    String message,
  ) {
    final text =
        message.toLowerCase();

    if (text.contains(
      'invalid login credentials',
    )) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }

    if (text.contains(
      'user already registered',
    )) {
      return 'هذا البريد الإلكتروني مسجل مسبقًا';
    }

    if (text.contains(
      'email not confirmed',
    )) {
      return 'يجب تأكيد البريد الإلكتروني أولًا';
    }

    if (text.contains(
      'email rate limit exceeded',
    )) {
      return 'تم تجاوز حد إرسال رسائل البريد. حاول لاحقًا';
    }

    if (text.contains(
      'password',
    )) {
      return 'كلمة المرور غير صحيحة أو غير صالحة';
    }

    if (text.contains(
      'email',
    )) {
      return 'تأكد من صحة البريد الإلكتروني';
    }

    return message;
  }
}






