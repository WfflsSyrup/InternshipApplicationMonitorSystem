import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../models/application_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ui/clean_card.dart';
import '../../widgets/ui/state_widgets.dart' as ui;
import '../../widgets/ui/workflow_step_indicator.dart';

class WorkflowOverviewScreen extends StatefulWidget {
  const WorkflowOverviewScreen({super.key});

  @override
  State<WorkflowOverviewScreen> createState() => _WorkflowOverviewScreenState();
}

class _WorkflowOverviewScreenState extends State<WorkflowOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().fetchApplications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      const WorkflowStep(title: 'Application', subtitle: 'Student submission'),
      const WorkflowStep(
        title: 'Verification',
        subtitle: 'Requirements review',
      ),
      const WorkflowStep(title: 'Endorsement', subtitle: 'Adviser approval'),
      const WorkflowStep(title: 'Partner', subtitle: 'Partner submission'),
      const WorkflowStep(title: 'Interview', subtitle: 'Partner decision'),
      const WorkflowStep(title: 'Placement', subtitle: 'Final confirmation'),
    ];

    return Scaffold(
      backgroundColor: UIConstants.background,
      appBar: AppBar(
        title: const Text('Application workflow'),
        actions: [
          IconButton(
            tooltip: 'Refresh applications',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DashboardProvider>().fetchApplications(),
          ),
          const SizedBox(width: UIConstants.spacingSM),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.workflowUpdateError.isNotEmpty &&
              provider.workflowUpdateIsBusinessFailure) {
            return ui.BusinessRuleFailureState(
              title: 'This application cannot move forward',
              description: provider.workflowUpdateError,
              interventionSteps: const [
                'Ask the coordinator to review outstanding requirements.',
                'Confirm that the application is at the expected workflow stage.',
                'Retry the transition after the record is corrected.',
              ],
            );
          }
          if (provider.workflowUpdateError.isNotEmpty) {
            return ui.TransientErrorState(
              message: provider.workflowUpdateError,
              onRetry: () => provider.fetchApplications(),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.spacingLG),
                children: [
                  Text(
                    'From application to placement',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: UIConstants.spacingSM),
                  Text(
                    'Each stage has a clear owner, and progression is checked against the application record.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UIConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingLG),
                  CleanCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 850,
                        child: WorkflowStepIndicator(
                          steps: steps,
                          currentStep: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Applications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '${provider.applications.length} records',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: UIConstants.spacingMD),
                  if (provider.applicationsState == DataLoadingState.loading)
                    const SizedBox(
                      height: 220,
                      child: ui.LoadingState(
                        message: 'Loading applications...',
                      ),
                    )
                  else if (provider.applicationsState == DataLoadingState.error)
                    SizedBox(
                      height: 280,
                      child: ui.TransientErrorState(
                        message: provider.applicationsError,
                        onRetry: () => provider.fetchApplications(),
                      ),
                    )
                  else if (provider.applicationsState ==
                      DataLoadingState.businessFailure)
                    SizedBox(
                      height: 340,
                      child: ui.BusinessRuleFailureState(
                        title: 'Application access requires review',
                        description: provider.applicationsError,
                        interventionSteps: const [
                          'Ask a coordinator to confirm your access.',
                          'Refresh this page after the account issue is resolved.',
                        ],
                      ),
                    )
                  else if (provider.applicationsState == DataLoadingState.empty)
                    const SizedBox(
                      height: 220,
                      child: ui.EmptyState(
                        icon: Icons.work_outline,
                        title: 'No applications yet',
                        description:
                            'Applications will appear here as students submit their records.',
                      ),
                    )
                  else
                    ...provider.applications.map(
                      (application) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: UIConstants.spacingMD,
                        ),
                        child: _ApplicationCard(
                          application: application,
                          isUpdating: provider.isUpdatingWorkflow,
                          onAdvance: (stage) => provider.updateWorkflow(
                            application.id,
                            stage: stage,
                          ),
                          onInterviewStatusChanged: (status) =>
                              provider.updateWorkflow(
                                application.id,
                                stage: 'interview',
                                interviewStatus: status,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.isUpdating,
    required this.onAdvance,
    required this.onInterviewStatusChanged,
  });

  final ApplicationModel application;
  final bool isUpdating;
  final Future<bool> Function(String stage) onAdvance;
  final Future<bool> Function(String status) onInterviewStatusChanged;

  static const _stages = [
    'application',
    'verification',
    'endorsement',
    'partner_submission',
    'interview',
    'placement_confirmation',
  ];

  @override
  Widget build(BuildContext context) {
    final stageIndex = _stages.indexOf(application.stage);
    final nextStage = stageIndex >= 0 && stageIndex < _stages.length - 1
        ? _stages[stageIndex + 1]
        : null;
    final company = application.companyName;
    final position = application.position;

    return CleanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.studentName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingXS),
                    Text(
                      [
                        application.applicationNumber,
                        if (company != null && company.isNotEmpty) company,
                        if (position != null && position.isNotEmpty) position,
                      ].join('  ·  '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StageBadge(label: _label(application.stage)),
            ],
          ),
          const SizedBox(height: UIConstants.spacingMD),
          LinearProgressIndicator(
            value: stageIndex < 0 ? 0 : (stageIndex + 1) / _stages.length,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: UIConstants.surfaceVariant,
            color: UIConstants.primary,
          ),
          if (application.stage == 'interview') ...[
            const SizedBox(height: UIConstants.spacingMD),
            DropdownButtonFormField<String>(
              initialValue: application.interviewStatus,
              decoration: const InputDecoration(labelText: 'Interview outcome'),
              items: const [
                DropdownMenuItem(
                  value: 'not_scheduled',
                  child: Text('Not scheduled'),
                ),
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(
                  value: 'offer_received',
                  child: Text('Offer received'),
                ),
                DropdownMenuItem(value: 'declined', child: Text('Declined')),
              ],
              onChanged: isUpdating
                  ? null
                  : (status) {
                      if (status != null) {
                        onInterviewStatusChanged(status);
                      }
                    },
            ),
          ],
          if (nextStage != null && application.workflowState != 'rejected') ...[
            const SizedBox(height: UIConstants.spacingMD),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isUpdating ? null : () => onAdvance(nextStage),
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward, size: 18),
                label: Text('Advance to ${_label(nextStage)}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingSM,
        vertical: UIConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: UIConstants.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UIConstants.radiusSM),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: UIConstants.primary),
      ),
    );
  }
}

String _label(String stage) {
  return switch (stage) {
    'partner_submission' => 'Partner submission',
    'placement_confirmation' => 'Placement confirmation',
    _ => '${stage[0].toUpperCase()}${stage.substring(1)}',
  };
}
