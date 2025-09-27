// lib/pages/settings_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:civicsnap_android/components/error_snackbar.dart';
import 'package:civicsnap_android/services/login_services.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? user;
  bool isLoading = true;
  final LoginServices _loginServices = LoginServices();

  final List<Locale> supportedLocales = const [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('gu'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
    Locale('pa'),
    Locale('bn'),
  ];

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      setState(() {
        user = currentUser;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar(context, 'errorFetchingUser'.tr());
    }
  }

  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'mr':
        return 'मराठी';
      case 'gu':
        return 'ગુજરાતી';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'bn':
        return "বাংলা";
      default:
        return locale.languageCode;
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirmLogout'.tr()),
          content: Text('logoutConfirmation'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('logoutButton'.tr()),
              onPressed: () async {
                Navigator.of(context).pop();
                await _loginServices.logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settingsTitle'.tr()), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profileTitle'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.person,
                    label: 'userNameLabel'.tr(),
                    value: user?.displayName ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    icon: Icons.email,
                    label: 'userEmailLabel'.tr(),
                    value: user?.email ?? 'N/A',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'languageTitle'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'changeLanguage'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Locale>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    initialValue: context.locale,
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        _changeLanguage(newLocale);
                      }
                    },
                    items: supportedLocales.map<DropdownMenuItem<Locale>>((
                      Locale locale,
                    ) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(_getLanguageName(locale)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'accountTitle'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.exit_to_app,
                        color: Colors.red[600],
                      ),
                      title: Text(
                        'logoutButton'.tr(),
                        style: TextStyle(color: Colors.red[600]),
                      ),
                      subtitle: Text('logoutDescription'.tr()),
                      onTap: _showLogoutConfirmationDialog,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
