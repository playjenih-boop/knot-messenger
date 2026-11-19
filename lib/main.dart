
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ywvliougphhralequxbp.supabase.co';
const supabaseAnonKey =
    'sb_publishable_O1bLWiOWytYx-SykbqFQLQ_jNwBeZlv';

const bg = Color(0xFF0B0B12);
const surface = Color(0xFF15151F);
const surface2 = Color(0xFF20202C);
const accent = Color(0xFF8B5CF6);
const accent2 = Color(0xFF6D42D8);
const textColor = Color(0xFFF5F3FF);
const muted = Color(0xFF9291A5);
const onlineColor = Color(0xFF43D9A3);

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

// ==================================================
// APP
// ==================================================

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Knot Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: surface,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ==================================================
// STARTUP ERROR
// ==================================================

class KnotStartupError extends StatelessWidget {
  final String error;

  const KnotStartupError({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 55,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Не удалось запустить Knot Messenger',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// AUTH GATE
// ==================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;

        if (session != null) {
          return const KnotHomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

// ==================================================
// AUTH SCREEN
// ==================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String _error = '';

  Future<void> _signIn() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !email.contains('@') ||
        !email.contains('.') ||
        email.startsWith('@') ||
        email.endsWith('@')) {
      setState(() {
        _error = 'Введите корректный адрес электронной почты.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
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
        _error = 'Ошибка отправки письма. Попробуйте ещё раз.';
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
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // LOGO

                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accent, accent2],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 35,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    size: 43,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'KNOT',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'MESSENGER',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 5,
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 45),

                Text(
                  _sent ? 'Проверь свою почту' : 'Добро пожаловать',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _sent
                      ? 'Мы отправили ссылку для входа на твою почту.'
                      : 'Общайся. Делись. Будь ближе.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 35),

                if (!_sent) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    autocorrect: false,
                    onSubmitted: (_) {
                      if (!_loading) _signIn();
                    },
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Электронная почта',
                      hintStyle: const TextStyle(color: muted),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: accent,
                      ),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Продолжить',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],

                if (_sent) ...[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.mark_email_read_rounded,
                          size: 48,
                          color: accent,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Открой письмо от Knot Messenger и нажми ссылку для входа.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sent = false;
                        _error = '';
                      });
                    },
                    child: const Text(
                      'Изменить email',
                      style: TextStyle(color: accent),
                    ),
                  ),
                ],

                const SizedBox(height: 50),

                const Text(
                  'Knot Messenger • Your people. Your space.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
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

// ==================================================
// HOME
// ==================================================

class KnotHomeScreen extends StatefulWidget {
  const KnotHomeScreen({super.key});

  @override
  State<KnotHomeScreen> createState() => _KnotHomeScreenState();
}

class _KnotHomeScreenState extends State<KnotHomeScreen> {
  int _selectedTab = 0;

  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Alex Morgan',
      'message': 'Давай сегодня увидимся 🔥',
      'time': '12:42',
      'unread': 2,
      'online': true,
      'initial': 'A',
      'color': Color(0xFF7356D8),
    },
    {
      'name': 'Mia',
      'message': 'Отправила тебе фотографии',
      'time': '12:18',
      'unread': 5,
      'online': true,
      'initial': 'M',
      'color': Color(0xFFDE729E),
    },
    {
      'name': 'Daniel',
      'message': 'Хорошо, договорились',
      'time': '11:56',
      'unread': 0,
      'online': false,
      'initial': 'D',
      'color': Color(0xFF3B9D9A),
    },
    {
      'name': 'Knot Team',
      'message': 'Добро пожаловать в Knot!',
      'time': '10:30',
      'unread': 1,
      'online': true,
      'initial': 'K',
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Sophia',
      'message': 'Ахаха 😂',
      'time': 'Вчера',
      'unread': 0,
      'online': false,
      'initial': 'S',
      'color': Color(0xFFCB8A4A),
    },
    {
      'name': 'David',
      'message': 'Увидимся завтра',
      'time': 'Вчера',
      'unread': 0,
      'online': false,
      'initial': 'D',
      'color': Color(0xFF5275C9),
    },
  ];

  final List<Map<String, dynamic>> _favorites = [
    {
      'name': 'Alex',
      'initial': 'A',
      'color': Color(0xFF7356D8),
      'online': true,
    },
    {
      'name': 'Mia',
      'initial': 'M',
      'color': Color(0xFFDE729E),
      'online': true,
    },
    {
      'name': 'Mark',
      'initial': 'M',
      'color': Color(0xFF3B9D9A),
      'online': false,
    },
    {
      'name': 'Kate',
      'initial': 'K',
      'color': Color(0xFFCB8A4A),
      'online': true,
    },
    {
      'name': 'Leo',
      'initial': 'L',
      'color': Color(0xFF5275C9),
      'online': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // AVATAR
  // ==================================================

  Widget _avatar({
    required String initial,
    required Color color,
    required double size,
    bool online = false,
  }) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
              ),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * 0.23,
              height: size * 0.23,
              decoration: BoxDecoration(
                color: onlineColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: bg,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==================================================
  // CHAT ITEM
  // ==================================================

  Widget _chatTile(Map<String, dynamic> chat) {
    final unread = chat['unread'] as int;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Чат с ${chat['name']} будет подключён далее',
            ),
            backgroundColor: surface2,
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 12,
        ),
        child: Row(
          children: [
            _avatar(
              initial: chat['initial'] as String,
              color: chat['color'] as Color,
              size: 57,
              online: chat['online'] as bool,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['name'] as String,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chat['message'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'] as String,
                  style: TextStyle(
                    color: unread > 0 ? accent : muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // FAVORITES
  // ==================================================

  Widget _favoritesWidget() {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final person = _favorites[index];

          return Padding(
            padding: const EdgeInsets.only(right: 19),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Профиль ${person['name"]}',
                    ),
                    backgroundColor: surface2,
                  ),
                );
              },
              child: Column(
                children: [
                  _avatar(
                  
