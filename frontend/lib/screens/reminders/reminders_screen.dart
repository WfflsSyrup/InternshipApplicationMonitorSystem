import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ui/clean_card.dart';
import '../../widgets/ui/state_widgets.dart' as ui;

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.background,
      appBar: AppBar(
        title: const Text('Milestone Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().fetchReminders(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.remindersState == DataLoadingState.loading) {
            return const ui.LoadingState(message: 'Loading reminders...');
          }
          if (provider.remindersState == DataLoadingState.error) {
            return ui.TransientErrorState(
              message: provider.remindersError,
              onRetry: () => provider.fetchReminders(),
            );
          }
          if (provider.remindersState == DataLoadingState.businessFailure) {
            return ui.BusinessRuleFailureState(
              title: 'Reminders are unavailable for this account',
              description: provider.remindersError,
              interventionSteps: const [
                'Ask the coordinator to review your account access.',
                'Confirm that the application record is active.',
              ],
            );
          }
          if (provider.remindersState == DataLoadingState.empty ||
              provider.reminders.isEmpty) {
            return const ui.EmptyState(
              icon: Icons.notifications_none,
              title: 'No reminders',
              description: 'All milestones are up to date',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacingLG),
            itemCount: provider.reminders.length,
            itemBuilder: (context, index) {
              final reminder = provider.reminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.spacingMD),
                child: CleanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.studentName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                reminder.priority,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                UIConstants.radiusSM,
                              ),
                            ),
                            child: Text(
                              reminder.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getPriorityColor(reminder.priority),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UIConstants.spacingSM),
                      Text(
                        reminder.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: UIConstants.spacingSM),
                      Text(
                        'Due: ${_formatDate(reminder.dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: UIConstants.spacingMD),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: provider.isUpdatingRecord
                              ? null
                              : () async {
                                  final completed = await provider
                                      .completeMilestone(reminder.id);
                                  if (!completed && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          provider.recordActionIsBusinessFailure
                                              ? 'Coordinator review required: ${provider.recordActionError}'
                                              : provider.recordActionError,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Mark complete'),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return UIConstants.error;
      case 'medium':
        return UIConstants.warning;
      default:
        return UIConstants.success;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
