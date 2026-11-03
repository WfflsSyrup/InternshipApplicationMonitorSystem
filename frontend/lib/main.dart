import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/minimal_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/applications/role_applications_screen.dart';
import 'screens/dashboard/home_dashboard.dart';
import 'screens/workflow/workflow_overview_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const InternshipMonitorApp());
}

class InternshipMonitorApp extends StatelessWidget {
  const InternshipMonitorApp({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(apiService: apiService),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp(
          key: ValueKey('${auth.session?.id}:${auth.session?.role}'),
          title: 'Internship Application Monitor',
          debugShowCheckedModeBanner: false,
          theme: MinimalTheme.lightTheme,
          home: const _SessionRouter(),
          builder: (context, child) {
            final session = auth.session;
            if (session == null) return child ?? const SizedBox.shrink();

            return ChangeNotifierProvider(
              create: (_) => DashboardProvider(apiService: auth.apiService),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

class _SessionRouter extends StatelessWidget {
  const _SessionRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final session = auth.session;
        if (session == null) return const LoginScreen();

        final Widget destination = switch (session.role) {
          'coordinator' || 'adviser' => HomeDashboard(role: session.role),
          'partner_reviewer' => const WorkflowOverviewScreen(
            role: 'partner_reviewer',
          ),
          'student' => const RoleApplicationsScreen(role: 'student'),
          _ => const LoginScreen(),
        };

        return destination;
      },
    );
  }
}
