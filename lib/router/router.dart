import 'package:civicsnap_android/pages/auth/auth_wrapper.dart';
import 'package:civicsnap_android/pages/create_report_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) {
        return AuthWrapper();
      },
      routes: [
        GoRoute(
          path: "report",
          builder: (context, state) {
            return CreateReportPage();
          },
        ),
      ],
    ),
  ],
);
