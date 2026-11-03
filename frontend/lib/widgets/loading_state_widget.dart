import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import 'ui/state_widgets.dart' as ui;

class LoadingStateWidget extends StatelessWidget {
  final DataLoadingState state;
  final String errorMessage;
  final VoidCallback? onRetry;
  final String? emptyMessage;
  final Widget? child;

  const LoadingStateWidget({
    super.key,
    required this.state,
    this.errorMessage = '',
    this.onRetry,
    this.emptyMessage,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DataLoadingState.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOADING DATA...',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: AppColors.neonCyan.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case DataLoadingState.error:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 64),
                const SizedBox(height: 16),
                Text(
                  'CONNECTION ERROR',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'Failed to load data',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY CONNECTION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
        );

      case DataLoadingState.businessFailure:
        return ui.BusinessRuleFailureState(
          title: 'This request needs coordinator review',
          description: errorMessage,
          interventionSteps: const [
            'Confirm your access and the current application status.',
            'Ask the coordinator to correct any workflow or record issues.',
          ],
        );

      case DataLoadingState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: AppColors.textTertiary,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage?.toUpperCase() ?? 'NO DATA AVAILABLE',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );

      case DataLoadingState.success:
      case DataLoadingState.idle:
        return child ?? const SizedBox.shrink();
    }
  }
}
