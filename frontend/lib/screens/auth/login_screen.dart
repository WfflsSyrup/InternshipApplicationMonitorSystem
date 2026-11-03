import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ui_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacingLG),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Consumer<AuthProvider>(
                builder: (context, auth, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      size: 34,
                      color: UIConstants.primary,
                    ),
                    const SizedBox(height: UIConstants.spacingMD),
                    Text(
                      'Internship Monitor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: UIConstants.spacingXL),
                    Text(
                      'Sign in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingLG),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      maxLength: 254,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        counterText: '',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)
                            ? null
                            : 'Enter a valid email address.';
                      },
                    ),
                    const SizedBox(height: UIConstants.spacingMD),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      maxLength: 128,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password.';
                        }
                        if (value.length > 128) {
                          return 'Password is too long.';
                        }
                        return null;
                      },
                    ),
                    if (_error != null || auth.notice != null) ...[
                      const SizedBox(height: UIConstants.spacingMD),
                      _ErrorBanner(message: _error ?? auth.notice!),
                    ],
                    const SizedBox(height: UIConstants.spacingLG),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingMD),
      decoration: BoxDecoration(
        color: UIConstants.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
        border: Border.all(color: UIConstants.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: UIConstants.error),
      ),
    );
  }
}
