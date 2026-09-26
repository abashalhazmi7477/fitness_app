import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

class FitnessStorage {
  static const String _mealsKey = 'fitness_meals';
  static const String _workoutsKey = 'fitness_workouts';
  static const String _waterKey = 'fitness_water';
  static const String _stepsKey = 'fitness_steps';
  static const String _weightKey = 'fitness_weight';
static const String _dailyDateKey = 'fitness_daily_date';

  static const String _plansKey = 'fitness_workout_plans';
  static const String _sessionsKey = 'fitness_plan_sessions';
  static const String _plansOwnerKey = 'fitness_workout_plans_owner';

  static const int maxPlans = 6;

  // ============================================================
  // أدوات داخلية
  // ============================================================

  static List<Map<String, dynamic>> _decodeList(String? data) {
    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data);

      if (decoded is List) {
        return decoded
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }
    } catch (_) {
      // البيانات المحلية غير صالحة.
    }

    return [];
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Future<void> _ensureNewDay() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _dateOnly(DateTime.now());
  final savedDate = prefs.getString(_dailyDateKey);

  if (savedDate != today) {
    await prefs.setString(_dailyDateKey, today);
    await prefs.setInt(_stepsKey, 0);
    await prefs.setDouble(_waterKey, 0);
  }
}

static String _dateOnly(DateTime date) {
    final local = date.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // الوجبات
  // ============================================================

  static Future<List<Map<String, dynamic>>> _getAllMeals() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_mealsKey));
  }

  static Future<List<Map<String, dynamic>>> getMeals() async {
    final meals = await _getAllMeals();
    final today = _dateOnly(DateTime.now());
    return meals.where((meal) {
      final date = DateTime.tryParse(meal['date']?.toString() ?? '');
      return date != null && _dateOnly(date) == today;
    }).toList();
  }

  static Map<String, dynamic> _convertSupabaseMealToLocal(
    Map<String, dynamic> meal,
  ) {
    final consumedAt =
        meal['consumed_at'] ??
        meal['created_at'] ??
        DateTime.now().toIso8601String();

    return {
      'id': DateTime.now().microsecondsSinceEpoch,
      'supabase_id': meal['id']?.toString() ?? '',
      'name': meal['meal_name'] ?? '',
      'quantity': 0,
      'unit': 'جم',
      'meal_type': meal['meal_type'],
      'calories': _toDouble(meal['calories']),
      'protein': _toDouble(meal['protein']),
      'carbs': _toDouble(meal['carbs']),
      'fats': _toDouble(meal['fat']),
      'fiber': _toDouble(meal['fiber']),
      'image_url': meal['image_url'],
      'notes': meal['notes'],
      'date': consumedAt.toString(),
    };
  }

  static Future<void> saveMeals(
    List<Map<String, dynamic>> meals,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _mealsKey,
      jsonEncode(meals),
    );
  }

  static Future<void> addMeal({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
    double quantity = 0,
    String unit = 'جم',
    String? mealType,
    double fiber = 0,
    String? imageUrl,
    String? notes,
    DateTime? consumedAt,
  }) async {
    final meals = await _getAllMeals();

    final now = consumedAt ?? DateTime.now();

    final localMeal = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'meal_type': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'image_url': imageUrl,
      'notes': notes,
      'date': now.toIso8601String(),
    };

    meals.add(localMeal);

    await saveMeals(meals);

    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      final remoteMeal = await SupabaseService.post(
        'meals',
        {
          'user_id': profileId,
          'meal_name': name,
          'meal_type': mealType,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fats,
          'fiber': fiber,
          'image_url': imageUrl,
          'notes': notes,
          'consumed_at': now.toIso8601String(),
        },
      );

      final supabaseId = remoteMeal['id'];

      if (supabaseId != null) {
        localMeal['supabase_id'] = supabaseId.toString();

        await saveMeals(meals);
      }
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على الحفظ المحلي.
    }
  }

  static Future<void> deleteMeal(int id) async {
    final meals = await _getAllMeals();

    Map<String, dynamic>? deletedMeal;

    for (final meal in meals) {
      if (meal['id'].toString() == id.toString()) {
        deletedMeal = meal;
        break;
      }
    }

    meals.removeWhere(
      (meal) => meal['id'].toString() == id.toString(),
    );

    await saveMeals(meals);

    try {
      final supabaseId =
          deletedMeal?['supabase_id']?.toString() ?? '';

      if (supabaseId.isEmpty) {
        return;
      }

      await SupabaseService.delete(
        'meals',
        'id=eq.${Uri.encodeQueryComponent(supabaseId)}',
      );
    } catch (e) {
      // تجاهل خطأ الحذف من Supabase.
    }
  }

  static Future<void> clearMeals() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_mealsKey);
  }

  // ============================================================
  // الأداء القديم
  // ============================================================

  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();

    return _decodeList(
      prefs.getString(_workoutsKey),
    );
  }

  static Future<void> saveWorkouts(
    List<Map<String, dynamic>> workouts,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _workoutsKey,
      jsonEncode(workouts),
    );
  }

  static Future<void> addWorkout({
    required String name,
    required String exercise,
    required double weight,
    required int sets,
    required int reps,
    List<Map<String, dynamic>>? setDetails,
  }) async {
    final workouts = await getWorkouts();

    final now = DateTime.now();

    final normalizedSets =
        setDetails ??
        List.generate(
          sets,
          (index) => {
            'set': index + 1,
            'weight': weight,
            'reps': reps,
            'completed': false,
          },
        );

    workouts.add({
      'id': now.microsecondsSinceEpoch,
      'name': name,
      'exercise': exercise,
      'weight': weight,
      'sets': sets,
      'reps': reps,
      'setDetails': normalizedSets,
      'date': now.toIso8601String(),
    });

    await saveWorkouts(workouts);
  }

  static Future<void> deleteWorkout(int id) async {
    final workouts = await getWorkouts();

    workouts.removeWhere(
      (workout) => workout['id'].toString() == id.toString(),
    );

    await saveWorkouts(workouts);
  }

  static Future<List<Map<String, dynamic>>> getExerciseHistory(
    String exercise,
  ) async {
    final workouts = await getWorkouts();

    final target = exercise.trim().toLowerCase();

    final result = workouts.where(
      (workout) {
        final workoutExercise =
            workout['exercise']?.toString().trim().toLowerCase() ?? '';

        return workoutExercise == target;
      },
    ).toList();

    result.sort(
      (a, b) {
        final aDate =
            DateTime.tryParse(
              a['date']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            DateTime.tryParse(
              b['date']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      },
    );

    return result;
  }

  static Future<Map<String, dynamic>?> getLastExercise(
    String exercise,
  ) async {
    final history = await getExerciseHistory(exercise);

    if (history.isEmpty) {
      return null;
    }

    return history.first;
  }

  // ============================================================
  // الجداول
  // ============================================================

  static Future<List<Map<String, dynamic>>> getPlans() async {
    final prefs = await SharedPreferences.getInstance();

    return _decodeList(
      prefs.getString(_plansKey),
    );
  }

  static Future<void> savePlans(
    List<Map<String, dynamic>> plans,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _plansKey,
      jsonEncode(plans),
    );
  }

  static Future<int> getPlanLimit() async {
    return maxPlans;
  }

  static Future<bool> canAddPlan() async {
    final plans = await getPlans();

    return plans.length < maxPlans;
  }

  // ============================================================
  // إضافة جدول
  // ============================================================

  static Future<bool> addPlan({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final plans = await getPlans();

    if (plans.length >= maxPlans) {
      return false;
    }

    final now = DateTime.now();
    final localId = now.microsecondsSinceEpoch;

    final plan = <String, dynamic>{
      'id': localId,
      'name': name,
      'owner': 'me',
      'public': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'exercises': exercises,
    };

    plans.add(plan);

    await savePlans(plans);

    await _syncPlanToSupabase(plan);

    return true;
  }

  // ============================================================
  // تحديث جدول
  // ============================================================

  static Future<bool> updatePlan(
    int id, {
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final plans = await getPlans();

    final index = plans.indexWhere(
      (plan) => plan['id'].toString() == id.toString(),
    );

    if (index == -1) {
      return false;
    }

    final now = DateTime.now();

    plans[index]['name'] = name;
    plans[index]['exercises'] = exercises;
    plans[index]['updatedAt'] = now.toIso8601String();

    await savePlans(plans);

    await _syncPlanToSupabase(plans[index]);

    return true;
  }

  // ============================================================
  // حذف جدول
  // ============================================================

  static Future<void> deletePlan(int id) async {
    final plans = await getPlans();

    Map<String, dynamic>? deletedPlan;

    for (final plan in plans) {
      if (plan['id'].toString() == id.toString()) {
        deletedPlan = plan;
        break;
      }
    }

    plans.removeWhere(
      (plan) => plan['id'].toString() == id.toString(),
    );

    await savePlans(plans);

    if (deletedPlan != null) {
      await _deletePlanFromSupabase(deletedPlan);
    }
  }

  static Future<Map<String, dynamic>?> getPlan(int id) async {
    final plans = await getPlans();

    for (final plan in plans) {
      if (plan['id'].toString() == id.toString()) {
        return plan;
      }
    }

    return null;
  }

  // ============================================================
  // نسخ جدول
  // ============================================================

  static Future<bool> copyPlan(
    Map<String, dynamic> sourcePlan,
  ) async {
    final canAdd = await canAddPlan();

    if (!canAdd) {
      return false;
    }

    final plans = await getPlans();

    final sourceExercises =
        sourcePlan['exercises'] is List
            ? (sourcePlan['exercises'] as List)
                .map(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList()
            : <Map<String, dynamic>>[];

    final now = DateTime.now();

    final plan = <String, dynamic>{
      'id': now.microsecondsSinceEpoch,
      'name': '${sourcePlan['name'] ?? 'جدول'} - نسخة',
      'owner': 'me',
      'public': false,
      'copiedFrom': sourcePlan['id']?.toString(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'exercises': sourceExercises,
    };

    plans.add(plan);

    await savePlans(plans);

    await _syncPlanToSupabase(plan);

    return true;
  }

  // ============================================================
  // مزامنة جدول واحد إلى Supabase
  // ============================================================

  static Future<void> _syncPlanToSupabase(
    Map<String, dynamic> plan,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return;
      }

      final userId = user.id;
      final remoteId = plan['supabase_id']?.toString() ?? '';

      final planData = Map<String, dynamic>.from(plan);
      planData.remove('supabase_id');

      final payload = {
        'user_id': userId,
        'name': plan['name']?.toString() ?? 'جدول',
        'plan_data': planData,
        'updated_at':
            plan['updatedAt']?.toString() ??
            DateTime.now().toIso8601String(),
      };

      if (remoteId.isNotEmpty) {
        await SupabaseService.update(
          'workout_plans',
          'id=eq.${Uri.encodeQueryComponent(remoteId)}&user_id=eq.${Uri.encodeQueryComponent(userId)}',
          payload,
        );
        return;
      }

      final remote = await SupabaseService.post(
        'workout_plans',
        {
          ...payload,
          'created_at':
              plan['createdAt']?.toString() ??
              DateTime.now().toIso8601String(),
        },
      );

      final newRemoteId = remote['id']?.toString();

      if (newRemoteId == null || newRemoteId.isEmpty) {
        return;
      }

      plan['supabase_id'] = newRemoteId;

      final plans = await getPlans();

      for (final localPlan in plans) {
        if (localPlan['id'].toString() ==
            plan['id'].toString()) {
          localPlan['supabase_id'] = newRemoteId;
          break;
        }
      }

      await savePlans(plans);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _plansOwnerKey,
        userId,
      );
      // تجاهل الخطأ
    } catch (_) {
      // تجاهل خطأ المزامنة
    }
  }
  // ============================================================
  // حذف جدول من Supabase
  // ============================================================

  static Future<void> _deletePlanFromSupabase(
    Map<String, dynamic> plan,
  ) async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      final remoteId =
          plan['supabase_id']?.toString() ?? '';

      if (remoteId.isEmpty) {
        return;
      }

      await SupabaseService.delete(
        'workout_plans',
        'id=eq.${Uri.encodeQueryComponent(remoteId)}'
        '&user_id=eq.${Uri.encodeQueryComponent(profileId)}',
      );
    } catch (e) {
      // تجاهل خطأ الحذف من Supabase.
    }
  }

  // ============================================================
  // جلسات التمرين
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getWorkoutSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final sessions = _decodeList(
      prefs.getString(_sessionsKey),
    );

    sessions.sort(
      (a, b) {
        final aDate =
            DateTime.tryParse(
              a['startedAt']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            DateTime.tryParse(
              b['startedAt']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      },
    );

    return sessions;
  }

  static Future<void> saveWorkoutSessions(
    List<Map<String, dynamic>> sessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions),
    );
  }

  // ============================================================
  // حفظ جلسة تمرين كاملة
  // ============================================================

  static Future<int> saveWorkoutSession({
    required int planId,
    required String planName,
    required DateTime startedAt,
    required int durationSeconds,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final sessions = await getWorkoutSessions();

    final id = DateTime.now().microsecondsSinceEpoch;

    final normalizedExercises = exercises.map(
      (exercise) {
        final rawSets = exercise['sets'];

        final normalizedSets =
            rawSets is List
                ? rawSets.map(
                    (set) {
                      final map =
                          Map<String, dynamic>.from(set);

                      return {
                        'set': _toInt(map['set']),
                        'weight': _toDouble(map['weight']),
                        'reps': _toInt(map['reps']),
                        'completed': map['completed'] == true,
                      };
                    },
                  ).toList()
                : <Map<String, dynamic>>[];

        return {
          'exerciseId':
              exercise['exerciseId'] ??
              exercise['id']?.toString() ??
              '',
          'exercise':
              exercise['exercise'] ??
              exercise['name'] ??
              '',
          'sets': normalizedSets,
        };
      },
    ).toList();

    sessions.add({
      'id': id,
      'planId': planId,
      'planName': planName,
      'startedAt': startedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'exercises': normalizedExercises,
    });

    await saveWorkoutSessions(sessions);

    await _syncWorkoutSessionToSupabase(
      planName: planName,
      startedAt: startedAt,
      durationSeconds: durationSeconds,
      exercises: normalizedExercises,
    );

    return id;
  }

  static Future<void> _syncWorkoutSessionToSupabase({
    required String planName,
    required DateTime startedAt,
    required int durationSeconds,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      final workout = await SupabaseService.post(
        'workouts',
        {
          'user_id': profileId,
          'workout_name': planName,
          'started_at': startedAt.toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
          'duration_minutes': (durationSeconds / 60).round(),
        },
      );

      final workoutId = workout['id'];

      if (workoutId == null) {
        return;
      }

      for (final exercise in exercises) {
        final exerciseId =
            exercise['exerciseId']?.toString() ?? '';

        final exerciseName =
            exercise['exercise']?.toString() ?? '';

        if (exerciseId.isEmpty) {
          continue;
        }

        final existingExercise = await SupabaseService.get(
          'exercises',
          query:
              '?id=eq.${Uri.encodeQueryComponent(exerciseId)}'
              '&select=id',
        );

        if (existingExercise.isEmpty) {
          await SupabaseService.post(
            'exercises',
            {
              'id': exerciseId,
              'name': exerciseName,
              'english_name': exerciseName,
              'muscle': '',
              'equipment': '',
              'technique': '',
            },
          );
        }

        final rawSets = exercise['sets'];

        if (rawSets is! List) {
          continue;
        }

        for (final rawSet in rawSets) {
          final set = Map<String, dynamic>.from(rawSet);

          if (set['completed'] != true) {
            continue;
          }

          await SupabaseService.post(
            'workout_sets',
            {
              'workout_id': workoutId,
              'exercise_id': exerciseId,
              'set_number': _toInt(set['set']),
              'weight_kg': _toDouble(set['weight']),
              'reps': _toInt(set['reps']),
            },
          );
        }
      }
    } catch (e) {
      // تجاهل خطأ مزامنة التمارين.
    }
  }

  static Future<Map<String, dynamic>?> getWorkoutSession(
    int id,
  ) async {
    final sessions = await getWorkoutSessions();

    for (final session in sessions) {
      if (session['id'].toString() == id.toString()) {
        return session;
      }
    }

    return null;
  }

  static Future<void> deleteWorkoutSession(int id) async {
    final sessions = await getWorkoutSessions();

    sessions.removeWhere(
      (session) => session['id'].toString() == id.toString(),
    );

    await saveWorkoutSessions(sessions);
  }

  static Future<void> clearWorkoutSessions() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_sessionsKey);
  }

  // ============================================================
  // سجل تمرين معين
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getExerciseSessionHistory(
    String exercise,
  ) async {
    final sessions = await getWorkoutSessions();

    final target = exercise.trim().toLowerCase();

    final result = <Map<String, dynamic>>[];

    for (final session in sessions) {
      final rawExercises = session['exercises'];

      if (rawExercises is! List) {
        continue;
      }

      for (final rawExercise in rawExercises) {
        final exerciseMap =
            Map<String, dynamic>.from(rawExercise);

        final name =
            exerciseMap['exercise']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (name == target) {
          result.add({
            'sessionId': session['id'],
            'planId': session['planId'],
            'planName': session['planName'],
            'startedAt': session['startedAt'],
            'durationSeconds': session['durationSeconds'],
            'exerciseId': exerciseMap['exerciseId'],
            'exercise': exerciseMap['exercise'],
            'sets': exerciseMap['sets'] ?? [],
          });
        }
      }
    }

    result.sort(
      (a, b) {
        final aDate =
            DateTime.tryParse(
              a['startedAt']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            DateTime.tryParse(
              b['startedAt']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      },
    );

    return result;
  }

  // ============================================================
  // آخر أداء للتمرين
  // ============================================================

  static Future<Map<String, dynamic>?>
      getLastPerformanceForExercise(
    String exercise,
  ) async {
    final history =
        await getExerciseSessionHistory(exercise);

    if (history.isEmpty) {
      return null;
    }

    return history.first;
  }

  // ============================================================
  // آخر مجموعة مكتملة
  // ============================================================

  static Future<Map<String, dynamic>?>
      getLastCompletedSetForExercise(
    String exercise,
  ) async {
    final performance =
        await getLastPerformanceForExercise(exercise);

    if (performance == null) {
      return null;
    }

    final rawSets = performance['sets'];

    if (rawSets is! List) {
      return null;
    }

    final completedSets = rawSets
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .where(
          (set) => set['completed'] == true,
        )
        .toList();

    if (completedSets.isEmpty) {
      return null;
    }

    return completedSets.last;
  }

  // ============================================================
  // آخر أداء لمجموعة معينة
  // ============================================================

  static Future<Map<String, dynamic>?>
      getLastSetPerformance(
    String exercise, {
    required int setNumber,
  }) async {
    final performance =
        await getLastPerformanceForExercise(exercise);

    if (performance == null) {
      return null;
    }

    final rawSets = performance['sets'];

    if (rawSets is! List) {
      return null;
    }

    for (final rawSet in rawSets) {
      final set = Map<String, dynamic>.from(rawSet);

      if (_toInt(set['set']) == setNumber &&
          set['completed'] == true) {
        return set;
      }
    }

    return null;
  }

  // ============================================================
  // إحصائيات التمارين
  // ============================================================

  static Future<int> getWorkoutSessionCount() async {
    final sessions = await getWorkoutSessions();

    return sessions.length;
  }

  static Future<int> getTotalWorkoutDuration() async {
    final sessions = await getWorkoutSessions();

    var total = 0;

    for (final session in sessions) {
      total += _toInt(
        session['durationSeconds'],
      );
    }

    return total;
  }

  static Future<Map<String, dynamic>?>
      getLastWorkoutSession() async {
    final sessions = await getWorkoutSessions();

    if (sessions.isEmpty) {
      return null;
    }

    return sessions.first;
  }

  // ============================================================
  // الماء
  // ============================================================

  static Future<double> getWater() async {
    await _ensureNewDay();
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_waterKey) ?? 0;
  }

  static Future<void> saveWater(
    double value,
  ) async {
    await _ensureNewDay();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      _waterKey,
      value,
    );

    await _syncWaterToSupabase(value);
  }

  static Future<void> addWater(
    double amount,
  ) async {
    final current = await getWater();

    await saveWater(
      current + amount,
    );
  }

  static Future<void> _syncWaterToSupabase(
    double water,
  ) async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      final today = _dateOnly(DateTime.now());

      final existing = await SupabaseService.get(
        'daily_activity',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&activity_date=eq.$today'
            '&select=id'
            '&limit=1',
      );

      if (existing.isNotEmpty) {
        final id = existing.first['id']?.toString();

        if (id != null && id.isNotEmpty) {
          await SupabaseService.update(
            'daily_activity',
            'id=eq.${Uri.encodeQueryComponent(id)}',
            {
              'water_liters': water,
            },
          );
        }

        return;
      }

      await SupabaseService.post(
        'daily_activity',
        {
          'user_id': profileId,
          'activity_date': today,
          'steps': 0,
          'water_liters': water,
          'active_calories': 0,
          'distance_km': 0,
        },
      );
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على الحفظ المحلي.
    }
  }

  static Future<void> _syncWaterFromSupabase(
    String profileId,
  ) async {
    try {
      final today = _dateOnly(DateTime.now());

      final rows = await SupabaseService.get(
        'daily_activity',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&activity_date=eq.$today'
            '&select=water_liters'
            '&limit=1',
      );

      if (rows.isEmpty) {
        return;
      }

      final value = double.tryParse(
        rows.first['water_liters']?.toString() ?? '0',
      );

      if (value == null) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(
        _waterKey,
        value,
      );
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على البيانات المحلية.
    }
  }

  // ============================================================
  // الخطوات
  // ============================================================

  static Future<int> getSteps() async {
    await _ensureNewDay();
    final prefs = await SharedPreferences.getInstance();

    final localSteps = prefs.getInt(_stepsKey) ?? 0;

    try {
      final profileId = await AuthService.getProfileId();

      if (profileId != null && profileId.isNotEmpty) {
        final today = _dateOnly(DateTime.now());

        final result = await SupabaseService.get(
          'daily_activity',
          query:
              '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
              '&activity_date=eq.$today'
              '&select=steps'
              '&limit=1',
        );

        if (result.isNotEmpty) {
          final remoteSteps = _toInt(
            result.first['steps'],
          );

          await prefs.setInt(
            _stepsKey,
            remoteSteps,
          );

          return remoteSteps;
        }
      }
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على القيمة المحلية.
    }

    return localSteps;
  }

  static Future<void> saveSteps(
    int value,
  ) async {
    await _ensureNewDay();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _stepsKey,
      value,
    );

    await _syncStepsToSupabase(value);
  }

  static Future<void> _syncStepsToSupabase(
    int steps,
  ) async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      final today = _dateOnly(DateTime.now());

      final existing = await SupabaseService.get(
        'daily_activity',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&activity_date=eq.$today'
            '&select=id'
            '&limit=1',
      );

      if (existing.isNotEmpty) {
        final id = existing.first['id']?.toString();

        if (id != null && id.isNotEmpty) {
          await SupabaseService.update(
            'daily_activity',
            'id=eq.${Uri.encodeQueryComponent(id)}',
            {
              'steps': steps,
            },
          );
        }

        return;
      }

      await SupabaseService.post(
        'daily_activity',
        {
          'user_id': profileId,
          'activity_date': today,
          'steps': steps,
          'water_liters': 0,
          'active_calories': 0,
          'distance_km': 0,
        },
      );
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على القيمة المحلية.
    }
  }

  static Future<void> syncCurrentSteps() async {
    final steps = await getSteps();

    await _syncStepsToSupabase(steps);
  }

  // ============================================================
  // الوزن
  // ============================================================

  static Future<double?> getWeight() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_weightKey);
  }

  static Future<void> saveWeight(
    double value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      _weightKey,
      value,
    );

    await _syncWeightToSupabase(value);
  }

  static Future<void> _syncWeightToSupabase(
    double value,
  ) async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      await SupabaseService.post(
        'weight_logs',
        {
          'user_id': profileId,
          'weight_kg': value,
          'recorded_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // تجاهل خطأ المزامنة والحفاظ على الوزن المحلي.
    }
  }

  static Future<double?>
      getLatestWeightFromSupabase() async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return null;
      }

      final result = await SupabaseService.get(
        'weight_logs',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&select=weight_kg,recorded_at'
            '&order=recorded_at.desc'
            '&limit=1',
      );

      if (result.isEmpty) {
        return null;
      }

      return _toDouble(
        result.first['weight_kg'],
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> syncCurrentWeight() async {
    final weight = await getWeight();

    if (weight == null) {
      return;
    }

    await _syncWeightToSupabase(weight);
  }

  // ============================================================
  // مزامنة بيانات الحساب من Supabase
  // ============================================================

  static Future<List<Map<String, dynamic>>> getLastFiveDaysHistory() async {
    final result = <Map<String, dynamic>>[];

    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return result;
      }

      final today = DateTime.now();

      final activities = await SupabaseService.get(
        'daily_activity',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&activity_date=gte.${_dateOnly(today.subtract(const Duration(days: 4)))}'
            '&activity_date=lte.${_dateOnly(today)}'
            '&select=activity_date,steps,water_liters'
            '&order=activity_date.desc',
      );

      final meals = await SupabaseService.get(
        'meals',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&select=calories,consumed_at'
            '&order=consumed_at.desc',
      );

      for (int i = 0; i < 5; i++) {
        final date = today.subtract(Duration(days: i));
        final dateText = _dateOnly(date);

        double calories = 0;

        for (final meal in meals) {
          final consumedAt = DateTime.tryParse(
            meal['consumed_at']?.toString() ?? '',
          );

          if (consumedAt != null &&
              _dateOnly(consumedAt) == dateText) {
            calories += _toDouble(meal['calories']);
          }
        }

        final rows = activities.where(
          (item) => item['activity_date']?.toString() == dateText,
        );

        final activity =
            rows.isNotEmpty ? rows.first : <String, dynamic>{};

        result.add({
          'date': dateText,
          'steps': _toInt(activity['steps']),
          'water': _toDouble(activity['water_liters']),
          'calories': calories,
        });
      }
    } catch (_) {
      // تجاهل خطأ سجل الأيام.
    }

    return result;
  }
  static Future<void> syncFromSupabase() async {
    try {
      final profileId = await AuthService.getProfileId();

      if (profileId == null || profileId.isEmpty) {
        return;
      }

      await _syncMealsFromSupabase(profileId);

      await _syncStepsFromSupabase(profileId);

      await _syncWaterFromSupabase(profileId);

      await _syncLatestWeightFromSupabase(profileId);

      await _syncPlansFromSupabase(profileId);
    } catch (e) {
      // تجاهل خطأ المزامنة.
    }
  }

  // ============================================================
  // مزامنة الوجبات
  // ============================================================

  static Future<void> _syncMealsFromSupabase(
    String profileId,
  ) async {
    try {
      final remoteMeals = await SupabaseService.get(
        'meals',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&select=*'
            '&order=consumed_at.desc',
      );

      if (remoteMeals.isEmpty) {
        return;
      }

      final convertedMeals =
          remoteMeals.map(_convertSupabaseMealToLocal).toList();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _mealsKey,
        jsonEncode(convertedMeals),
      );
    } catch (e) {
      // تجاهل خطأ مزامنة الوجبات.
    }
  }

  // ============================================================
  // مزامنة الخطوات
  // ============================================================

  static Future<void> _syncStepsFromSupabase(
    String profileId,
  ) async {
    try {
      final today = _dateOnly(DateTime.now());

      final result = await SupabaseService.get(
        'daily_activity',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&activity_date=eq.$today'
            '&select=steps'
            '&limit=1',
      );

      if (result.isEmpty) {
        return;
      }

      final steps = _toInt(
        result.first['steps'],
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        _stepsKey,
        steps,
      );
    } catch (e) {
      // تجاهل خطأ مزامنة الخطوات.
    }
  }

  // ============================================================
  // مزامنة الماء
  // ============================================================

  // تتم من خلال _syncWaterFromSupabase أعلاه.

  // ============================================================
  // مزامنة آخر وزن
  // ============================================================

  static Future<void> _syncLatestWeightFromSupabase(
    String profileId,
  ) async {
    try {
      final result = await SupabaseService.get(
        'weight_logs',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&select=weight_kg,recorded_at'
            '&order=recorded_at.desc'
            '&limit=1',
      );

      if (result.isEmpty) {
        return;
      }

      final weight = _toDouble(
        result.first['weight_kg'],
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(
        _weightKey,
        weight,
      );
    } catch (e) {
      // تجاهل خطأ مزامنة الوزن.
    }
  }

  // ============================================================
  // مزامنة خطط التمارين من Supabase
  // ============================================================

  static Future<void> _syncPlansFromSupabase(
    String profileId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final localPlans = _decodeList(
        prefs.getString(_plansKey),
      );

      final storedOwner =
          prefs.getString(_plansOwnerKey);

      final remotePlans = await SupabaseService.get(
        'workout_plans',
        query:
            '?user_id=eq.${Uri.encodeQueryComponent(profileId)}'
            '&select=*'
            '&order=created_at.asc',
      );

      // إذا كان الجهاز مستخدمًا لحساب مختلف،
      // لا نخلط خطط الحساب القديم مع الحساب الجديد.
      if (storedOwner != null &&
          storedOwner.isNotEmpty &&
          storedOwner != profileId) {
        final converted = _convertRemotePlans(remotePlans);

        await savePlans(converted);

        await prefs.setString(
          _plansOwnerKey,
          profileId,
        );

        return;
      }

      // أول مزامنة للحساب الحالي.
      // إذا كانت هناك خطط محلية قديمة، نرفعها إلى الحساب.
      if (remotePlans.isEmpty) {
        if (localPlans.isNotEmpty) {
          for (final plan in localPlans) {
            await _syncPlanToSupabase(plan);
          }
        }

        await prefs.setString(
          _plansOwnerKey,
          profileId,
        );

        return;
      }

      final convertedRemote =
          _convertRemotePlans(remotePlans);

      final remoteIds = convertedRemote
          .map(
            (plan) =>
                plan['supabase_id']?.toString() ?? '',
          )
          .where((id) => id.isNotEmpty)
          .toSet();

      final merged = <Map<String, dynamic>>[
        ...convertedRemote,
      ];

      // أي خطة محلية لم تُرفع بعد يتم رفعها.
      for (final localPlan in localPlans) {
        final localRemoteId =
            localPlan['supabase_id']?.toString() ?? '';

        if (localRemoteId.isEmpty) {
          await _syncPlanToSupabase(localPlan);

          final updatedRemoteId =
              localPlan['supabase_id']?.toString() ?? '';

          if (updatedRemoteId.isNotEmpty &&
              !remoteIds.contains(updatedRemoteId)) {
            merged.add(localPlan);
          }
        }
      }

      if (merged.length > maxPlans) {
        merged.removeRange(
          maxPlans,
          merged.length,
        );
      }

      await savePlans(merged);

      await prefs.setString(
        _plansOwnerKey,
        profileId,
      );
    } catch (e) {
      // إذا فشلت المزامنة تبقى الخطط المحلية.
    }
  }

  static List<Map<String, dynamic>> _convertRemotePlans(
    List<Map<String, dynamic>> remotePlans,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final remote in remotePlans) {
      final rawData = remote['plan_data'];

      Map<String, dynamic> plan;

      if (rawData is Map) {
        plan = Map<String, dynamic>.from(rawData);
      } else {
        plan = {};
      }

      plan['supabase_id'] =
          remote['id']?.toString() ?? '';

      plan['name'] =
          remote['name']?.toString() ??
          plan['name'] ??
          'جدول';

      if (!plan.containsKey('id')) {
        plan['id'] =
            DateTime.now().microsecondsSinceEpoch +
            result.length;
      }

      plan['owner'] = 'me';

      plan['public'] =
          plan['public'] == true;

      plan['createdAt'] =
          plan['createdAt'] ??
          remote['created_at']?.toString() ??
          DateTime.now().toIso8601String();

      plan['updatedAt'] =
          remote['updated_at']?.toString() ??
          plan['updatedAt'] ??
          DateTime.now().toIso8601String();

      if (plan['exercises'] is! List) {
        plan['exercises'] =
            <Map<String, dynamic>>[];
      }

      result.add(plan);
    }

    return result;
  }

  // ============================================================
  // حذف جميع بيانات اللياقة
  // ============================================================

  static Future<void> clearAllFitnessData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_mealsKey);
    await prefs.remove(_workoutsKey);
    await prefs.remove(_waterKey);
    await prefs.remove(_stepsKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_plansKey);
    await prefs.remove(_plansOwnerKey);
    await prefs.remove(_sessionsKey);
  }
}








