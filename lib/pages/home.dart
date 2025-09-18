import 'package:civicsnap_android/components/error_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:civicsnap_android/services/login_services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  bool isLoading = true;
  final LoginServices _loginServices = LoginServices();

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

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirmLogout'.tr()),
          content: Text('Are you sure you want to log out?'.tr()),
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
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('homeTitle'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showLogoutConfirmationDialog,
            tooltip: 'logoutButton'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'welcomeMessage'.tr(namedArgs: {"name": user?.displayName ?? ''}),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text('whatToDo'.tr(), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            _buildFeatureCard(
              context,
              title: 'reportTitle'.tr(),
              subtitle: 'reportSubtitle'.tr(),
              icon: Icons.add_circle_outline,
              onTap: () => context.go('/report'),
              iconColor: Theme.of(context).colorScheme.primary,
            ),
            _buildFeatureCard(
              context,
              title: 'myReportsTitle'.tr(),
              subtitle: 'myReportsSubtitle'.tr(),
              icon: Icons.list_alt,
              onTap: () => context.go('/my-reports'),
              iconColor: Theme.of(context).colorScheme.secondary,
            ),
            _buildFeatureCard(
              context,
              title: 'settingsTitle'.tr(),
              subtitle: 'settingsSubtitle'.tr(),
              icon: Icons.settings,
              onTap: () => context.go('/settings'),
              iconColor: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
