import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/register_page.dart';
import 'screens/nutrition_page.dart' as nutrition;
import 'screens/workout_page.dart' as workout;
import 'screens/progress_page.dart' as progress;
import 'screens/friends_page.dart' as friends;
import 'screens/account_page.dart' as account;
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/app_translations.dart';

const bg = Color(0xFF0B0F0D);
const card = Color(0xFF151B18);
const card2 = Color(0xFF1B231F);
const green = Color(0xFF20C982);
const greenDark = Color(0xFF087A55);
const white = Color(0xFFF5F7F6);
const muted = Color(0xFF89958F);
const line = Color(0xFF28312D);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lqvqomlswivsplzvbpwq.supabase.co',
    publishableKey:
        'sb_publishable_iUdzoW80mYO-PIKAfwjheA_LbU2olxV',
  );

  await LanguageService.load();
  runApp(const FitnessAI());
}

class FitnessAI extends StatelessWidget {
  const FitnessAI({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.locale,
      builder: (context, locale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fitness AI',
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bg,
            fontFamily: 'Arial',
            colorScheme: ColorScheme.fromSeed(
              seedColor: green,
              brightness: Brightness.dark,
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  bool loading = false;
  bool hide = true;

  bool get en => LanguageService.isEnglish;

  Future<void> login() async {
    if (user.text.trim().isEmpty || pass.text.trim().isEmpty) {
      message(en
          ? 'Enter username and password'
          : 'أدخل اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => loading = true);

    final ok = await AuthService.login(
      email: user.text.trim(),
      password: pass.text.trim(),
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (!ok) {
      message(en
          ? 'Incorrect username or password'
          : 'اسم المستخدم أو كلمة المرور غير صحيحة');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: card2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: en ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Align(
                      alignment:
                          en ? Alignment.topRight : Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  LanguageService.setLanguage('ar'),
                              child: Text(
                                'العربية',
                                style: TextStyle(
                                  color: !en ? green : muted,
                                ),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(color: muted),
                            ),
                            TextButton(
                              onPressed: () =>
                                  LanguageService.setLanguage('en'),
                              child: Text(
                                'English',
                                style: TextStyle(
                                  color: en ? green : muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [greenDark, green],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: .18),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fitness AI',
                      style: TextStyle(
                        color: white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      en
                          ? 'Your smart fitness companion'
                          : 'رفيقك الذكي للياقة والتغذية',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 35),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppTranslations.get('login'),
                            style: const TextStyle(
                              color: white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _field(
                            user,
                            en ? 'Username' : 'اسم المستخدم',
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: pass,
                            obscureText: hide,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: card2,
                              labelText: en ? 'Password' : 'كلمة المرور',
                              labelStyle:
                                  const TextStyle(color: muted),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: muted,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => hide = !hide),
                                icon: Icon(
                                  hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: muted,
                                ),
                              ),
                              border: _border(),
                              enabledBorder: _border(),
                              focusedBorder: _border(green),
                            ),
                            onSubmitted: (_) => login(),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      AppTranslations.get('login'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              en
                                  ? 'Create a new account'
                                  : 'إنشاء حساب جديد',
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: card2,
      labelText: label,
      labelStyle: const TextStyle(color: muted),
      prefixIcon: Icon(icon, color: muted),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(green),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: c,
      textDirection: TextDirection.ltr,
      style: const TextStyle(color: white),
      decoration: _decoration(label, icon),
    );
  }

  OutlineInputBorder _border([Color color = line]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  final pages = const [
    HomePage(),
    nutrition.NutritionPage(),
    workout.WorkoutPage(),
    progress.ProgressPage(),
    friends.FriendsPage(),
    account.AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: card,
            height: 74,
            elevation: 0,
            indicatorColor: green.withValues(alpha: .14),
            labelTextStyle:
                WidgetStateProperty.resolveWith((states) {
              final selected =
                  states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? green : muted,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              );
            }),
            iconTheme:
                WidgetStateProperty.resolveWith((states) {
              final selected =
                  states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? green : muted,
                size: 23,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) =>
                setState(() => index = v),
            destinations: [
              _nav(Icons.home_outlined, Icons.home, 'الرئيسية'),
              _nav(Icons.restaurant_outlined, Icons.restaurant, 'التغذية'),
              _nav(Icons.fitness_center_outlined,
                  Icons.fitness_center, 'التمارين'),
              _nav(Icons.bar_chart_outlined, Icons.bar_chart, 'التقدم'),
              _nav(Icons.people_outline, Icons.people, 'الأصدقاء'),
              _nav(Icons.person_outline, Icons.person, 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _nav(
    IconData normal,
    IconData selected,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(normal),
      selectedIcon: Icon(selected),
      label: label,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = 'المستخدم';
  String goal = 'cutting';
  double weight = 0;
  double calories = 2000;
  double protein = 0;
  double carbs = 0;
  double fat = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final n = await AuthService.getName();
    final w = await AuthService.getWeight();
    final h = await AuthService.getHeight();
    final age = await AuthService.getAge();
    final g = await AuthService.getGender();
    final goalValue = await AuthService.getGoal();
    final activity = await AuthService.getActivity();

    final kg = w ?? 0;
    final cm = h ?? 0;
    final years = age ?? 0;

    double bmr = years > 0 && cm > 0 && kg > 0
        ? ((g ?? 'male') == 'female'
            ? 10 * kg + 6.25 * cm - 5 * years - 161
            : 10 * kg + 6.25 * cm - 5 * years + 5)
        : 2000;

    final multiplier = switch (activity) {
      'low' => 1.2,
      'light' => 1.375,
      'high' => 1.725,
      'very_high' => 1.9,
      _ => 1.55,
    };

    var cal = bmr * multiplier;

    if (goalValue == 'cutting') cal -= 400;
    if (goalValue == 'bulking') cal += 300;

    cal = cal.clamp(1200, 5000).toDouble();

    final p = kg * (goalValue == 'bulking'
        ? 1.8
        : goalValue == 'maintain'
            ? 1.6
            : 2.0);

    final f = kg * .8;
    final c = ((cal - p * 4 - f * 9) / 4).clamp(0, 1000);

    if (!mounted) return;

    setState(() {
      name = n?.trim().isNotEmpty == true ? n!.trim() : 'المستخدم';
      weight = kg;
      goal = goalValue ?? 'cutting';
      calories = cal;
      protein = p;
      fat = f;
      carbs = c.toDouble();
    });
  }

  String goalName() {
    switch (goal) {
      case 'bulking':
        return 'تضخيم';
      case 'maintain':
        return 'محافظة';
      default:
        return 'تنشيف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: green,
        backgroundColor: card,
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحبًا 👋',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: green.withValues(alpha: .25),
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [greenDark, green],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'السعرات اليومية',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
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
                        calories.round().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5, left: 5),
                        child: Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 8,
                      backgroundColor:
                          Colors.white.withValues(alpha: .18),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${calories.round()} kcal متبقية اليوم',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _mini(Icons.flag_outlined, 'الهدف', goalName()),
                const SizedBox(width: 10),
                _mini(Icons.bolt_outlined, 'النشاط', 'نشاط متوسط'),
              ],
            ),
            const SizedBox(height: 24),
            const _Title(
              'المغذيات اليومية',
              'احتياجك المحسوب حسب هدفك',
            ),
            const SizedBox(height: 12),
            _card(
              Column(
                children: [
                  _macro('البروتين', protein, Icons.egg_alt_outlined),
                  const SizedBox(height: 18),
                  _macro('الكربوهيدرات', carbs, Icons.grain),
                  const SizedBox(height: 18),
                  _macro('الدهون', fat, Icons.opacity_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _Title('وزنك الحالي', 'تابع تقدمك نحو هدفك'),
            const SizedBox(height: 12),
            _card(
              Row(
                children: [
                  _iconBox(Icons.monitor_weight_outlined),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الوزن الحالي',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pill(goalName()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _Title('نشاط اليوم', 'حافظ على نشاطك اليومي'),
            const SizedBox(height: 12),
            Row(
              children: [
                _activity('الخطوات', '0', '10,000', Icons.directions_walk),
                const SizedBox(width: 10),
                _activity('الماء', '0.00 L', '3 L', Icons.water_drop_outlined),
              ],
            ),
            const SizedBox(height: 24),
            const _Title('إجراءات سريعة', 'سجل نشاطك بسهولة'),
            const SizedBox(height: 12),
            Row(
              children: [
                _action(Icons.restaurant_outlined, 'إضافة وجبة'),
                const SizedBox(width: 10),
                _action(Icons.fitness_center_outlined, 'تسجيل تمرين'),
              ],
            ),
            const SizedBox(height: 12),
            _feature(
              Icons.auto_awesome,
              'التحليل الذكي',
              'تحليل تقدمك وتغذيتك وتمارينك وتقديم توصيات مناسبة لهدفك',
            ),
            const SizedBox(height: 12),
            _feature(
              Icons.camera_alt_outlined,
              'تحليل الوجبة',
              'التقط صورة لوجبتك لتحليل السعرات والمغذيات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }

  Widget _mini(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            _iconBox(icon, size: 40),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: muted, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String title, double value, IconData icon) {
    return Row(
      children: [
        _iconBox(icon, size: 40),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      )),
                  const Spacer(),
                  Text(
                    '${value.round()} g',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0,
                  minHeight: 6,
                  backgroundColor: card2,
                  valueColor:
                      AlwaysStoppedAnimation(green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activity(
      String title, String current, String target, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(icon, size: 38),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              current,
              style: const TextStyle(
                color: white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'من $target',
              style:
                  const TextStyle(color: muted, fontSize: 10),
            ),
            const SizedBox(height: 9),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 5,
                backgroundColor: card2,
                valueColor: AlwaysStoppedAnimation(green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            _iconBox(icon, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: title == 'التحليل الذكي'
              ? green.withValues(alpha: .3)
              : line,
        ),
      ),
      child: Row(
        children: [
          _iconBox(icon, size: 54),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: muted),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: green,
        size: size * .52,
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Title(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

