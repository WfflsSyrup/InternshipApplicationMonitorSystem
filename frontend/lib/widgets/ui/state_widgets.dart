import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';

/// Loading State Widget
class LoadingState extends StatelessWidget {
  final String message;

  const LoadingState({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(UIConstants.primary),
            ),
          ),
          const SizedBox(height: UIConstants.spacingMD),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: UIConstants.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing2XL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: UIConstants.textTertiary),
            const SizedBox(height: UIConstants.spacingMD),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingSM),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: UIConstants.spacingLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Transient Network Error State with Auto-Retry UI
class TransientErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  const TransientErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingMD),
              decoration: BoxDecoration(
                color: UIConstants.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off, size: 32, color: UIConstants.warning),
            ),
            const SizedBox(height: UIConstants.spacingMD),
            Text(
              'Connection Issue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: UIConstants.spacingSM),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingLG),
            ElevatedButton.icon(
              onPressed: isRetrying ? null : onRetry,
              icon: isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(isRetrying ? 'Retrying...' : 'Retry'),
            ),
            const SizedBox(height: UIConstants.spacingSM),
            Text(
              'Automatic retries are complete. Retry again when you are ready.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Permanent Business Rule Failure State - Route to Human Intervention
class BusinessRuleFailureState extends StatelessWidget {
  final String title;
  final String description;
  final List<String> interventionSteps;
  final VoidCallback? onContactSupport;
  final VoidCallback? onEscalate;

  const BusinessRuleFailureState({
    super.key,
    required this.title,
    required this.description,
    required this.interventionSteps,
    this.onContactSupport,
    this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing2XL),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(UIConstants.spacingXL),
          decoration: BoxDecoration(
            color: UIConstants.surface,
            border: Border.all(
              color: UIConstants.error.withOpacity(0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(UIConstants.radiusLG),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacingSM),
                    decoration: BoxDecoration(
                      color: UIConstants.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.radiusMD),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: UIConstants.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requires Human Intervention',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: UIConstants.spacingXS),
                        Text(
                          'Business rule violation',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: UIConstants.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingLG),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: UIConstants.spacingSM),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: UIConstants.textSecondary,
                ),
              ),
              const SizedBox(height: UIConstants.spacingLG),
              Text(
                'Required Actions:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: UIConstants.spacingMD),
              ...interventionSteps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: UIConstants.spacingMD),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: UIConstants.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: UIConstants.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: UIConstants.spacingMD),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: UIConstants.spacingLG),
              Row(
                children: [
                  if (onEscalate != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEscalate,
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text('Escalate to Coordinator'),
                      ),
                    ),
                  if (onEscalate != null && onContactSupport != null)
                    const SizedBox(width: UIConstants.spacingSM),
                  if (onContactSupport != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onContactSupport,
                        icon: const Icon(Icons.support_agent, size: 18),
                        label: const Text('Contact Support'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
