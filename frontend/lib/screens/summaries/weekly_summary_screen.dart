import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ui/clean_card.dart';
import '../../widgets/ui/state_widgets.dart' as ui;

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchWeeklySummaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.background,
      appBar: AppBar(
        title: const Text('Weekly Placement Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DashboardProvider>().fetchWeeklySummaries(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.weeklySummariesState == DataLoadingState.loading) {
            return const ui.LoadingState(message: 'Loading summaries...');
          }
          if (provider.weeklySummariesState == DataLoadingState.error) {
            return ui.TransientErrorState(
              message: provider.weeklySummariesError,
              onRetry: () => provider.fetchWeeklySummaries(),
            );
          }
          if (provider.weeklySummariesState ==
              DataLoadingState.businessFailure) {
            return ui.BusinessRuleFailureState(
              title: 'Summary access requires coordinator review',
              description: provider.weeklySummariesError,
              interventionSteps: const [
                'Ask the coordinator to review access to placement reports.',
                'Refresh this view after the issue is resolved.',
              ],
            );
          }
          if (provider.weeklySummariesState == DataLoadingState.empty ||
              provider.weeklySummaries.isEmpty) {
            return const ui.EmptyState(
              icon: Icons.bar_chart,
              title: 'No summaries available',
              description: 'Weekly data will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacingLG),
            itemCount: provider.weeklySummaries.length,
            itemBuilder: (context, index) {
              final summary = provider.weeklySummaries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.spacingMD),
                child: CleanCard(
                  title: summary.weekLabel,
                  subtitle:
                      '${_formatDate(summary.weekStart)} - ${_formatDate(summary.weekEnd)}',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              'Total',
                              summary.totalApplications.toString(),
                            ),
                          ),
                          Expanded(
                            child: _buildMetric(
                              'Interviews',
                              summary.interviewsScheduled.toString(),
                            ),
                          ),
                          Expanded(
                            child: _buildMetric(
                              'Offers',
                              summary.offersReceived.toString(),
                            ),
                          ),
                          Expanded(
                            child: _buildMetric(
                              'Placed',
                              summary.placementsConfirmed.toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UIConstants.spacingMD),
                      Container(
                        padding: const EdgeInsets.all(UIConstants.spacingMD),
                        decoration: BoxDecoration(
                          color: UIConstants.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            UIConstants.radiusMD,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: UIConstants.success,
                            ),
                            const SizedBox(width: UIConstants.spacingSM),
                            Text(
                              'Placement Rate: ${summary.placementRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: UIConstants.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: UIConstants.textPrimary,
          ),
        ),
        const SizedBox(height: UIConstants.spacingXS),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: UIConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
