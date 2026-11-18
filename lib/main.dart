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
        title: 'Knot',
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

  @override
  void initState() {
    super.initState();
    _configured = _supabaseReady;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 64, color: _violet),
              const SizedBox(height: 16),
              const Text(
                'Knot Messenger',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _configured
                    ? 'Supabase подключен успешно. Готово к работе!'
                    : 'Требуется настройка переменных Supabase URL и Anon Key.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
