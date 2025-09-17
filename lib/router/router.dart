import 'package:civicsnap_android/pages/auth/auth_wrapper.dart';
import 'package:civicsnap_android/pages/create_report_page.dart';
import 'package:civicsnap_android/pages/my_reports_page.dart';
import 'package:civicsnap_android/pages/report_details_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) => const AuthWrapper(),
      routes: [
        GoRoute(
          path: "report",
          builder: (context, state) => const CreateReportPage(),
        ),
        GoRoute(
          path: "my-reports",
          builder: (context, state) => const MyReportsPage(),
        ),
        GoRoute(
          path: "report/:id",
          builder: (context, state) {
            final reportId = state.pathParameters["id"]!;
            return ReportDetailsPage(reportId: reportId);
          },
        ),
      ],
    ),
  ],
);
