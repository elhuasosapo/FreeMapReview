import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/local_auth_provider.dart';

class LocalLoginScreen extends ConsumerWidget {
  const LocalLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final rememberMe = ref.watch(rememberMeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Login Locale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            CheckboxListTile(
              title: const Text('Ricorda login'),
              value: ref.watch(rememberMeProvider),
              onChanged: (value) {
                rememberMe.state = value ?? false;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text == 'admin' &&
                    passwordController.text == '0000') {
                  ref.read(localAuthProvider.notifier).state = true;
                  ref.read(localUserProvider.notifier).state = 'admin';
                  ref.read(localAuthNotifierProvider).value = true;
                  saveLocalAuth(true, 'admin', remember: ref.read(rememberMeProvider));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Credenziali non valide')),
                  );
                }
              },
              child: const Text('Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}
