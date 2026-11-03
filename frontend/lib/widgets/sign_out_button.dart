import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      onPressed: context.read<AuthProvider>().signOut,
      icon: const Icon(Icons.logout),
    );
  }
}
