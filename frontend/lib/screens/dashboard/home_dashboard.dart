import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ui/clean_card.dart';
import '../alerts/incomplete_records_screen.dart';
import '../escalations/escalations_screen.dart';
import '../reminders/reminders_screen.dart';
import '../summaries/weekly_summary_screen.dart';
import '../workflow/workflow_overview_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().fetchAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.background,
      appBar: AppBar(
        title: const Text('Internship Monitor'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().fetchAllData(),
          ),
          const SizedBox(width: UIConstants.spacingSM),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          final hasNetworkError = [
            provider.remindersState,
            provider.incompleteRecordsState,
            provider.escalationsState,
            provider.weeklySummariesState,
            provider.applicationsState,
          ].contains(DataLoadingState.error);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placement operations',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingSM),
                    Text(
                      'Keep every application moving from submission through placement.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: UIConstants.textSecondary,
                      ),
                    ),
                    if (hasNetworkError) ...[
                      const SizedBox(height: UIConstants.spacingLG),
                      _ConnectionNotice(onRetry: provider.fetchAllData),
                    ],
                    const SizedBox(height: UIConstants.spacingXL),
                    Text(
                      'This week at a glance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: UIConstants.spacingMD),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                        final spacing = UIConstants.spacingMD;
                        final width =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _MetricCard(
                              width: width,
                              label: 'Milestones due',
                              value: _count(
                                provider.remindersState,
                                provider.reminders.length,
                              ),
                              icon: Icons.notifications_none,
                              color: UIConstants.primary,
                            ),
                            _MetricCard(
                              width: width,
                              label: 'Incomplete records',
                              value: _count(
                                provider.incompleteRecordsState,
                                provider.incompleteRecords.length,
                              ),
                              icon: Icons.assignment_late_outlined,
                              color: UIConstants.warning,
                            ),
                            _MetricCard(
                              width: width,
                              label: 'Open escalations',
                              value: _count(
                                provider.escalationsState,
                                provider.escalations.length,
                              ),
                              icon: Icons.support_agent,
                              color: UIConstants.error,
                            ),
                            _MetricCard(
                              width: width,
                              label: 'Placements confirmed',
                              value: _summaryCount(provider),
                              icon: Icons.task_alt,
                              color: UIConstants.success,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: UIConstants.spacingXL),
                    Text(
                      'Workflow and automation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: UIConstants.spacingMD),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 600
                            ? 2
                            : 1;
                        final spacing = UIConstants.spacingMD;
                        final width =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _NavigationCard(
                              width: width,
                              title: 'Application workflow',
                              description:
                                  'Review the six stages and who is responsible.',
                              icon: Icons.account_tree_outlined,
                              onTap: () => _open(
                                context,
                                const WorkflowOverviewScreen(),
                              ),
                            ),
                            _NavigationCard(
                              width: width,
                              title: 'Milestone reminders',
                              description:
                                  'Upcoming and overdue application deadlines.',
                              icon: Icons.notifications_active_outlined,
                              onTap: () =>
                                  _open(context, const RemindersScreen()),
                            ),
                            _NavigationCard(
                              width: width,
                              title: 'Incomplete records',
                              description:
                                  'Documents and requirements that need attention.',
                              icon: Icons.fact_check_outlined,
                              onTap: () => _open(
                                context,
                                const IncompleteRecordsScreen(),
                              ),
                            ),
                            _NavigationCard(
                              width: width,
                              title: 'Stalled applications',
                              description:
                                  'Cases escalated for coordinator follow-up.',
                              icon: Icons.flag_outlined,
                              onTap: () =>
                                  _open(context, const EscalationsScreen()),
                            ),
                            _NavigationCard(
                              width: width,
                              title: 'Weekly placement summary',
                              description:
                                  'Submission, interview, offer, and placement trends.',
                              icon: Icons.bar_chart,
                              onTap: () =>
                                  _open(context, const WeeklySummaryScreen()),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _count(DataLoadingState state, int count) {
    if (state == DataLoadingState.loading || state == DataLoadingState.idle) {
      return 'Loading';
    }
    if (state == DataLoadingState.error ||
        state == DataLoadingState.businessFailure) {
      return 'Unavailable';
    }
    return count.toString();
  }

  String _summaryCount(DashboardProvider provider) {
    if (provider.weeklySummariesState == DataLoadingState.loading ||
        provider.weeklySummariesState == DataLoadingState.idle) {
      return 'Loading';
    }
    if (provider.weeklySummariesState == DataLoadingState.error ||
        provider.weeklySummariesState == DataLoadingState.businessFailure) {
      return 'Unavailable';
    }
    if (provider.weeklySummaries.isEmpty) {
      return '—';
    }
    return provider.weeklySummaries.first.placementsConfirmed.toString();
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: CleanCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingMD),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusMD),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: UIConstants.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: UIConstants.spacingXS),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.width,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: CleanCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingMD),
              decoration: BoxDecoration(
                color: UIConstants.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(UIConstants.radiusMD),
              ),
              child: Icon(icon, color: UIConstants.primary),
            ),
            const SizedBox(width: UIConstants.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: UIConstants.spacingXS),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: UIConstants.spacingSM),
            const Icon(Icons.chevron_right, color: UIConstants.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingMD),
      decoration: BoxDecoration(
        color: UIConstants.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
        border: Border.all(color: UIConstants.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: UIConstants.warning),
          const SizedBox(width: UIConstants.spacingMD),
          Expanded(
            child: Text(
              'Some dashboard data could not be loaded. Your saved records are unchanged.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
