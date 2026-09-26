import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String t(String ar, String en) => LanguageService.isEnglish ? en : ar;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  int age = 26;
  double height = 172;
  double weight = 85;

  String gender = 'male';
  String goal = 'cutting';
  String activity = 'moderate';

  bool obscurePassword = true;
  bool isCreatingAccount = false;

  static const backgroundColor = Color(0xFF0D0F0E);
  static const cardColor = Color(0xFF171A18);
  static const fieldColor = Color(0xFF1D211F);
  static const borderColor = Color(0xFF292E2B);
  static const primaryColor = Color(0xFF19A974);
  static const primaryDark = Color(0xFF087F5B);
  static const textColor = Color(0xFFF2F4F3);
  static const secondaryText = Color(0xFF9AA39F);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isCreatingAccount = true;
    });

    final calories = calculateCalories();
    final macros = calculateMacros(calories);

    final registered = await AuthService.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      goal: goal,
      activity: activity,
      dailyCalories: calories,
      proteinTarget: macros['protein']!.toDouble(),
      carbsTarget: macros['carbs']!.toDouble(),
      fatTarget: macros['fat']!.toDouble(),
    );

    if (!mounted) return;

    setState(() {
      isCreatingAccount = false;
    });

    if (!registered) {
      _showMessage(
        AuthService.lastRegisterError ?? t('تعذر إنشاء الحساب','Unable to create account'),
        isError: true,
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: AlertDialog(
            backgroundColor: cardColor,
            surfaceTintColor: Colors.transparent,
            title: Text(t('تم تجهيز حسابك 🎉','Your account is ready 🎉'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعرات اليومية: $calories سعرة',
                  style: const TextStyle(color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'البروتين: ${macros['protein']} g',
                  style: const TextStyle(color: textColor),
                ),
                Text(
                  'الكربوهيدرات: ${macros['carbs']} g',
                  style: const TextStyle(color: textColor),
                ),
                Text(
                  'الدهون: ${macros['fat']} g',
                  style: const TextStyle(color: textColor),
                ),
                const SizedBox(height: 15),
                Text(t('هذه الأرقام تقديرية، ويمكن تحسينها لاحقًا حسب تقدمك ونشاطك.','These numbers are estimates and can be improved later based on your progress and activity.'),
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(t('متابعة','Continue'),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFB42318) : primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int calculateCalories() {
    double bmr;

    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
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
      default:
        activityMultiplier = 1.55;
    }

    double calories = bmr * activityMultiplier;

    if (goal == 'cutting') {
      calories -= 400;
    } else if (goal == 'bulking') {
      calories += 300;
    }

    return calories.round();
  }

  Map<String, int> calculateMacros(int calories) {
    double proteinPerKg;

    if (goal == 'cutting') {
      proteinPerKg = 2.0;
    } else if (goal == 'bulking') {
      proteinPerKg = 1.8;
    } else {
      proteinPerKg = 1.6;
    }

    final protein = (weight * proteinPerKg).round();

    final fat = ((calories * 0.25) / 9).round();

    final remainingCalories =
        calories - (protein * 4) - (fat * 9);

    final carbs = (remainingCalories / 4).round();

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LanguageService.direction,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: textColor,
          ),
          title: Text(t('إنشاء حساب','Create Account'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFF153D2D),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      size: 38,
                      color: primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Center(child: Text(t('خلنا نتعرف عليك','Let''s get to know you'),
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Center(child: Text(t('أدخل بياناتك حتى نقدر نجهز خطتك بشكل مناسب','Enter your details so we can prepare a suitable plan'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                _sectionTitle(t('بيانات الحساب','Account Information')),

                const SizedBox(height: 12),

                _textField(
                  controller: nameController,
                  label: t('الاسم','Name'),
                  hint: t('مثال: عبدالله','Example: Abdullah'),
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 13),

                _textField(
                  controller: emailController,
                  label: t('البريد الإلكتروني','Email'),
                  hint: t('مثال: abdullah123','Example: abdullah123'),
                  icon: Icons.alternate_email,
                ),

                const SizedBox(height: 13),

                _textField(
                  controller: passwordController,
                  label: t('كلمة المرور','Password'),
                  hint: t('6 أحرف على الأقل','At least 6 characters'),
                  icon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: secondaryText,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                _sectionTitle(t('بيانات الجسم','Body Information')),

                const SizedBox(height: 12),

                _numberCard(
                  title: t('العمر','Age'),
                  value: '$age سنة',
                  icon: Icons.cake_outlined,
                  onMinus: () {
                    if (age > 14) {
                      setState(() {
                        age--;
                      });
                    }
                  },
                  onPlus: () {
                    if (age < 80) {
                      setState(() {
                        age++;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                _numberCard(
                  title: t('الطول','Height'),
                  value: '${height.round()} سم',
                  icon: Icons.height,
                  onMinus: () {
                    if (height > 130) {
                      setState(() {
                        height--;
                      });
                    }
                  },
                  onPlus: () {
                    if (height < 220) {
                      setState(() {
                        height++;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                _numberCard(
                  title: t('الوزن','Weight'),
                  value: '${weight.round()} كجم',
                  icon: Icons.monitor_weight_outlined,
                  onMinus: () {
                    if (weight > 40) {
                      setState(() {
                        weight--;
                      });
                    }
                  },
                  onPlus: () {
                    if (weight < 200) {
                      setState(() {
                        weight++;
                      });
                    }
                  },
                ),

                const SizedBox(height: 25),

                _sectionTitle(t('الجنس','Gender')),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _choiceCard(
                        title: t('ذكر','Male'),
                        icon: Icons.male,
                        selected: gender == 'male',
                        onTap: () {
                          setState(() {
                            gender = 'male';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _choiceCard(
                        title: t('أنثى','Female'),
                        icon: Icons.female,
                        selected: gender == 'female',
                        onTap: () {
                          setState(() {
                            gender = 'female';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                _sectionTitle(t('هدفك','Your Goal')),

                const SizedBox(height: 12),

                _choiceCard(
                  title: t('تنشيف','Cutting'),
                  subtitle:
                      t('خسارة الدهون والمحافظة على الكتلة العضلية','Lose fat while preserving muscle mass'),
                  icon: Icons.trending_down,
                  selected: goal == 'cutting',
                  onTap: () {
                    setState(() {
                      goal = 'cutting';
                    });
                  },
                ),

                const SizedBox(height: 10),

                _choiceCard(
                  title: t('تضخيم','Bulking'),
                  subtitle:
                      t('زيادة الكتلة العضلية بشكل تدريجي','Gradually increase muscle mass'),
                  icon: Icons.trending_up,
                  selected: goal == 'bulking',
                  onTap: () {
                    setState(() {
                      goal = 'bulking';
                    });
                  },
                ),

                const SizedBox(height: 10),

                _choiceCard(
                  title: t('تثبيت','Maintain'),
                  subtitle:
                      t('المحافظة على وزنك الحالي','Maintain your current weight'),
                  icon: Icons.balance,
                  selected: goal == 'maintain',
                  onTap: () {
                    setState(() {
                      goal = 'maintain';
                    });
                  },
                ),

                const SizedBox(height: 25),

                _sectionTitle(t('مستوى نشاطك','Activity Level')),

                const SizedBox(height: 12),

                _activitySelector(),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        isCreatingAccount ? null : createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor:
                          const Color(0xFF315A4A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                    ),
                    child: isCreatingAccount
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(t('إنشاء حساب والبدء','Create Account & Start'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(child: Text(t('يمكنك تعديل بياناتك لاحقًا من صفحة الحساب','You can edit your information later from the Account page'),
                    style: TextStyle(
                      color: Color(0xFF707875),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: textColor,
      ),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: secondaryText,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF626B67),
        ),
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFB42318),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFB42318),
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return t('هذا الحقل مطلوب','This field is required');
        }

        if (controller == passwordController &&
            value.trim().length < 6) {
          return t('كلمة المرور يجب أن تكون 6 أحرف على الأقل','Password must be at least 6 characters');
        }

        return null;
      },
    );
  }

  Widget _numberCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
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
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF153D2D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          _smallButton(
            icon: Icons.remove,
            onTap: onMinus,
          ),
          const SizedBox(width: 7),
          _smallButton(
            icon: Icons.add,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E332B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF153D2D)
                : cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primaryColor
                  : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1D211F)
                      : fieldColor,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activitySelector() {
    final activities = [
      {
        'key': 'low',
        'title': t('منخفض','Low'),
      },
      {
        'key': 'light',
        'title': t('خفيف','Light'),
      },
      {
        'key': 'moderate',
        'title': t('متوسط','Moderate'),
      },
      {
        'key': 'high',
        'title': t('مرتفع','High'),
      },
      {
        'key': 'very_high',
        'title': t('عالي جدًا','Very High'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: activities.map((item) {
          final selected =
              activity == item['key'];

          return GestureDetector(
            onTap: () {
              setState(() {
                activity = item['key']!;
              });
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),
              margin:
                  const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF153D2D)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 21,
                    color: selected
                        ? primaryColor
                        : const Color(0xFF5E6863),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item['title']!,
                    style: TextStyle(
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}






