import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF080010);
const _midnight = Color(0xFF111C32);
const _panel = Color(0xFF172438);
const _blue = Color(0xFF0FFF9A68);
const _violet = Color(0xFFFF8FABFB);
const _muted = Color(0xFF5F6AAC);

bool _supabaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Жестко прописанные параметры для обхода проблем с GitHub Actions
  const url = 'https://ywvliouqphhralequxbp.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3dmxpb3VncGhocmFsZXF1eGJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMDAwMDAsImV4cCI6MjA1NTU3NjAwMH0';
  
  try {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _supabaseReady = true;
  } catch (e) {
    _supabaseReady = false;
  }
  
  runApp(const KnotApp());
}

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knot Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _violet,
          secondary: _blue,
          surface: _panel,
        ),
        useMaterial3: true,
      ),
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    if (_supabaseReady) {
      final session = Supabase.instance.client.auth.currentSession;
      _isLoggedIn = session != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supabaseReady) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Ошибка инициализации Supabase. Проверьте URL.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ),
      );
    }
    return _isLoggedIn ? const ChatsScreen() : const AuthScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: 'io.supabase.knot://login-callback/',
      );
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 64, color: _violet),
              const SizedBox(height: 16),
              const Text(
                'Вход в Knot',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_sent)
                const Text(
                  'Ссылка для входа отправлена на ваш Email!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green, fontSize: 16),
                )
              else ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'name@example.com'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  style: FilledButton.styleFrom(backgroundColor: _violet),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knot Chats'),
        backgroundColor: _midnight,
      ),
      body: const Center(child: Text('Вы вошли в систему!')),
    );
  }
}
