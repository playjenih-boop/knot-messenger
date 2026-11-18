import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF080D10);
const _midnight = Color(0xFF111C32);
const _panel = Color(0xFF17243B);
const _blue = Color(0xFF0FF5A9E8);
const _violet = Color(0xFF0FFE8AFB);
const _muted = Color(0xFF5F6AAC);

bool _supabaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _supabaseReady = true;
  }
  runApp(const KnotApp());
}

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _panel,
            hintStyle: const TextStyle(color: _muted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: .06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _violet, width: 1.4),
            ),
          ),
        ),
        home: const _AppGate(),
      );
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _configured = false;
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _configured = _supabaseReady;
    if (_configured) {
      final session = Supabase.instance.client.auth.currentSession;
      _isLoggedIn = session != null;
    }
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _violet)),
      );
    }
    if (!_configured) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Требуется настройка Supabase',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Укажите переменные SUPABASE_URL и SUPABASE_ANON_KEY в GitHub Secrets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите ваш Email для авторизации через OTP',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const _AppGate()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 0, // Список чатов пока пуст
        itemBuilder: (context, index) => const ListTile(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _violet,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Действие для создания нового чата
        },
      ),
    );
  }
}
