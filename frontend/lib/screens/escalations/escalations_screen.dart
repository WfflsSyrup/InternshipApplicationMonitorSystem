import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ui/clean_card.dart';
import '../../widgets/ui/state_widgets.dart' as ui;

class EscalationsScreen extends StatefulWidget {
  const EscalationsScreen({super.key});

  @override
  State<EscalationsScreen> createState() => _EscalationsScreenState();
}

class _EscalationsScreenState extends State<EscalationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchEscalations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.background,
      appBar: AppBar(
        title: const Text('Stalled Escalations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DashboardProvider>().fetchEscalations(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.escalationsState == DataLoadingState.loading) {
            return const ui.LoadingState(message: 'Loading escalations...');
          }
          if (provider.escalationsState == DataLoadingState.error) {
            return ui.TransientErrorState(
              message: provider.escalationsError,
              onRetry: () => provider.fetchEscalations(),
            );
          }
          if (provider.escalationsState == DataLoadingState.businessFailure) {
            return ui.BusinessRuleFailureState(
              title: 'Escalations need a coordinator review',
              description: provider.escalationsError,
              interventionSteps: const [
                'Ask a coordinator to review the application workflow state.',
                'Correct the recorded data before requesting this list again.',
              ],
            );
          }
          if (provider.escalationsState == DataLoadingState.empty ||
              provider.escalations.isEmpty) {
            return ui.EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No escalations',
              description: 'All applications are progressing well',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacingLG),
            itemCount: provider.escalations.length,
            itemBuilder: (context, index) {
              final escalation = provider.escalations[index];
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
                              escalation.studentName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: UIConstants.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                UIConstants.radiusSM,
                              ),
                            ),
                            child: Text(
                              escalation.escalationLevel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: UIConstants.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UIConstants.spacingSM),
                      Text(
                        escalation.escalationReason,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: UIConstants.spacingSM),
                      Text(
                        '${escalation.daysStalled} days stalled � Assigned: ${escalation.assignedTo}',
                        style: Theme.of(context).textTheme.bodySmall,
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
}
