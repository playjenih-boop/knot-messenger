
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://ywvliougphhralequxbp.supabase.co';
const String supabaseKey =
    'sb_publishable_O1bLWiOWytYx-SykbqFQLQ_jNwBeZlv';

const Color bgColor = Color(0xFF0B0B12);
const Color surfaceColor = Color(0xFF15151F);
const Color surface2Color = Color(0xFF20202C);
const Color accentColor = Color(0xFF8B5CF6);
const Color accent2Color = Color(0xFF6D42D8);
const Color textColor = Color(0xFFF5F3FF);
const Color mutedColor = Color(0xFF9291A5);
const Color onlineColor = Color(0xFF43D9A3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    runApp(const KnotApp());
  } catch (e) {
    runApp(KnotStartupError(error: e.toString()));
  }
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
        scaffoldBackgroundColor: bgColor,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor,
          surface: surfaceColor,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

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
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ошибка запуска Knot',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mutedColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

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

// ============================================================
// AUTH SCREEN
// ============================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  bool _emailSent = false;
  String? _error;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Введите корректный адрес электронной почты.";
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
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Не удалось отправить письмо. Попробуйте ещё раз.';
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
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // LOGO
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [accentColor, accent2Color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 35,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 45,
                    color: Colors.white,
          ),
        ),
                const SizedBox(height: 24),

                const Text(
                  'Knot',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Общение без границ',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 45),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Добро пожаловать',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Войдите, чтобы продолжить общение.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 25),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Электронная почта',
                          hintStyle: const TextStyle(color: mutedColor),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: mutedColor,
                          ),
                          filled: true,
                          fillColor: surface2Color,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Продолжить',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      if (_emailSent) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: onlineColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: onlineColor,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Письмо отправлено. Проверьте почту и перейдите по ссылке.',
                                  style: TextStyle(
                                    color: onlineColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Продолжая, вы соглашаетесь с правилами использования Knot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class KnotHomeScreen extends StatefulWidget {
  const KnotHomeScreen({super.key});

  @override
  State<KnotHomeScreen> createState() => _KnotHomeScreenState();
}

class _KnotHomeScreenState extends State<KnotHomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Alex Morgan',
      'message': 'Отлично, договорились!',
      'time': '12:45',
      'unread': 2,
      'online': true,
      'avatar': 'A',
      'color': 0xFF7C5CFC,
    },
    {
      'name': 'Mia',
      'message': 'Отправила тебе фото',
      'time': '12:32',
      'unread': 1,
      'online': true,
      'avatar': 'M',
      'color': 0xFFEC70A7,
    },
    {
      'name': 'Daniel',
      'message': 'Хорошо, увидимся завтра',
      'time': '11:58',
      'unread': 0,
      'online': false,
      'avatar': 'D',
      'color': 0xFF3CA8A1,
    },
    {
      'name': 'Knot Team',
      'message': 'Добро пожаловать в Knot!',
      'time': 'Вчера',
      'unread': 0,
      'online': false,
      'avatar': 'K',
      'color': 0xFF6B75E8,
    },
    {
      'name': 'Sophia',
      'message': 'Спасибо ❤️',
      'time': 'Вчера',
      'unread': 0,
      'online': true,
      'avatar': 'S',
      'color': 0xFFE6A452,
    },
    {
      'name': 'David',
      'message': 'Как дела?',
      'time': 'Пн',
      'unread': 0,
      'online': false,
      'avatar': 'D',
      'color': 0xFF5694D8,
    },
  ];

  final List<Map<String, dynamic>> _contacts = [
    {
      'name': 'Alex Morgan',
      'avatar': 'A',
      'color': 0xFF7C5CFC,
      'online': true,
    },
    {
      'name': 'Mia',
      'avatar': 'M',
      'color': 0xFFEC70A7,
      'online': true,
    },
    {
      'name': 'Daniel',
      'avatar': 'D',
      'color': 0xFF3CA8A1,
      'online': false,
    },
    {
      'name': 'Sophia',
      'avatar': 'S',
      'color': 0xFFE6A452,
      'online': true,
    },
    {
      'name': 'David',
      'avatar': 'D',
      'color': 0xFF5694D8,
      'online': false,
    },
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pages = [
      _chatsPage(),
      _contactsPage(),
      _explorePage(),
      _profilePage(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: surfaceColor,
          indicatorColor: accentColor.withOpacity(0.18),
          selectedIndex: _selectedIndex,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Контакты',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Обзор',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CHATS PAGE
  // ==========================================================

  Widget _chatsPage() {
    final query = _searchQuery.trim().toLowerCase();

    final filteredChats = _chats.where((chat) {
      final name = chat['name'].toString().toLowerCase();
      final message = chat['message'].toString().toLowerCase();

      return name.contains(query) || message.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Knot',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),
              ),
              _headerButton(
                Icons.edit_square,
                () => _showMessage('Создание нового чата скоро появится'),
              ),
              const SizedBox(width: 10),
              _headerButton(
                Icons.add,
                () => _showMessage('Новый чат скоро появится'),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Поиск',
              hintStyle: const TextStyle(color: mutedColor),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: mutedColor,
              ),
              filled: true,
              fillColor: surfaceColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        _favoritesWidget(),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              const Text(
                'Сообщения',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredChats.length}',
                style: const TextStyle(color: mutedColor),
              ),
            ],
          ),
        ),
