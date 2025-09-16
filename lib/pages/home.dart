import 'package:civicsnap_android/components/error_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:civicsnap_android/services/login_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  bool isLoading = true;

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
      showErrorSnackbar(
        context,
        "There was an erorr while fetching your user, please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginServices = LoginServices();

    return Scaffold(
      appBar: AppBar(
        title: const Text("CivicSnap"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => loginServices.logout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome 👋",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.displayName ?? "Guest User",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user?.email ?? "",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _homeCard(
                          context,
                          icon: Icons.report_problem,
                          title: "Report Issue",
                          color: Colors.redAccent,
                          onTap: () {
                            // TODO: Navigate to report page
                          },
                        ),
                        _homeCard(
                          context,
                          icon: Icons.map,
                          title: "View Map",
                          color: Colors.blueAccent,
                          onTap: () {
                            // TODO: Navigate to map page
                          },
                        ),
                        _homeCard(
                          context,
                          icon: Icons.history,
                          title: "My Reports",
                          color: Colors.green,
                          onTap: () {
                            // TODO: Navigate to reports list
                          },
                        ),
                        _homeCard(
                          context,
                          icon: Icons.settings,
                          title: "Settings",
                          color: Colors.deepPurple,
                          onTap: () {
                            // TODO: Navigate to settings
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _homeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
