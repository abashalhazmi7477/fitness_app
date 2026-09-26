
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/register_page.dart';
import 'screens/nutrition_page.dart' as nutrition_screen;
import 'screens/workout_page.dart' as workout_screen;
import 'screens/progress_page.dart' as progress_screen;
import 'screens/friends_page.dart' as friends_screen;
import 'screens/account_page.dart' as account_screen;
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/app_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lqvqomlswivsplzvbpwq.supabase.co',
    publishableKey: 'sb_publishable_iUdzoW80mYO-PIKAfwjheA_LbU2olxV',
  );
  await LanguageService.load();
  runApp(const FitnessAIApp());
}

// ============================================================
// الألوان
// ============================================================

const Color backgroundColor = Color(0xFF0D0F0E);
const Color cardColor = Color(0xFF171A18);
const Color fieldColor = Color(0xFF1D211F);
const Color borderColor = Color(0xFF292E2B);

const Color primaryColor = Color(0xFF19A974);
const Color primaryDarkColor = Color(0xFF087F5B);

const Color mainTextColor = Color(0xFFF2F4F3);
const Color secondaryTextColor = Color(0xFF9AA39F);

// ============================================================
// التطبيق
// ============================================================

class FitnessAIApp extends StatelessWidget {
  const FitnessAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.locale,
      builder: (context, locale, _) {
        return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      title: 'Fitness AI',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
          labelStyle: const TextStyle(
            color: secondaryTextColor,
          ),
        ),
      ),
      home: const LoginPage(),
        );
      },
    );
  }
}

// ============================================================
// تسجيل الدخول
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('أدخل اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final valid = await AuthService.login(
      email: username,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (!valid) {
      _showMessage('اسم المستخدم أو كلمة المرور غير صحيحة');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainPage(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: cardColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 25),

                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 38,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Fitness AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mainTextColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'لياقتك، تغذيتك، وتحليلك الذكي في مكان واحد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 35),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(AppTranslations.get('login'),
                            style: TextStyle(
                              color: mainTextColor,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller: usernameController,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(labelText: AppTranslations.get('username'),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: AppTranslations.get('password'),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: secondaryTextColor,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => login(),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    primaryDarkColor.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(AppTranslations.get('login'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  'ليس لديك حساب؟',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                child: Text(AppTranslations.get('register'),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// الصفحة الرئيسية للتطبيق
// ============================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  

  final List<Widget> pages = [HomePage(),
    nutrition_screen.NutritionPage(),
    workout_screen.WorkoutPage(),
    progress_screen.ProgressPage(),
    friends_screen.FriendsPage(),
    account_screen.AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: cardColor,
          indicatorColor: primaryColor.withValues(alpha: 0.18),
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });

            if (index == 0) {
              
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: AppTranslations.get('home'),
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: AppTranslations.get('nutrition'),
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: AppTranslations.get('workouts'),
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: AppTranslations.get('progress'),
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: AppTranslations.get('friends'),
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: AppTranslations.get('account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// الرئيسية
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = 'مرحبًا';
  String goal = '';
  String activity = '';

  int age = 0;
  double height = 0;
  double weight = 0;

  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;

  int consumedCalories = 0;
  int steps = 0;
  double water = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loadedName = await AuthService.getName();
    final loadedAge = await AuthService.getAge();
    final loadedHeight = await AuthService.getHeight();
    final loadedWeight = await AuthService.getWeight();
    final loadedGoal = await AuthService.getGoal();
    final loadedActivity = await AuthService.getActivity();
    final loadedGender = await AuthService.getGender();

    final calculatedCalories = _calculateCalories(
      age: loadedAge ?? 0,
      height: loadedHeight ?? 0,
      weight: loadedWeight ?? 0,
      gender: loadedGender ?? 'male',
      activity: loadedActivity ?? 'moderate',
      goal: loadedGoal ?? 'cutting',
    );

    final calculatedProtein =
        (loadedWeight ?? 0) * _proteinMultiplier(loadedGoal ?? 'cutting');

    final calculatedFat = (loadedWeight ?? 0) * 0.8;

    final calculatedCarbs = _calculateCarbs(
      calories: calculatedCalories,
      protein: calculatedProtein,
      fat: calculatedFat,
    );

    if (!mounted) return;

    setState(() {
      name = loadedName?.trim().isNotEmpty == true
          ? loadedName!.trim()
          : 'مرحبًا';

      age = loadedAge ?? 0;
      height = loadedHeight ?? 0;
      weight = loadedWeight ?? 0;

      goal = loadedGoal ?? '';
      activity = loadedActivity ?? '';

      calories = calculatedCalories;
      protein = calculatedProtein;
      fat = calculatedFat;
      carbs = calculatedCarbs;

      isLoading = false;
    });
  }

  double _calculateCalories({
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String activity,
    required String goal,
  }) {
    if (age <= 0 || height <= 0 || weight <= 0) {
      return 2000;
    }

    double bmr;

    if (gender == 'female') {
      bmr = (10 * weight) +
          (6.25 * height) -
          (5 * age) -
          161;
    } else {
      bmr = (10 * weight) +
          (6.25 * height) -
          (5 * age) +
          5;
    }

    double activityMultiplier;

    switch (activity) {
      case 'low':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'high':
        activityMultiplier = 1.725;
        break;
      case 'very_high':
        activityMultiplier = 1.9;
        break;
      case 'moderate':
      default:
        activityMultiplier = 1.55;
        break;
    }

    double maintenanceCalories = bmr * activityMultiplier;

    if (goal == 'cutting') {
      maintenanceCalories -= 400;
    } else if (goal == 'bulking') {
      maintenanceCalories += 300;
    }

    return maintenanceCalories.clamp(1200, 5000).toDouble();
  }

  double _proteinMultiplier(String goal) {
    if (goal == 'bulking') {
      return 1.8;
    }

    if (goal == 'maintain') {
      return 1.6;
    }

    return 2.0;
  }

  double _calculateCarbs({
    required double calories,
    required double protein,
    required double fat,
  }) {
    final proteinCalories = protein * 4;
    final fatCalories = fat * 9;

    final remainingCalories =
        calories - proteinCalories - fatCalories;

    if (remainingCalories <= 0) {
      return 100;
    }

    return remainingCalories / 4;
  }

  String _goalText() {
    switch (goal) {
      case 'cutting':
        return 'تنشيف';
      case 'bulking':
        return 'تضخيم';
      case 'maintain':
        return 'محافظة';
      default:
        return 'غير محدد';
    }
  }

  String _activityText() {
    switch (activity) {
      case 'low':
        return 'نشاط منخفض';
      case 'light':
        return 'نشاط خفيف';
      case 'moderate':
        return 'نشاط متوسط';
      case 'high':
        return 'نشاط مرتفع';
      case 'very_high':
        return 'نشاط مرتفع جدًا';
      default:
        return 'غير محدد';
    }
  }

  void _addWater() {
    if (water >= 3) return;

    setState(() {
      water = (water + 0.25).clamp(0, 3);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إضافة كوب ماء 💧',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: cardColor,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAddMeal() {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'إضافة وجبة',
              style: TextStyle(
                color: mainTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'سيتم ربط هذه الصفحة بقاعدة بيانات الوجبات في الخطوة القادمة.',
              style: TextStyle(
                color: secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسنًا',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWorkout() {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'تسجيل تمرين',
              style: TextStyle(
                color: mainTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'سيتم ربط سجل التمارين والأوزان في الخطوة القادمة.',
              style: TextStyle(
                color: secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسنًا',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSmartAnalysis() {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'التحليل الذكي',
                  style: TextStyle(
                    color: mainTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'عند اكتمال بيانات التغذية والتمارين، سيقوم التطبيق بتحليل تقدمك وتقديم توصيات مخصصة لهدفك.',
              style: TextStyle(
                color: secondaryTextColor,
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسنًا',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    final calorieProgress =
        calories <= 0 ? 0.0 : (consumedCalories / calories).clamp(0.0, 1.0);

    final stepProgress = (steps / 10000).clamp(0.0, 1.0);
    final waterProgress = (water / 3).clamp(0.0, 1.0);

    return SafeArea(
      child: RefreshIndicator(
        color: primaryColor,
        backgroundColor: cardColor,
        onRefresh: _loadUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
          children: [
            // --------------------------------------------------
            // الترحيب
            // --------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحبًا 👋',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // بطاقة السعرات
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    primaryDarkColor,
                    primaryColor,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'السعرات اليوم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$consumedCalories',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5, right: 6),
                        child: Text(
                          'مستهلك',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${calories.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3, right: 5),
                        child: Text(
                          'هدفك',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: calorieProgress,
                      minHeight: 8,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.18),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${(calories - consumedCalories).clamp(0, calories).round()} kcal متبقية اليوم',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // الهدف والنشاط
            // --------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: _DashboardMiniCard(
                    icon: Icons.flag_outlined,
                    title: 'الهدف',
                    value: _goalText(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashboardMiniCard(
                    icon: Icons.bolt_outlined,
                    title: 'النشاط',
                    value: _activityText(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // المغذيات
            // --------------------------------------------------

            const _SectionTitle(
              title: 'المغذيات اليومية',
              subtitle: 'احتياجك المحسوب حسب هدفك',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Column(
                children: [
                  _MacroProgressRow(
                    title: 'البروتين',
                    value: protein,
                    consumed: 0,
                    unit: 'g',
                    icon: Icons.egg_alt_outlined,
                  ),
                  const SizedBox(height: 18),
                  _MacroProgressRow(
                    title: 'الكربوهيدرات',
                    value: carbs,
                    consumed: 0,
                    unit: 'g',
                    icon: Icons.grain,
                  ),
                  const SizedBox(height: 18),
                  _MacroProgressRow(
                    title: 'الدهون',
                    value: fat,
                    consumed: 0,
                    unit: 'g',
                    icon: Icons.opacity_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // الوزن
            // --------------------------------------------------

            const _SectionTitle(
              title: 'الوزن',
              subtitle: 'ملخص وضعك الحالي',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.monitor_weight_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'وزنك الحالي',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: mainTextColor,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _goalText(),
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // نشاط اليوم
            // --------------------------------------------------

            const _SectionTitle(
              title: 'نشاط اليوم',
              subtitle: 'حافظ على نشاطك اليومي',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ActivityProgressCard(
                    icon: Icons.directions_walk,
                    title: 'الخطوات',
                    current: '$steps',
                    target: '10,000',
                    progress: stepProgress,
                    onTap: () {
                      _showComingSoon(
                        context,
                        'تتبع الخطوات',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActivityProgressCard(
                    icon: Icons.water_drop_outlined,
                    title: 'الماء',
                    current: '${water.toStringAsFixed(2)} L',
                    target: '3 L',
                    progress: waterProgress,
                    onTap: _addWater,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // إجراءات سريعة
            // --------------------------------------------------

            const _SectionTitle(
              title: 'إجراءات سريعة',
              subtitle: 'سجل نشاطك بسهولة',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.restaurant_outlined,
                    title: 'إضافة وجبة',
                    onTap: _showAddMeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.fitness_center_outlined,
                    title: 'تسجيل تمرين',
                    onTap: _showWorkout,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // التحليل الذكي
            // --------------------------------------------------

            InkWell(
              onTap: _showSmartAnalysis,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: primaryColor,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التحليل الذكي',
                            style: TextStyle(
                              color: mainTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'تحليل تقدمك وتغذيتك وتمارينك وتقديم توصيات مناسبة لهدفك',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_left,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // تحليل الوجبة
            // --------------------------------------------------

            InkWell(
              onTap: () {
                _showComingSoon(
                  context,
                  'تحليل الوجبة',
                );
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: primaryColor,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحليل الوجبة',
                            style: TextStyle(
                              color: mainTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'التقط صورة لوجبتك لتحليل السعرات والمغذيات',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_left,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'السعرات والمغذيات محسوبة بناءً على بيانات حسابك الحالية.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              title,
              style: const TextStyle(
                color: mainTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'هذه الميزة سيتم ربطها بالبيانات الفعلية في المرحلة القادمة.',
              style: TextStyle(
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسنًا',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// عنوان القسم
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: mainTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// بطاقة صغيرة للهدف والنشاط
// ============================================================

class _DashboardMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mainTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// تقدم المغذيات
// ============================================================

class _MacroProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final double consumed;
  final String unit;
  final IconData icon;

  const _MacroProgressRow({
    required this.title,
    required this.value,
    required this.consumed,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        value <= 0 ? 0.0 : (consumed / value).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: mainTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${consumed.round()} / ${value.round()} $unit',
                    style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: fieldColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// بطاقة النشاط
// ============================================================

class _ActivityProgressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String current;
  final String target;
  final double progress;
  final VoidCallback onTap;

  const _ActivityProgressCard({
    required this.icon,
    required this.title,
    required this.current,
    required this.target,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.add_circle_outline,
                  color: secondaryTextColor,
                  size: 19,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              current,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mainTextColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'من $target',
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: fieldColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// الإجراءات السريعة
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mainTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// التغذية
// ============================================================

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: AppTranslations.get('nutrition'),
      icon: Icons.restaurant,
      subtitle: 'تابع سعراتك ومغذياتك اليومية',
    );
  }
}

// ============================================================
// التمارين
// ============================================================

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: AppTranslations.get('workouts'),
      icon: Icons.fitness_center,
      subtitle: 'خطط تمارينك وسجل أوزانك وتقدمك',
    );
  }
}

// ============================================================
// الأصدقاء
// ============================================================

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimplePage(title: AppTranslations.get('friends'),
      icon: Icons.people,
      subtitle: 'تابع تقدمك مع أصدقائك وتنافس معهم',
    );
  }
}

// ============================================================
// الحساب
// ============================================================

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String name = '';
  String username = '';
  String goal = '';
  double weight = 0;
  double height = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final loadedName = await AuthService.getName();
    final loadedUsername = await AuthService.getUsername();
    final loadedGoal = await AuthService.getGoal();
    final loadedWeight = await AuthService.getWeight();
    final loadedHeight = await AuthService.getHeight();

    if (!mounted) return;

    setState(() {
      name = loadedName ?? '';
      username = loadedUsername ?? '';
      goal = loadedGoal ?? '';
      weight = loadedWeight ?? 0;
      height = loadedHeight ?? 0;
      isLoading = false;
    });
  }

  String _goalText() {
    switch (goal) {
      case 'cutting':
        return 'تنشيف';
      case 'bulking':
        return 'تضخيم';
      case 'maintain':
        return 'محافظة';
      default:
        return 'غير محدد';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'حذف الحساب',
              style: TextStyle(
                color: mainTextColor,
              ),
            ),
            content: const Text(
              'هل أنت متأكد من حذف الحساب؟ لا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(
                color: secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: secondaryTextColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف الحساب',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await AuthService.deleteAccount();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(AppTranslations.get('account'),
            style: TextStyle(
              color: mainTextColor,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 38,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  name.isEmpty ? 'المستخدم' : name,
                  style: const TextStyle(
                    color: mainTextColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  username,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              children: [
                _MacroRow(
                  title: 'الوزن',
                  value: '${weight.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
                const Divider(
                  color: borderColor,
                  height: 24,
                ),
                _MacroRow(
                  title: 'الطول',
                  value: '${height.toStringAsFixed(0)} cm',
                  icon: Icons.height,
                ),
                const Divider(
                  color: borderColor,
                  height: 24,
                ),
                _MacroRow(
                  title: 'الهدف',
                  value: _goalText(),
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(
                Icons.logout,
                color: Colors.orangeAccent,
              ),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: mainTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => _deleteAccount(context),
              child: const Text(
                'حذف الحساب',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Abdulelah alhazmi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF505754),
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================
// صف المغذيات
// ============================================================

class _MacroRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MacroRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: mainTextColor,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: mainTextColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// صفحة بسيطة
// ============================================================

class _SimplePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const _SimplePage({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mainTextColor,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 38,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        title,
                        style: const TextStyle(
                          color: mainTextColor,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'سيتم تطوير هذه الصفحة في المرحلة القادمة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}















