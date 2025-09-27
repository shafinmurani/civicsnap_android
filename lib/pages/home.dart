import 'dart:async';
import 'package:civicsnap_android/components/error_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  User? user;
  bool isLoading = true;
  late StreamSubscription<ServiceStatus> _locationStreamSubscription;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUser();
    _checkLocationServicesAndPermissions();
    _locationStreamSubscription = Geolocator.getServiceStatusStream().listen(
      _onLocationServiceStatusChanged,
    );
  }

  @override
  void dispose() {
    _locationStreamSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationServicesAndPermissions();
    }
  }

  void _onLocationServiceStatusChanged(ServiceStatus status) {
    if (status == ServiceStatus.disabled) {
      if (mounted && !_isShowingDialog) {
        _checkLocationServicesAndPermissions();
      }
    }
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

  Future<void> _checkLocationServicesAndPermissions() async {
    // Check if a dialog is showing and if location is now enabled.
    // If so, dismiss the dialog.
    if (_isShowingDialog) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.of(context).pop();
          _isShowingDialog = false;
          return;
        }
      }
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _isShowingDialog = true;
        await _showLocationDialog(
          'locationServiceDisabledTitle'.tr(),
          'locationServiceDisabledMessage'.tr(),
          () async {
            await Geolocator.openLocationSettings();
          },
        );
        _isShowingDialog = false;
      }
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _isShowingDialog = true;
          await _showLocationDialog(
            'permissionDeniedTitle'.tr(),
            'permissionDeniedMessage'.tr(),
            () async {
              await Geolocator.openAppSettings();
            },
          );
          _isShowingDialog = false;
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _isShowingDialog = true;
        await _showLocationDialog(
          'permissionDeniedTitle'.tr(),
          'permissionDeniedMessage'.tr(),
          () async {
            await Geolocator.openAppSettings();
          },
        );
        _isShowingDialog = false;
      }
      return;
    }
  }

  Future<void> _showLocationDialog(
    String title,
    String content,
    VoidCallback onOpenSettings,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            TextButton(
              onPressed: onOpenSettings,
              child: Text('openSettingsButton'.tr()),
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
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => context.go('/queued-uploads'),
            tooltip: 'queuedUploads'.tr(),
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
