import 'package:flutter/material.dart';

import '../services/fitness_storage.dart';
import '../services/language_service.dart';
import '../services/app_translations.dart';
import '../data/exercise_catalog.dart';

const Color progressGreen = Color(0xFF19A974);
const Color progressDarkGreen = Color(0xFF087F5B);
const Color progressBackground = Color(0xFF0D1110);
const Color progressCard = Color(0xFF151B19);
const Color progressMuted = Color(0xFF8D9995);

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool loading = true;
  bool savingWeight = false;

  int workoutCount = 0;
  int totalDuration = 0;
  double currentWeight = 0;

  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> fiveDaysHistory = [];

  String t(String key) => AppTranslations.get(key);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FitnessStorage.getWorkoutSessionCount(),
        FitnessStorage.getTotalWorkoutDuration(),
        FitnessStorage.getWorkoutSessions(),
        FitnessStorage.getWeight(),
        FitnessStorage.getLastFiveDaysHistory(),
      ]);

      double weight = _toDouble(results[3]);

      try {
        final serverWeight =
            await FitnessStorage.getLatestWeightFromSupabase();

        if (serverWeight != null && serverWeight > 0) {
          weight = serverWeight;
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        workoutCount = results[0] as int;
        totalDuration = results[1] as int;
        sessions = List<Map<String, dynamic>>.from(results[2] as List);
        currentWeight = weight;
        fiveDaysHistory =
            List<Map<String, dynamic>>.from(results[4] as List);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _showWeightDialog() async {
    final controller = TextEditingController(
      text: currentWeight > 0 ? _formatNumber(currentWeight) : '',
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: AlertDialog(
            backgroundColor: progressCard,
            title: Text(
              t('record_new_weight'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: t('weight'),
                hintText: t('example_weight'),
                suffixText: t('kg'),
                labelStyle: const TextStyle(color: progressMuted),
                hintStyle: const TextStyle(color: Colors.white24),
                suffixStyle: const TextStyle(
                  color: progressGreen,
                  fontWeight: FontWeight.w700,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(14),
                  ),
                  borderSide: BorderSide(color: progressGreen),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  t('cancel'),
                  style: const TextStyle(color: progressMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: progressGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final weight = double.tryParse(
                    controller.text.trim().replaceAll(',', '.'),
                  );

                  if (weight == null || weight <= 0 || weight > 500) {
                    return;
                  }

                  Navigator.of(dialogContext).pop(weight);
                },
                child: Text(
                  t('save'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (value == null || value <= 0) return;

    await _saveWeight(value);
  }

  Future<void> _saveWeight(double weight) async {
    if (savingWeight) return;

    setState(() {
      savingWeight = true;
    });

    try {
      await FitnessStorage.saveWeight(weight);

      if (!mounted) return;

      setState(() {
        currentWeight = weight;
        savingWeight = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('weight_saved'),
            textAlign: LanguageService.isArabic
                ? TextAlign.right
                : TextAlign.left,
          ),
          backgroundColor: progressDarkGreen,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        savingWeight = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('weight_save_failed'),
            textAlign: LanguageService.isArabic
                ? TextAlign.right
                : TextAlign.left,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours ${t('hours_short')} $minutes ${t('minutes_short')}';
    }

    return '$minutes ${t('minutes_short')}';
  }

  String _formatSessionDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return t('unknown_date');
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  int _completedSetsInSession(Map<String, dynamic> session) {
    var count = 0;
    final exercises = session['exercises'];

    if (exercises is! List) return 0;

    for (final rawExercise in exercises) {
      if (rawExercise is! Map) continue;

      final sets = rawExercise['sets'];

      if (sets is! List) continue;

      for (final rawSet in sets) {
        if (rawSet is Map && rawSet['completed'] == true) {
          count++;
        }
      }
    }

    return count;
  }

  int _totalSetsInSession(Map<String, dynamic> session) {
    var count = 0;
    final exercises = session['exercises'];

    if (exercises is! List) return 0;

    for (final rawExercise in exercises) {
      if (rawExercise is! Map) continue;

      final sets = rawExercise['sets'];

      if (sets is List) {
        count += sets.length;
      }
    }

    return count;
  }

  Map<String, dynamic>? _findBestExercise() {
    final bestByExercise = <String, Map<String, dynamic>>{};

    for (final session in sessions) {
      final exercises = session['exercises'];

      if (exercises is! List) continue;

      for (final rawExercise in exercises) {
        if (rawExercise is! Map) continue;

        final exerciseName =
            rawExercise['exercise']?.toString().trim() ?? '';

        if (exerciseName.isEmpty) continue;

        final sets = rawExercise['sets'];

        if (sets is! List) continue;

        for (final rawSet in sets) {
          if (rawSet is! Map) continue;
          if (rawSet['completed'] != true) continue;

          final weight = _toDouble(rawSet['weight']);
          final reps = _toInt(rawSet['reps']);
          final current = bestByExercise[exerciseName];

          if (current == null ||
              weight > _toDouble(current['weight']) ||
              (weight == _toDouble(current['weight']) &&
                  reps > _toInt(current['reps']))) {
            bestByExercise[exerciseName] = {
              'exercise': exerciseName,
              'weight': weight,
              'reps': reps,
              'date': session['startedAt'],
            };
          }
        }
      }
    }

    if (bestByExercise.isEmpty) return null;

    final values = bestByExercise.values.toList();

    values.sort(
      (a, b) => _toDouble(b['weight']).compareTo(
        _toDouble(a['weight']),
      ),
    );

    return values.first;
  }

  List<Map<String, dynamic>> _recentSessions() {
    final result = List<Map<String, dynamic>>.from(sessions);

    result.sort((a, b) {
      final aDate = DateTime.tryParse(
            a['startedAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = DateTime.tryParse(
            b['startedAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return result.take(5).toList();
  }

  ExerciseCatalogMatch? _exerciseCatalogMatch(String exerciseName) {
    final target = exerciseName.trim().toLowerCase();

    for (final item in exerciseCatalogData) {
      final arabic =
          item['name']?.toString().trim().toLowerCase();

      final english =
          item['englishName']?.toString().trim().toLowerCase();

      if (arabic == target || english == target) {
        return ExerciseCatalogMatch(
          name: item['name']?.toString() ?? exerciseName,
          englishName: item['englishName']?.toString() ?? '',
          muscle: item['muscle']?.toString() ?? '',
        );
      }
    }

    return null;
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: progressCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: progressGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: progressGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: progressMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightCard() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: progressCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: progressGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: savingWeight ? null : _showWeightDialog,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: progressGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_outlined,
                    color: progressGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('current_weight_title'),
                        style: const TextStyle(
                          color: progressMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentWeight > 0
                            ? '${_formatNumber(currentWeight)} ${t('kg')}'
                            : '-- ${t('kg')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentWeight > 0
                            ? t('edit_weight')
                            : t('record_weight'),
                        style: const TextStyle(
                          color: progressGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                savingWeight
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: progressGreen,
                        ),
                      )
                    : Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: progressGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: progressGreen,
                          size: 21,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [progressDarkGreen, progressGreen],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('your_progress'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  workoutCount == 0
                      ? t('start_first_workout')
                      : t('keep_going'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestPerformanceCard() {
    final best = _findBestExercise();

    if (best == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: progressCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white30,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('best_performance'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('complete_first_session'),
                    style: const TextStyle(
                      color: progressMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final exercise = best['exercise']?.toString() ?? '';
    final weight = _toDouble(best['weight']);
    final reps = _toInt(best['reps']);
    final match = _exerciseCatalogMatch(exercise);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: progressCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: progressGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: progressGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: progressGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('best_performance_recorded'),
                  style: const TextStyle(
                    color: progressMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  LanguageService.isEnglish
                      ? match?.englishName ?? exercise
                      : match?.name ?? exercise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatNumber(weight)} ${t('kg')} • $reps ${t('repetitions')}',
                  style: const TextStyle(
                    color: progressGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session) {
    final planName = session['planName']?.toString() ?? t('workouts');
    final duration = _toInt(session['durationSeconds']);
    final setsCompleted = _completedSetsInSession(session);
    final totalSets = _totalSetsInSession(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: progressCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: progressGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: progressGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatSessionDate(session['startedAt'])} • '
                  '${_formatDuration(duration)}',
                  style: const TextStyle(
                    color: progressMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$setsCompleted / $totalSets',
                style: const TextStyle(
                  color: progressGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('sets'),
                style: const TextStyle(
                  color: progressMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.locale,
      builder: (context, locale, _) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: Scaffold(
            backgroundColor: progressBackground,
            appBar: AppBar(
              backgroundColor: progressBackground,
              elevation: 0,
              title: Text(
                t('progress_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white70,
                  ),
                  tooltip: t('refresh'),
                ),
              ],
            ),
            body: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: progressGreen,
                    ),
                  )
                : RefreshIndicator(
                    color: progressGreen,
                    backgroundColor: progressCard,
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        _progressHeader(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _weightCard(),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.fitness_center,
                                      title: t('workouts_count'),
                                      value: '$workoutCount',
                                      subtitle: t('completed_sessions'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.timer_outlined,
                                      title: t('training_time'),
                                      value: _formatDuration(totalDuration),
                                      subtitle: t('total_time'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.repeat,
                                      title: t('sets'),
                                      value: '${sessions.fold<int>(
                                        0,
                                        (total, session) =>
                                            total +
                                            _completedSetsInSession(session),
                                      )}',
                                      subtitle: t('completed_sets'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.calendar_month_outlined,
                                      title: t('last_activity'),
                                      value: sessions.isEmpty
                                          ? '--'
                                          : _formatSessionDate(
                                              sessions.first['startedAt'],
                                            ),
                                      subtitle: t('last_workout'),
                                    ),
                                  ),
                                ],
                              ),
                              _bestPerformanceCard(),
                              const SizedBox(height: 18),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: progressCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('last_five_days'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...fiveDaysHistory.map((day) {
                                      final date = DateTime.tryParse(
                                        day['date']?.toString() ?? '',
                                      );

                                      final dateText = date == null
                                          ? '--'
                                          : '${date.day}/${date.month}';

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.03,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 42,
                                              child: Text(
                                                dateText,
                                                style: const TextStyle(
                                                  color: progressMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${_toInt(day['steps'])} ${t('steps_count')}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${_formatNumber(_toDouble(day['calories']))} ${t('calories')}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: progressGreen,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${_formatNumber(_toDouble(day['water']))} L',
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t('recent_workouts'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${sessions.length} ${t('session')}',
                                    style: const TextStyle(
                                      color: progressMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (sessions.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 55,
                                  ),
                                  decoration: BoxDecoration(
                                    color: progressCard,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.insights_outlined,
                                        color: Colors.white24,
                                        size: 55,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        t('no_workout_sessions'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        t('start_first_workout_here'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: progressMuted,
                                          fontSize: 11,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._recentSessions().map(_sessionCard),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class ExerciseCatalogMatch {
  final String name;
  final String englishName;
  final String muscle;

  const ExerciseCatalogMatch({
    required this.name,
    required this.englishName,
    required this.muscle,
  });
}