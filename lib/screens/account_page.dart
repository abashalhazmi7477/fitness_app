import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/app_translations.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final Color green = const Color(0xFF19A974);
  final Color darkGreen = const Color(0xFF087F5B);
  final Color background = const Color(0xFF0D1110);
  final Color cardColor = const Color(0xFF151B19);

  String name = '';
  String username = '';
  String age = '';
  String height = '';
  String weight = '';
  String gender = '';
  String goal = '';
  String activity = '';

  bool loading = true;

  String t(String key) => AppTranslations.get(key);

  @override
  void initState() {
    super.initState();
    loadAccount();
  }

  Future<void> loadAccount() async {
    final loadedName = await AuthService.getName();
    final loadedUsername = await AuthService.getUsername();
    final loadedAge = await AuthService.getAge();
    final loadedHeight = await AuthService.getHeight();
    final loadedWeight = await AuthService.getWeight();
    final loadedGender = await AuthService.getGender();
    final loadedGoal = await AuthService.getGoal();
    final loadedActivity = await AuthService.getActivity();

    if (!mounted) return;

    setState(() {
      name = loadedName ?? '';
      username = loadedUsername ?? '';
      age = loadedAge?.toString() ?? '';
      height = loadedHeight?.toString() ?? '';
      weight = loadedWeight?.toString() ?? '';
      gender = loadedGender ?? '';
      goal = loadedGoal ?? '';
      activity = loadedActivity ?? '';
      loading = false;
    });
  }

  String genderText() {
    switch (gender) {
      case 'male':
        return t('male');
      case 'female':
        return t('female');
      default:
        return gender.isEmpty ? t('not_specified') : gender;
    }
  }

  String goalText() {
    switch (goal) {
      case 'cutting':
        return t('cutting');
      case 'bulking':
        return t('bulking');
      case 'maintain':
        return t('maintain');
      default:
        return goal.isEmpty ? t('not_specified') : goal;
    }
  }

  String activityText() {
    switch (activity) {
      case 'low':
        return t('low');
      case 'light':
        return t('light');
      case 'moderate':
        return t('moderate');
      case 'high':
        return t('high');
      case 'very_high':
        return t('very_high');
      default:
        return activity.isEmpty ? t('not_specified') : activity;
    }
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              t('logout'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              t('logout_question'),
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  t('cancel'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(t('logout')),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              t('delete_account'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              t('delete_warning'),
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  t('cancel'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(t('delete_account')),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    await AuthService.deleteAccount();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.locale,
      builder: (context, locale, _) {
        return Directionality(
          textDirection: LanguageService.direction,
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              elevation: 0,
              title: Text(
                t('my_account'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: loading
                ? Center(child: CircularProgressIndicator(color: green))
                : RefreshIndicator(
                    onRefresh: loadAccount,
                    color: green,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        _profileHeader(),
                        const SizedBox(height: 18),
                        _sectionTitle(t('personal_information')),
                        const SizedBox(height: 10),
                        _infoCard(),
                        const SizedBox(height: 18),
                        _sectionTitle(t('your_goal_activity')),
                        const SizedBox(height: 10),
                        _goalCard(),
                        const SizedBox(height: 24),
                        _sectionTitle(t('settings')),
                        const SizedBox(height: 10),
                        _languageButton(),
                        const SizedBox(height: 24),
                        _logoutButton(),
                        const SizedBox(height: 12),
                        _deleteButton(),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Abdulelah alhazmi',
                            style: TextStyle(
                              color: Color(0xFF6E7673),
                              fontSize: 10,
                            ),
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

  Widget _profileHeader() {
    final displayName = name.isEmpty ? username : name;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGreen, green],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? t('user') : displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  username.isEmpty ? t('personal_account') : '@$username',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageButton() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          leading: Icon(Icons.language_rounded, color: green),
          title: Text(
            t('language'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            LanguageService.isArabic ? t('arabic') : t('english'),
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_left_rounded, color: Colors.grey),
          onTap: _changeLanguage,
        ),
      ),
    );
  }

  Future<void> _changeLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cardColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  LanguageService.isArabic
                      ? t('choose_language')
                      : t('choose_language_en'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                title: Text(
                  t('arabic'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'ar'),
              ),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(
                  t('english'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'en'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    await LanguageService.setLanguage(selected);
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.cake_outlined,
            title: t('age'),
            value: age.isEmpty ? t('not_specified') : '$age ${t('years')}',
          ),
          _divider(),
          _infoRow(
            icon: Icons.height_rounded,
            title: t('height'),
            value: height.isEmpty ? t('not_specified') : '$height ${t('cm')}',
          ),
          _divider(),
          _infoRow(
            icon: Icons.monitor_weight_outlined,
            title: t('weight'),
            value: weight.isEmpty ? t('not_specified') : '$weight ${t('kg')}',
          ),
          _divider(),
          _infoRow(
            icon: Icons.person_outline_rounded,
            title: t('gender'),
            value: genderText(),
          ),
        ],
      ),
    );
  }

  Widget _goalCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.flag_outlined,
            title: t('goal'),
            value: goalText(),
          ),
          _divider(),
          _infoRow(
            icon: Icons.directions_run_rounded,
            title: t('activity_level'),
            value: activityText(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.05));
  }

  Widget _logoutButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          t('logout'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: deleteAccount,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(
          t('delete_account'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
