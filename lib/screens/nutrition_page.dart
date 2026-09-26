import 'package:flutter/material.dart';
import '../services/fitness_storage.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final Color green = const Color(0xFF19A974);
  final Color darkGreen = const Color(0xFF087F5B);
  final Color background = const Color(0xFF0D1110);
  final Color cardColor = const Color(0xFF151B19);

  List<Map<String, dynamic>> meals = [];
  bool loading = true;

  final mealNameController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  @override
  void dispose() {
    mealNameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> loadMeals() async {
    final data = await FitnessStorage.getMeals();

    if (!mounted) return;

    setState(() {
      meals = data;
      loading = false;
    });
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double get totalCalories {
    return meals.fold(
      0,
      (sum, meal) => sum + _number(meal['calories']),
    );
  }

  double get totalProtein {
    return meals.fold(
      0,
      (sum, meal) => sum + _number(meal['protein']),
    );
  }

  double get totalCarbs {
    return meals.fold(
      0,
      (sum, meal) => sum + _number(meal['carbs']),
    );
  }

  double get totalFats {
    return meals.fold(
      0,
      (sum, meal) => sum + _number(meal['fats']),
    );
  }

  // ============================================================
  // قاعدة غذائية مبدئية
  // القيم لكل 100 جم
  // ============================================================

  final Map<String, Map<String, double>> foodDatabase = const {
    'دجاج': {
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fats': 3.6,
    },
    'دجاج مشوي': {
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fats': 3.6,
    },
    'صدر دجاج': {
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fats': 3.6,
    },
    'رز': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fats': 0.3,
    },
    'رز مسلوق': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fats': 0.3,
    },
    'بيض': {
      'calories': 155,
      'protein': 13,
      'carbs': 1.1,
      'fats': 11,
    },
    'لحم': {
      'calories': 250,
      'protein': 26,
      'carbs': 0,
      'fats': 17,
    },
    'تونة': {
      'calories': 116,
      'protein': 26,
      'carbs': 0,
      'fats': 1,
    },
    'بطاطس': {
      'calories': 87,
      'protein': 1.9,
      'carbs': 20,
      'fats': 0.1,
    },
    'شوفان': {
      'calories': 389,
      'protein': 16.9,
      'carbs': 66.3,
      'fats': 6.9,
    },
    'موز': {
      'calories': 89,
      'protein': 1.1,
      'carbs': 22.8,
      'fats': 0.3,
    },
  };

  Map<String, double>? _findFood(String name) {
    final normalized = name.trim().toLowerCase();

    for (final entry in foodDatabase.entries) {
      final key = entry.key.toLowerCase();

      if (normalized == key ||
          normalized.contains(key)) {
        return entry.value;
      }
    }

    return null;
  }

  // ============================================================
  // إضافة الطعام وحساب القيم
  // ============================================================

  Future<void> addMeal() async {
    final name = mealNameController.text.trim();

    final quantity =
        double.tryParse(
              quantityController.text.trim(),
            ) ??
            0;

    if (name.isEmpty || quantity <= 0) {
      _message(
        'أدخل اسم الطعام والكمية بالجرام',
      );
      return;
    }

    final food = _findFood(name);

    if (food == null) {
      _message(
        'هذا الطعام غير موجود في قاعدة البيانات الحالية.\n'
        'جرّب: دجاج مشوي، رز مسلوق، بيض، تونة، بطاطس، شوفان، موز',
      );
      return;
    }

    final factor = quantity / 100;

    final calories =
        food['calories']! * factor;

    final protein =
        food['protein']! * factor;

    final carbs =
        food['carbs']! * factor;

    final fats =
        food['fats']! * factor;

    await FitnessStorage.addMeal(
      name:
          '$name - ${quantity.toStringAsFixed(0)} جم',
      quantity: quantity,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );

    mealNameController.clear();
    quantityController.clear();

    await loadMeals();

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Future<void> deleteMeal(int id) async {
    await FitnessStorage.deleteMeal(id);

    await loadMeals();
  }

  // ============================================================
  // شاشة إضافة الطعام
  // ============================================================

  void showAddMealDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'إضافة طعام',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    controller:
                        mealNameController,
                    label: 'اسم الطعام',
                    hint: 'مثال: دجاج مشوي',
                    icon:
                        Icons.restaurant_rounded,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller:
                        quantityController,
                    label: 'الكمية (جم)',
                    hint: 'مثال: 100',
                    icon: Icons.scale_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          green.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Text(
                      'أنت تدخل الطعام والكمية فقط، '
                      'والتطبيق يحسب السعرات والبروتين والكارب والدهون تلقائيًا.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor:
                      Colors.white,
                ),
                onPressed: addMeal,
                child: const Text(
                  'حساب وإضافة',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintStyle: const TextStyle(
          color: Colors.white24,
        ),
        prefixIcon: Icon(
          icon,
          color: green,
        ),
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          title: const Text(
            'التغذية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButton:
            FloatingActionButton(
          backgroundColor: green,
          onPressed:
              showAddMealDialog,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        body: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: loadMeals,
                color: green,
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    100,
                  ),
                  children: [
                    _calorieCard(),
                    const SizedBox(height: 16),
                    _macroSummary(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'وجبات اليوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${meals.length} عناصر',
                          style: TextStyle(
                            color: green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (meals.isEmpty)
                      _emptyMeals()
                    else
                      ...meals.map(
                        _mealCard,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _calorieCard() {
    const target = 2200.0;

    final progress =
        (totalCalories / target)
            .clamp(0.0, 1.0);

    final remaining =
        (target - totalCalories)
            .clamp(0.0, target);

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            darkGreen,
            green,
          ],
          begin:
              Alignment.topRight,
          end:
              Alignment.bottomLeft,
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons
                      .local_fire_department_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'سعرات اليوم\nالمتابعة اليومية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              Text(
                '${totalCalories.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.20,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                '${totalCalories.toInt()} kcal',
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              Text(
                'المتبقي ${remaining.toInt()} kcal',
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroSummary() {
    return Row(
      children: [
        Expanded(
          child: _macroCard(
            'بروتين',
            totalProtein,
            'g',
            Icons
                .fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            'كارب',
            totalCarbs,
            'g',
            Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroCard(
            'دهون',
            totalFats,
            'g',
            Icons.opacity_rounded,
          ),
        ),
      ],
    );
  }

  Widget _macroCard(
    String title,
    double value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: green,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toInt()}$unit',
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMeals() {
    return Container(
      padding:
          const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .restaurant_menu_rounded,
            color: green,
            size: 48,
          ),
          const SizedBox(height: 14),
          const Text(
            'لا توجد وجبات مسجلة اليوم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف الطعام والكمية وسنحسب لك السعرات والماكروز.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed:
                showAddMealDialog,
            style:
                ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor:
                  Colors.white,
            ),
            icon:
                const Icon(Icons.add),
            label: const Text(
              'إضافة أول طعام',
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(
    Map<String, dynamic> meal,
  ) {
    final id =
        int.tryParse('${meal['id']}') ??
            0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  meal['name']
                          ?.toString() ??
                      'طعام',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_number(meal['calories']).toInt()} kcal',
                  style:
                      TextStyle(
                    color: green,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'بروتين ${_number(meal['protein']).toInt()}g • '
                  'كارب ${_number(meal['carbs']).toInt()}g • '
                  'دهون ${_number(meal['fats']).toInt()}g',
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                deleteMeal(id),
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
              color:
                  Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}