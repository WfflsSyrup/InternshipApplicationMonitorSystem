import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/sign_out_button.dart';
import '../../widgets/ui/clean_card.dart';
import '../../widgets/ui/state_widgets.dart' as ui;

class RoleApplicationsScreen extends StatefulWidget {
  const RoleApplicationsScreen({super.key, required this.role});

  final String role;

  @override
  State<RoleApplicationsScreen> createState() => _RoleApplicationsScreenState();
}

class _RoleApplicationsScreenState extends State<RoleApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'student'
        ? 'My applications'
        : 'Partner review';
    final userName = context.watch<AuthProvider>().session?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          SignOutButton(),
          SizedBox(width: UIConstants.spacingSM),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              return ListView(
                padding: const EdgeInsets.all(UIConstants.spacingLG),
                children: [
                  Text(
                    'Welcome, $userName',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: UIConstants.spacingXS),
                  Text(
                    widget.role == 'student'
                        ? 'Your application progress.'
                        : 'Applications assigned to your review.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UIConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingLG),
                  if (provider.applicationsState == DataLoadingState.loading ||
                      provider.applicationsState == DataLoadingState.idle)
                    const ui.LoadingState(message: 'Loading applications...')
                  else if (provider.applicationsState == DataLoadingState.error)
                    ui.TransientErrorState(
                      message: provider.applicationsError,
                      onRetry: provider.fetchApplications,
                    )
                  else if (provider.applications.isEmpty)
                    const ui.EmptyState(
                      icon: Icons.work_outline,
                      title: 'No applications yet',
                      description:
                          'Applications will appear here when available.',
                    )
                  else
                    ...provider.applications.map(
                      (application) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: UIConstants.spacingMD,
                        ),
                        child: CleanCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.companyName?.isNotEmpty == true
                                    ? application.companyName!
                                    : application.applicationNumber,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (application.position?.isNotEmpty == true) ...[
                                const SizedBox(height: UIConstants.spacingXS),
                                Text(
                                  application.position!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: UIConstants.spacingMD),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      application.applicationNumber,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ),
                                  Text(
                                    _stageLabel(application.stage),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _stageLabel(String stage) => switch (stage) {
    'partner_submission' => 'Partner submission',
    'placement_confirmation' => 'Placement confirmation',
    _ => '${stage[0].toUpperCase()}${stage.substring(1)}',
  };
}
