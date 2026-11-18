import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF080D18);
const _midnight = Color(0xFF111C32);
const _panel = Color(0xFF17243B);
const _blue = Color(0xFF55A9E8);
const _violet = Color(0xFF8878F2);
const _muted = Color(0xFF9AAAC2);
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
    if (_loading) return const _LoadingScreen();
    if (!_configured) return const _SetupScreen();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return const AuthScreen();
        // Supabase only sets `phone` on the user after the phone change is verified.
        if (user.phone == null || user.phone!.isEmpty) {
          return const PhoneVerificationScreen();
        }
        return const KnotHome();
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 52 : 38,
            height: large ? 52 : 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, Color(0xFF6255C9)]),
              borderRadius: BorderRadius.circular(large ? 17 : 12),
              boxShadow: [BoxShadow(color: _violet.withValues(alpha: .22), blurRadius: 20)],
            ),
            child: Text('K', style: TextStyle(fontSize: large ? 32 : 23, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(width: 11),
          Text('knot', style: TextStyle(fontSize: large ? 34 : 27, fontWeight: FontWeight.w800, letterSpacing: -1.1)),
        ],
      );
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _Brand(large: true),
              const SizedBox(height: 28),
              const Text('Подключи Knot к серверу', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text('Для регистрации и реальных сообщений создай проект Supabase и запусти приложение с SUPABASE_URL и SUPABASE_ANON_KEY. Инструкция находится в README.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.5)),
            ]),
          ),
        ),
      );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _busy = false;
  bool _hidePassword = true;
  String? _notice;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _notice = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        final result = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        if (result.session == null) {
          setState(() => _notice = 'Аккаунт создан. Подтверди Email по ссылке из письма, затем войди в Knot, чтобы подтвердить номер телефона.');
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Не удалось выполнить запрос. Проверь подключение и настройки сервера.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) { _showError('Сначала введи корректный Email.'); return; }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _notice = 'Если аккаунт существует, письмо для восстановления уже отправлено.');
    } on AuthException catch (e) { _showError(e.message); }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF8C3D55)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Center(child: _Brand(large: true)),
                    const SizedBox(height: 42),
                    Text(_register ? 'Твой мир. На связи.' : 'С возвращением', style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                    const SizedBox(height: 8),
                    Text(_register ? 'Создай аккаунт Knot — общение начинается здесь.' : 'Войди, чтобы продолжить общение.', style: const TextStyle(color: _muted, height: 1.4)),
                    const SizedBox(height: 28),
                    if (_register) ...[
                      _Field(controller: _name, label: 'Имя', hint: 'Как тебя называть?', icon: Icons.person_outline, validator: (v) => (v == null || v.trim().length < 2) ? 'Введи имя (минимум 2 символа)' : null),
                      const SizedBox(height: 14),
                    ],
                    _Field(controller: _email, label: 'Электронная почта', hint: 'name@example.com', icon: Icons.mail_outline, keyboard: TextInputType.emailAddress, validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Проверь адрес Email' : null),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      validator: (v) => (v == null || v.length < 8) ? 'Пароль должен содержать минимум 8 символов' : null,
                      decoration: InputDecoration(labelText: 'Пароль', hintText: 'Минимум 8 символов', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hidePassword = !_hidePassword)),
                    ),
                    if (!_register) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgotPassword, child: const Text('Забыли пароль?'))),
                    if (_notice != null) ...[
                      const SizedBox(height: 14),
                      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _blue.withValues(alpha: .10), borderRadius: BorderRadius.circular(14), border: Border.all(color: _blue.withValues(alpha: .25))), child: Text(_notice!, style: const TextStyle(color: Color(0xFFB9DFFF), height: 1.4))),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                      child: _busy ? const SizedBox(height: 21, width: 21, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'Создать аккаунт' : 'Войти', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    Center(child: TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _notice = null; }), child: Text(_register ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться'))),
                    const SizedBox(height: 22),
                    const Text('Продолжая, ты соглашаешься с условиями использования и политикой конфиденциальности Knot.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF73839D), fontSize: 11, height: 1.5)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});
  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _phone.dispose(); _code.dispose(); super.dispose(); }

  Future<void> _sendCode() async {
    final value = _phone.text.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value)) {
      setState(() => _error = 'Введи номер в международном формате, например +380XXXXXXXXX.'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(phone: value));
      setState(() => _sent = true);
    } on AuthException catch (e) { setState(() => _error = e.message); }
    catch (_) { setState(() => _error = 'Не удалось отправить SMS. Проверь настройки SMS-провайдера.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _verify() async {
    final value = _phone.text.trim();
    final token = _code.text.trim();
    if (token.length < 6) { setState(() => _error = 'Введи код из SMS.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.verifyOTP(phone: value, token: token, type: OtpType.phoneChange);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({'onboarding_complete': true}).eq('id', user.id);
      }
    } on AuthException catch (e) { setState(() => _error = e.message); }
    catch (_) { setState(() => _error = 'Не удалось подтвердить номер. Попробуй ещё раз.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: _bg, title: const _Brand()),
        body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.phonelink_lock_outlined, size: 58, color: _blue),
          const SizedBox(height: 24),
          const Text('Подтверди номер телефона', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          const Text('Email подтверждён. Остался номер телефона — он поможет защитить аккаунт и восстановить доступ.', style: TextStyle(color: _muted, height: 1.5)),
          const SizedBox(height: 26),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Номер телефона', hintText: '+380XXXXXXXXX', prefixIcon: Icon(Icons.phone_outlined))),
          if (_sent) ...[
            const SizedBox(height: 14),
            TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 8, decoration: const InputDecoration(labelText: 'Код из SMS', hintText: 'Введи код подтверждения', prefixIcon: Icon(Icons.sms_outlined))),
          ],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8B9A)))),
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : (_sent ? _verify : _sendCode), style: FilledButton.styleFrom(backgroundColor: _violet, minimumSize: const Size.fromHeight(55)), child: _busy ? const CircularProgressIndicator() : Text(_sent ? 'Подтвердить номер' : 'Отправить SMS-код')),
          if (_sent) TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Отправить код ещё раз')),
          const SizedBox(height: 12),
          TextButton(onPressed: () async => Supabase.instance.client.auth.signOut(), child: const Text('Выйти из аккаунта')),
        ]))))),
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.hint, required this.icon, this.keyboard, this.validator});
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, keyboardType: keyboard, validator: validator, decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)));
}

class KnotHome extends StatefulWidget {
  const KnotHome({super.key});
  @override
  State<KnotHome> createState() => _KnotHomeState();
}

class _KnotHomeState extends State<KnotHome> {
  int _tab = 0;
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _chats = [];
  RealtimeChannel? _updates;
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _updates = _db.channel('knot-home-$_uid')
      ..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'messages', callback: (_) => _loadChats())
      ..subscribe();
  }

  @override
  void dispose() {
    _search.dispose();
    if (_updates != null) _db.removeChannel(_updates!);
    super.dispose();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    try {
      final memberships = await _db.from('conversation_members').select('conversation_id').eq('user_id', _uid);
      final ids = memberships.map((e) => e['conversation_id'].toString()).toList();
      if (ids.isEmpty) {
        if (mounted) setState(() { _chats = []; _loading = false; _error = null; });
        return;
      }
      final rows = await _db.from('conversations')
        .select('id,kind,title,updated_at,conversation_members(user_id,profiles(display_name,knot_id,avatar_path))')
        .inFilter('id', ids).order('updated_at', ascending: false);
      final result = <Map<String, dynamic>>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final last = await _db.from('messages').select('body,message_type,sender_id,created_at')
          .eq('conversation_id', row['id']).isFilter('deleted_at', null)
          .order('created_at', ascending: false).limit(1);
        row['last_message'] = last.isEmpty ? null : last.first;
        final members = (row['conversation_members'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        row['other_members'] = members.where((m) => m['user_id'] != _uid).toList();
        result.add(row);
      }
      if (mounted) setState(() { _chats = result; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Не удалось загрузить чаты. Проверь миграции базы данных и подключение.'; });
    }
  }

  Future<void> _newChat() async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final knotId = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _midnight,
      title: const Text('Новый чат'),
      content: Form(key: key, child: TextFormField(controller: controller, autofocus: true,
        decoration: const InputDecoration(labelText: 'Knot ID', hintText: 'Например, knot_a1b2c3d4'),
        validator: (v) => (v == null || v.trim().length < 6) ? 'Введи корректный Knot ID' : null)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(ctx, controller.text.trim()); }, child: const Text('Найти'))],
    ));
    controller.dispose();
    if (knotId == null || !mounted) return;
    try {
      final id = await _db.rpc('create_direct_chat', params: {'p_knot_id': knotId});
      await _loadChats();
      if (!mounted) return;
      Map<String, dynamic>? chat;
      for (final item in _chats) { if (item['id'] == id) { chat = item; break; } }
      if (chat != null) _openChat(chat);
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось создать чат. Проверь Knot ID и подключение.')));
    }
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(chat: chat))).then((_) => _loadChats());
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Чаты', 'Звонки', 'Контакты', 'Профиль'];
    return Scaffold(
      appBar: AppBar(backgroundColor: _bg, titleSpacing: 20, title: const _Brand(),
        actions: [if (_tab == 0) IconButton(onPressed: _newChat, tooltip: 'Новый чат', icon: const Icon(Icons.edit_square))]),
      body: _tab == 0 ? _chatList() : _placeholder(titles[_tab]),
      floatingActionButton: _tab == 0 ? FloatingActionButton.small(backgroundColor: _violet, foregroundColor: Colors.white, onPressed: _newChat, child: const Icon(Icons.add_comment_outlined)) : null,
      bottomNavigationBar: NavigationBar(backgroundColor: _midnight, indicatorColor: _violet.withValues(alpha: .23), selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value), destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Чаты'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Звонки'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Контакты'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ]),
    );
  }

  Widget _chatList() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 12), child: Text('Твои разговоры', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700))),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Поиск чатов', prefixIcon: Icon(Icons.search)))),
    const SizedBox(height: 10),
    Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted)), const SizedBox(height: 12), OutlinedButton(onPressed: _loadChats, child: const Text('Повторить'))]))
      : _chats.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.forum_outlined, size: 48, color: _violet), const SizedBox(height: 14), const Text('Пока нет переписок', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 7), const Text('Найди человека по Knot ID и начни первый разговор.', textAlign: TextAlign.center, style: TextStyle(color: _muted)), const SizedBox(height: 16), FilledButton.icon(onPressed: _newChat, icon: const Icon(Icons.add), label: const Text('Новый чат'))])))
      : RefreshIndicator(onRefresh: _loadChats, child: ListView(children: _chats.where((c) {
          final members = c['other_members'] as List? ?? [];
          final profile = members.isNotEmpty ? (members.first['profiles'] as Map? ?? {}) : {};
          final name = (c['title'] ?? profile['display_name'] ?? 'Knot чат').toString();
          return name.toLowerCase().contains(_search.text.toLowerCase());
        }).map((c) {
          final members = c['other_members'] as List? ?? [];
          final profile = members.isNotEmpty ? (members.first['profiles'] as Map? ?? {}) : {};
          final name = (c['title'] ?? profile['display_name'] ?? 'Knot чат').toString();
          final last = c['last_message'] as Map?;
          final preview = last == null ? 'Начни общение' : (last['body'] ?? 'Вложение').toString();
          final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'K';
          return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            leading: CircleAvatar(radius: 25, backgroundColor: _violet.withValues(alpha: .8), child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 19))),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted)),
            trailing: const Icon(Icons.chevron_right, color: _muted, size: 19), onTap: () => _openChat(c));
        }).toList()))),
  ]);

  Widget _placeholder(String title) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(title == 'Профиль' ? Icons.person_outline : title == 'Контакты' ? Icons.people_outline : Icons.call_outlined, size: 42, color: _violet),
    const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6), const Text('Этот раздел готовится к запуску', style: TextStyle(color: _muted)),
    if (title == 'Профиль') FutureBuilder<Map<String, dynamic>>(
      future: _db.from('profiles').select('display_name,knot_id,bio').eq('id', _uid).single(),
      builder: (context, snap) => snap.hasData ? Padding(padding: const EdgeInsets.all(20), child: Column(children: [Text(snap.data!['display_name'] ?? ''), const SizedBox(height: 5), SelectableText('@${snap.data!['knot_id']}', style: const TextStyle(color: _blue)), TextButton(onPressed: () => Supabase.instance.client.auth.signOut(), child: const Text('Выйти из аккаунта'))])) : const CircularProgressIndicator()),
  ]));
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.chat});
  final Map<String, dynamic> chat;
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String? _sendError;
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;
  String get _conversationId => widget.chat['id'].toString();
  String get _title {
    final members = widget.chat['other_members'] as List? ?? [];
    if (widget.chat['title'] != null) return widget.chat['title'].toString();
    if (members.isEmpty) return 'Knot чат';
    final profile = members.first['profiles'] as Map? ?? {};
    return (profile['display_name'] ?? 'Knot пользователь').toString();
  }

  @override
  void initState() {
    super.initState();
    _db.from('conversation_members').update({'last_read_at': DateTime.now().toUtc().toIso8601String()}).eq('conversation_id', _conversationId).eq('user_id', _uid);
  }
  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _sendError = null; });
    _input.clear();
    try {
      await _db.from('messages').insert({'conversation_id': _conversationId, 'sender_id': _uid, 'body': text, 'message_type': 'text'});
      await _db.from('conversations').update({'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', _conversationId);
    } catch (_) {
      _input.text = text;
      if (mounted) setState(() => _sendError = 'Сообщение не отправлено. Проверь соединение и попробуй снова.');
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _bg, title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const Text('Knot · личный чат', style: TextStyle(fontSize: 11, color: _blue))]), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)), IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))]),
    body: Column(children: [
      Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.from('messages').stream(primaryKey: ['id']).eq('conversation_id', _conversationId).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Не удалось загрузить сообщения', style: TextStyle(color: _muted)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final messages = snapshot.data!.where((m) => m['deleted_at'] == null).toList();
          if (messages.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.waving_hand_outlined, color: _violet, size: 42), SizedBox(height: 12), Text('Это начало вашей истории', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Отправь первое сообщение в Knot.', style: TextStyle(color: _muted))])));
          return ListView.builder(controller: _scroll, padding: const EdgeInsets.fromLTRB(14, 18, 14, 18), itemCount: messages.length, itemBuilder: (context, index) {
            final m = messages[index];
            final mine = m['sender_id'] == _uid;
            final time = DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal();
            final stamp = time == null ? '' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.fromLTRB(13, 10, 13, 7), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78), decoration: BoxDecoration(color: mine ? const Color(0xFF554A9E) : _panel, borderRadius: BorderRadius.only(topLeft: const Radius.circular(17), topRight: const Radius.circular(17), bottomLeft: Radius.circular(mine ? 17 : 5), bottomRight: Radius.circular(mine ? 5 : 17))), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Align(alignment: Alignment.centerLeft, child: Text((m['body'] ?? 'Вложение').toString(), style: const TextStyle(color: Colors.white, height: 1.35))), const SizedBox(height: 4), Text(stamp, style: const TextStyle(fontSize: 10, color: Color(0xFFCEC9E9)))])));
          });
        }),
      if (_sendError != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_sendError!, style: const TextStyle(color: Color(0xFFFF8B9A), fontSize: 12))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отправка файлов появится в следующей версии.'))), icon: const Icon(Icons.add_circle_outline, color: _blue)),
        Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Сообщение...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13)))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _sending ? null : _send, style: IconButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white), icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}
