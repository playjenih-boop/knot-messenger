
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://ywvliougphhralequxbp.supabase.co';

const String supabaseAnonKey =
    'sb_publishable_O1bLWiOWytYx-SykbqFQLQ_jNwBeZlv';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    runApp(const KnotApp());
  } catch (e) {
    runApp(KnotStartupError(error: e.toString()));
  }
}

class KnotStartupError extends StatelessWidget {
  const KnotStartupError({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось запустить Knot',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Проверь подключение к интернету '
                  'и настройки сервера Supabase.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Knot',
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Введите корректный адрес электронной почты.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.knot://login-callback/',
      );

      if (!mounted) return;

      setState(() {
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Ошибка входа: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Вход в Knot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              if (_sent) ...[
                const Icon(
                  Icons.mark_email_read,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ссылка для входа отправлена на ваш Email!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    labelText: 'Электронная почта',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  SelectableText(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Продолжить'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
