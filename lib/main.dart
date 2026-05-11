import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ============================================================
// 🌐 InAppBrowserPage - المتصفح الداخلي الرائع
// ============================================================
class InAppBrowserPage extends StatefulWidget {
  final String url;
  final String title;
  final bool isDark;

  const InAppBrowserPage({
    Key? key,
    required this.url,
    this.title = '',
    this.isDark = true,
  }) : super(key: key);

  @override
  State<InAppBrowserPage> createState() => _InAppBrowserPageState();
}

class _InAppBrowserPageState extends State<InAppBrowserPage>
    with SingleTickerProviderStateMixin {
  late WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _currentUrl = '';
  String _pageTitle = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── متغيرات السحب للإغلاق ──
  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _pageTitle = widget.title;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.isDark ? const Color(0xFF111111) : Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
              _currentUrl = url;
            });
          },
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
              _loadingProgress = 1.0;
            });
            _fadeController.forward(from: 0);
            final title = await _controller.getTitle();
            final canBack = await _controller.canGoBack();
            final canFwd = await _controller.canGoForward();
            if (mounted) {
              setState(() {
                _pageTitle = title ?? _pageTitle;
                _canGoBack = canBack;
                _canGoForward = canFwd;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getDomain(String url) {
    try {
      return Uri.parse(url).host.replaceAll('www.', '');
    } catch (_) {
      return url;
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF111111) : Colors.white;
    final surface = widget.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final subColor = widget.isDark ? Colors.white54 : Colors.black45;
    const red = Color(0xFFE53935);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // ── شريط العنوان العلوي ──
            Container(
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          // زر الإغلاق
                          _BrowserButton(
                            icon: Icons.close_rounded,
                            isDark: widget.isDark,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 6),
                          // شريط العنوان والرابط
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 13,
                                      color: Colors.green[400],
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_pageTitle.isNotEmpty)
                                            Text(
                                              _pageTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          Text(
                                            _getDomain(_currentUrl),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 11,
                                              color: subColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // فتح في متصفح خارجي
                          _BrowserButton(
                            icon: Icons.open_in_new_rounded,
                            isDark: widget.isDark,
                            onTap: _openExternal,
                          ),
                        ],
                      ),
                    ),
                    // شريط التحميل
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _isLoading ? 3 : 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(red),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── WebView ──
            Expanded(
              child: Stack(
                children: [
                  FadeTransition(
                    opacity: _isLoading
                        ? const AlwaysStoppedAnimation(0.0)
                        : _fadeAnimation,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: _loadingProgress > 0 ? _loadingProgress : null,
                              strokeWidth: 3,
                              color: red,
                              backgroundColor: widget.isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── شريط التنقل السفلي ──
            Container(
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  top: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BrowserButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: widget.isDark,
                        enabled: _canGoBack,
                        onTap: () async {
                          if (await _controller.canGoBack()) {
                            _controller.goBack();
                          }
                        },
                      ),
                      _BrowserButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        isDark: widget.isDark,
                        enabled: _canGoForward,
                        onTap: () async {
                          if (await _controller.canGoForward()) {
                            _controller.goForward();
                          }
                        },
                      ),
                      _BrowserButton(
                        icon: Icons.refresh_rounded,
                        isDark: widget.isDark,
                        onTap: () => _controller.reload(),
                      ),
                      _BrowserButton(
                        icon: Icons.share_rounded,
                        isDark: widget.isDark,
                        onTap: _openExternal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool enabled;

  const _BrowserButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white24 : Colors.black26);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.white.withOpacity(enabled ? 0.07 : 0.03)
              : Colors.black.withOpacity(enabled ? 0.06 : 0.02),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// دالة مساعدة لفتح الروابط في المتصفح الداخلي
/// CupertinoPageRoute يتعامل تلقائياً مع حركة الصفحتين وسحب الإغلاق
void openInAppBrowser(BuildContext context, String url,
    {String title = '', bool isDark = true}) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (_) => InAppBrowserPage(url: url, title: title, isDark: isDark),
    ),
  );
}

class NotificationService {
  static const String _channelId = 'scrptaty_notifications';
  static const int _welcomeNotificationId = 1001;
  static const int _postNotificationBaseId = 2000;
  static Timer? _welcomeTimer;

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'Scrptaty Notifications',
            description: 'General app notifications',
            importance: Importance.max,
          ),
        );
  }

  static Future<bool> requestPermission() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImplementation?.requestNotificationsPermission();
    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  static Future<void> scheduleWelcomeNotification() async {
    await flutterLocalNotificationsPlugin.cancel(_welcomeNotificationId);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _welcomeNotificationId,
      'مرحبا بك في سكربتاتي',
      'تم تفعيل الإشعارات بنجاح.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Scrptaty Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showWelcomeNotificationAfterDelay() async {
    _welcomeTimer?.cancel();
    _welcomeTimer = Timer(const Duration(seconds: 5), () async {
      await flutterLocalNotificationsPlugin.show(
        _welcomeNotificationId,
        'مرحبا بك في سكربتاتي',
        'تم تفعيل الإشعارات بنجاح.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Scrptaty Notifications',
            channelDescription: 'General app notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  static Future<void> showPostNotification(PostItem post) async {
    final title = post.title.isNotEmpty ? post.title : 'منشور جديد';
    final body =
        post.description.isNotEmpty ? post.description : 'تمت إضافة منشور جديد.';
    final imageBytes = post.imageUrl.isNotEmpty
        ? await _downloadImageBytes(post.encodedImageUrl)
        : null;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Scrptaty Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: imageBytes != null
          ? BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon: ByteArrayAndroidBitmap(imageBytes),
              contentTitle: title,
              summaryText: body,
            )
          : BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Scrptaty',
            ),
    );

    await flutterLocalNotificationsPlugin.show(
      _postNotificationBaseId +
          (int.tryParse(post.id) ??
              DateTime.now().millisecondsSinceEpoch.remainder(100000)),
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: post.id,
    );
  }

  static Future<Uint8List?> _downloadImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> cancelAll() async {
    _welcomeTimer?.cancel();
    _welcomeTimer = null;
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    ),
  );}
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isDark = true;
  User? _currentUser;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadTheme();
    // الاستماع لتغييرات حالة المصادقة بشكل مباشر
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
    PostNotificationMonitor.start();
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool("theme") ?? true;
    });
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = !isDark;
      prefs.setBool("theme", isDark);
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PostNotificationMonitor.checkNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    PostNotificationMonitor.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: MainShell(
        isDark: isDark,
        onToggle: toggleTheme,
        currentUser: _currentUser,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final User? currentUser;
  const MainShell({required this.isDark, required this.onToggle, this.currentUser});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  double _currentPage = 0.0;
  late final PageController _pageController;
  final List<GlobalKey> _pageKeys = List.generate(4, (_) => GlobalKey());
  double _homeScrollOffset = 0.0;
  VoidCallback? _homeScrollToTopCallback;
  Function(VoidCallback)? _registerHomeScrollCallback;

  final List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    _NavItem(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt_rounded,
      label: 'سكربتات',
    ),
    _NavItem(
      icon: Icons.phone_outlined,
      activeIcon: Icons.phone_rounded,
      label: 'اتصل بنا',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'الإعدادات',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _pageController.addListener(() {
      if (!_pageController.hasClients) return;
      final page = _pageController.page ?? _currentIndex.toDouble();
      setState(() {
        _currentPage = page;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) {
      // نفس الصفحة
      if (index == 0) {
        // الصفحة الرئيسية - ننزل لفوق
        _scrollToTop();
      }
      return;
    }
    
    // حفظ موقع السكرول للصفحة الحالية
    if (_currentIndex == 0) {
      _saveHomeScrollOffset();
    }
    
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _saveHomeScrollOffset() {
    // Will be called from HomePage via callback
  }

  void _scrollToTop() {
    // Use callback to scroll to top in HomePage
    if (_homeScrollToTopCallback != null) {
      _homeScrollToTopCallback!();
    }
  }

  void _restoreHomeScrollOffset() {
    // Will be called from HomePage via callback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? const Color(0xFF111111) : Colors.white,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => setState(() {
          _currentIndex = i;
          _currentPage = i.toDouble();
        }),
        children: [
          HomePage(
            isDark: widget.isDark, 
            onToggle: widget.onToggle,
            currentUser: widget.currentUser,
            onRegisterScrollCallback: (callback) {
              _homeScrollToTopCallback = callback;
            },
          ),
          ScriptsPage(isDark: widget.isDark),
          ContactPage(isDark: widget.isDark),
          SettingsPage(isDark: widget.isDark, onToggle: widget.onToggle),
        ],
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.ltr,
        child: _GlassNavBar(
          currentPage: _currentPage,
          currentIndex: _currentIndex,
          items: _items,
          isDark: widget.isDark,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlassNavBar extends StatefulWidget {
  final double currentPage;
  final int currentIndex;
  final List<_NavItem> items;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentPage,
    required this.currentIndex,
    required this.items,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<_GlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
        child: MouseRegion(
          onEnter: (_) => _triggerPulse(),
          onExit: (_) {},
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    _triggerPulse();
                  },
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      if (widget.currentIndex < widget.items.length - 1) {
                        widget.onTap(widget.currentIndex + 1);
                      }
                    } else if (details.primaryVelocity! > 0) {
                      if (widget.currentIndex > 0) {
                        widget.onTap(widget.currentIndex - 1);
                      }
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.red.withOpacity(0.03)
                          : const Color.fromARGB(255, 243, 33, 33)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.18)
                            : Colors.black.withOpacity(0.10),
                        width: 0.5,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth =
                            constraints.maxWidth / widget.items.length;

                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: widget.currentIndex * itemWidth + 5,
                              top: 5,
                              bottom: 5,
                              width: itemWidth - 10,
                              child: _buildMovingIndicator(),
                            ),
                            Row(
                              children: List.generate(
                                widget.items.length,
                                (i) => _NavBarItem(
                                  item: widget.items[i],
                                  itemIndex: i,
                                  currentPage: widget.currentPage,
                                  isDark: widget.isDark,
                                  onTap: () {
                                    _triggerPulse();
                                    widget.onTap(i);
                                  },
                                  itemWidth: itemWidth,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovingIndicator() {
    final fracPart = widget.currentPage - widget.currentPage.floor();

    final stretchFactor = fracPart < 0.5 ? fracPart * 2 : (1 - fracPart) * 2;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            const Color(0xFFFF3333).withOpacity(0.25 + stretchFactor * 0.1),
            const Color(0xFFFF3333).withOpacity(0.10 + stretchFactor * 0.05),
          ],
        ),
        border: Border.all(
          color:
              const Color(0xFFFF3333).withOpacity(0.15 + stretchFactor * 0.1),
          width: 0.5,
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final int itemIndex;
  final double currentPage;
  final bool isDark;
  final VoidCallback onTap;
  final double itemWidth;

  const _NavBarItem({
    required this.item,
    required this.itemIndex,
    required this.currentPage,
    required this.isDark,
    required this.onTap,
    required this.itemWidth,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _wasActive = (widget.currentPage.round() == widget.itemIndex);
  }

  @override
  void didUpdateWidget(_NavBarItem old) {
    super.didUpdateWidget(old);
    final isNowActive = widget.currentPage.round() == widget.itemIndex;
    if (isNowActive && !_wasActive) {
      _controller.forward(from: 0);
    }
    _wasActive = isNowActive;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getActivationStrength() {
    final distance = (widget.currentPage - widget.itemIndex).abs();
    if (distance >= 1.0) return 0.0;
    return 1.0 - distance;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? Colors.red : Colors.red;

    final inactiveColor = widget.isDark
        ? Colors.white.withOpacity(0.7)
        : const Color.fromARGB(255, 73, 44, 44).withOpacity(0.8);

    final strength = _getActivationStrength();
    final isFullyActive = strength > 0.99;

    final Color resolvedColor =
        Color.lerp(inactiveColor, activeColor, strength)!;

    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: isFullyActive
                    ? _scaleAnim
                    : AlwaysStoppedAnimation(1.0 + strength * 0.15),
                child: Icon(
                  strength > 0.5 ? widget.item.activeIcon : widget.item.icon,
                  color: resolvedColor,
                  size: 24 + strength * 1.5,
                  shadows: strength < 0.5
                      ? [
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 0.7,
                            color: const Color.fromARGB(255, 255, 255, 255)
                                .withOpacity(1),
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: resolvedColor,
                  shadows: strength < 0.7
                      ? [
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 0.5,
                            color: const Color.fromARGB(255, 255, 255, 255)
                                .withOpacity(1),
                          ),
                        ]
                      : [],
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🔥 HomePage - الصفحة الرئيسية
// ============================================================
class PostItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  const PostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    };
  }

  String get encodedImageUrl => Uri.encodeFull(imageUrl);

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final rawImage = _readString(json, ['image', 'image_url', 'photo', 'img']);
    final resolvedImage = rawImage.isEmpty
        ? ''
        : (rawImage.startsWith('http')
            ? rawImage
            : 'https://scrptaty.com/posts/$rawImage');

    return PostItem(
      id: _readString(json, ['id']),
      title: _readString(json, ['title', 'name']),
      description: _readString(json, ['description', 'content', 'body']),
      imageUrl: resolvedImage,
    );
  }
}

String stripHtmlTags(String htmlText) {
  return htmlText
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .trim();
}

/// تحويل HTML إلى Markdown للتعديل في المحرر
String htmlToMarkdown(String html) {
  if (html.trim().isEmpty) return '';
  // إذا لم يكن HTML (لا يحتوي على وسوم)، أعده كما هو
  if (!html.contains('<') || !html.contains('>')) return html;

  String text = html;

  // div style text-align → تحويلها للصيغة التي يستخدمها المحرر
  text = text.replaceAllMapped(
    RegExp(r'<div[^>]*style="[^"]*text-align:\s*(center|left|right)[^"]*"[^>]*>([\s\S]*?)</div>'),
    (m) {
      final align = m[1]!.trim();
      final content = _stripTags(m[2]!).trim();
      if (align == 'right') return content;
      return '<div align="$align">$content</div>';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'<div align="([^"]+)">([\s\S]*?)</div>'),
    (m) {
      final align = m[1]!.trim();
      final content = _stripTags(m[2]!).trim();
      if (align == 'right') return content;
      return '<div align="$align">$content</div>';
    },
  );

  // h1, h2, h3
  text = text.replaceAllMapped(RegExp(r'<h1[^>]*>([\s\S]*?)</h1>'), (m) => '# ${_stripTags(m[1]!)}\n');
  text = text.replaceAllMapped(RegExp(r'<h2[^>]*>([\s\S]*?)</h2>'), (m) => '## ${_stripTags(m[1]!)}\n');
  text = text.replaceAllMapped(RegExp(r'<h3[^>]*>([\s\S]*?)</h3>'), (m) => '### ${_stripTags(m[1]!)}\n');

  // hr
  text = text.replaceAll(RegExp(r'<hr\s*/?>'), '\n---\n');

  // blockquote
  text = text.replaceAllMapped(RegExp(r'<blockquote[^>]*>([\s\S]*?)</blockquote>'), (m) => '> ${_stripTags(m[1]!)}\n');

  // ol / ul / li
  int olCounter = 0;
  bool inOl = false;
  final lines = text.split('\n');
  final result = <String>[];
  for (final line in lines) {
    final t = line.trim();
    if (t.startsWith('<ol')) { inOl = true; olCounter = 0; continue; }
    if (t.startsWith('</ol>')) { inOl = false; result.add(''); continue; }
    if (t.startsWith('<ul') || t.startsWith('</ul>')) { inOl = false; result.add(''); continue; }
    final liMatch = RegExp(r'<li[^>]*>([\s\S]*?)</li>').firstMatch(t);
    if (liMatch != null) {
      final content = _stripTags(liMatch[1]!).trim();
      if (inOl) {
        olCounter++;
        result.add('$olCounter. $content');
      } else {
        result.add('• $content');
      }
      continue;
    }
    result.add(line);
  }
  text = result.join('\n');

  // strong / bold
  text = text.replaceAllMapped(RegExp(r'<strong[^>]*>([\s\S]*?)</strong>'), (m) => '**${m[1]}**');
  text = text.replaceAllMapped(RegExp(r'<b[^>]*>([\s\S]*?)</b>'), (m) => '**${m[1]}**');

  // em / italic
  text = text.replaceAllMapped(RegExp(r'<em[^>]*>([\s\S]*?)</em>'), (m) => '*${m[1]}*');
  text = text.replaceAllMapped(RegExp(r'<i[^>]*>([\s\S]*?)</i>'), (m) => '*${m[1]}*');

  // underline
  text = text.replaceAllMapped(RegExp(r'<u[^>]*>([\s\S]*?)</u>'), (m) => '<u>${m[1]}</u>');

  // code
  text = text.replaceAllMapped(RegExp(r'<code[^>]*>([\s\S]*?)</code>'), (m) => '`${_stripTags(m[1]!)}`');

  // links - href with double quotes
  text = text.replaceAllMapped(RegExp(r'<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>'), (m) => '[${_stripTags(m[2]!)}](${m[1]})');
  // links - href with single quotes
  text = text.replaceAllMapped(RegExp(r"<a[^>]*href='([^']*)'[^>]*>([\s\S]*?)</a>"), (m) => '[${_stripTags(m[2]!)}](${m[1]})');

  // p tags → plain text with newlines
  text = text.replaceAllMapped(RegExp(r'<p[^>]*>([\s\S]*?)</p>'), (m) => '${m[1]}\n');

  // br
  text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');

  // remove remaining tags
  text = _stripTags(text);

  // decode HTML entities
  text = text.replaceAll('&amp;', '&');
  text = text.replaceAll('&lt;', '<');
  text = text.replaceAll('&gt;', '>');
  text = text.replaceAll('&quot;', '"');
  text = text.replaceAll('&#39;', "'");
  text = text.replaceAll('&nbsp;', ' ');

  // clean up excessive blank lines
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}

String _stripTags(String html) {
  return html.replaceAll(RegExp(r'<[^>]+>'), '');
}

/// تحويل Markdown إلى HTML لعرضه بشكل صحيح في flutter_html
String markdownToHtml(String markdown) {
  if (markdown.trim().isEmpty) return '';

  // إذا كان المحتوى يبدو بالفعل HTML، أعده كما هو
  if (markdown.trimLeft().startsWith('<') && markdown.contains('>')) {
    return markdown;
  }

  String html = markdown;

  // ── 1. escape HTML entities الخاصة (قبل أي شيء) ──
  html = html.replaceAll('&', '&amp;');
  // لا نعالج < و > لأن المستخدم قد يكون كتب وسوم <u> يدوياً
  // لذا نُعيد & فقط

  // ── 0. معالجة وسوم المحاذاة <div align="..."> التي يضيفها المحرر ──
  html = html.replaceAllMapped(
    RegExp(r'<div align="([^"]+)">(.*?)</div>', dotAll: true),
    (m) => '<div style="text-align:${m[1]}">${m[2]}</div>',
  );

  // ── 2. العناوين ##, ###, # ──
  html = html.replaceAllMapped(
    RegExp(r'^### (.+)$', multiLine: true),
    (m) => '<h3 dir="rtl">${m[1]}</h3>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^## (.+)$', multiLine: true),
    (m) => '<h2 dir="rtl">${m[1]}</h2>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^# (.+)$', multiLine: true),
    (m) => '<h1 dir="rtl">${m[1]}</h1>',
  );

  // ── 3. خط أفقي --- ──
  html = html.replaceAll(RegExp(r'^---$', multiLine: true), '<hr/>');

  // ── 4. اقتباس > ──
  html = html.replaceAllMapped(
    RegExp(r'^> (.+)$', multiLine: true),
    (m) => '<blockquote dir="rtl">${m[1]}</blockquote>',
  );

  // ── 5. قائمة مرقمة 1. ──
  final numberedLines = <String>[];
  bool inOl = false;
  for (final line in html.split('\n')) {
    final match = RegExp(r'^\d+\. (.+)$').firstMatch(line);
    if (match != null) {
      if (!inOl) { numberedLines.add('<ol dir="rtl">'); inOl = true; }
      numberedLines.add('<li>${match[1]}</li>');
    } else {
      if (inOl) { numberedLines.add('</ol>'); inOl = false; }
      numberedLines.add(line);
    }
  }
  if (inOl) numberedLines.add('</ol>');
  html = numberedLines.join('\n');

  // ── 6. قائمة نقطية • أو - ──
  final bulletLines = <String>[];
  bool inUl = false;
  for (final line in html.split('\n')) {
    final match = RegExp(r'^[•\-\*] (.+)$').firstMatch(line);
    if (match != null) {
      if (!inUl) { bulletLines.add('<ul dir="rtl">'); inUl = true; }
      bulletLines.add('<li>${match[1]}</li>');
    } else {
      if (inUl) { bulletLines.add('</ul>'); inUl = false; }
      bulletLines.add(line);
    }
  }
  if (inUl) bulletLines.add('</ul>');
  html = bulletLines.join('\n');

  // ── 7. Bold & Italic مجتمعان ***نص*** ──
  html = html.replaceAllMapped(
    RegExp(r'\*\*\*(.+?)\*\*\*'),
    (m) => '<strong><em>${m[1]}</em></strong>',
  );

  // ── 8. Bold **نص** ──
  html = html.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (m) => '<strong>${m[1]}</strong>',
  );

  // ── 9. Italic *نص* ──
  html = html.replaceAllMapped(
    RegExp(r'\*(.+?)\*'),
    (m) => '<em>${m[1]}</em>',
  );

  // ── 10. Inline code `نص` ──
  html = html.replaceAllMapped(
    RegExp(r'`(.+?)`'),
    (m) => '<code>${m[1]}</code>',
  );

  // ── 11. رابط [نص](url) ──
  html = html.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => '<a href="${m[2]}">${m[1]}</a>',
  );

  // ── 12. أسطر فارغة → فقرات جديدة ──
  // نقسم الأسطر ونجمعها في فقرات
  final lines = html.split('\n');
  final paragraphs = <String>[];
  final buffer = StringBuffer();

  for (final line in lines) {
    final trimmed = line.trim();
    // السطور التي تبدأ بوسم HTML بلوك نتركها كما هي
    final isBlock = trimmed.startsWith('<h') ||
        trimmed.startsWith('<hr') ||
        trimmed.startsWith('<ol') ||
        trimmed.startsWith('</ol') ||
        trimmed.startsWith('<ul') ||
        trimmed.startsWith('</ul') ||
        trimmed.startsWith('<li') ||
        trimmed.startsWith('<blockquote') ||
        trimmed.startsWith('</blockquote');

    if (isBlock) {
      if (buffer.isNotEmpty) {
        paragraphs.add('<p dir="rtl">${buffer.toString().trim()}</p>');
        buffer.clear();
      }
      paragraphs.add(trimmed);
    } else if (trimmed.isEmpty) {
      if (buffer.isNotEmpty) {
        paragraphs.add('<p dir="rtl">${buffer.toString().trim()}</p>');
        buffer.clear();
      }
    } else {
      if (buffer.isNotEmpty) buffer.write('<br/>');
      buffer.write(trimmed);
    }
  }
  if (buffer.isNotEmpty) {
    paragraphs.add('<p dir="rtl">${buffer.toString().trim()}</p>');
  }

  return paragraphs.join('\n');
}

const String _viewedPostsStorageKey = 'viewed_posts';

Future<List<PostItem>> fetchPosts() async {
  final response =
      await http.get(Uri.parse('https://scrptaty.com/posts/get_posts.php'));

  if (response.statusCode != 200) {
    throw Exception('Failed to load posts: ${response.statusCode}');
  }

  final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

  final List<dynamic> rawPosts;
  if (decoded is List) {
    rawPosts = decoded;
  } else if (decoded is Map<String, dynamic>) {
    final dynamic nestedPosts =
        decoded['posts'] ?? decoded['data'] ?? decoded['value'];
    if (nestedPosts is List) {
      rawPosts = nestedPosts;
    } else {
      rawPosts = [decoded];
    }
  } else {
    throw Exception('Unexpected posts response');
  }

  return rawPosts
      .whereType<Map>()
      .map((item) => PostItem.fromJson(Map<String, dynamic>.from(item)))
      .where((post) =>
          post.title.isNotEmpty ||
          post.description.isNotEmpty ||
          post.imageUrl.isNotEmpty)
      .toList();
}

Future<List<PostItem>> loadViewedPosts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_viewedPostsStorageKey);
    if (saved == null || saved.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(saved);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => PostItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> markPostAsViewed(PostItem post) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_viewedPostsStorageKey);
    final currentPosts = <PostItem>[];

    if (saved != null && saved.isNotEmpty) {
      final decoded = jsonDecode(saved);
      if (decoded is List) {
        currentPosts.addAll(decoded
            .whereType<Map>()
            .map((item) => PostItem.fromJson(Map<String, dynamic>.from(item))));
      }
    }

    final updatedPosts = [post, ...currentPosts.where((item) => item.id != post.id)];
    final trimmedPosts = updatedPosts.length > 50
        ? updatedPosts.sublist(0, 50)
        : updatedPosts;

    await prefs.setString(
      _viewedPostsStorageKey,
      jsonEncode(trimmedPosts.map((item) => item.toJson()).toList()),
    );
  } catch (_) {
    // Ignore cache write failures.
  }
}

class PostNotificationMonitor {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastSeenPostIdKey = 'last_seen_post_id';
  static const Duration _checkInterval = Duration(minutes: 2);

  static Timer? _timer;
  static bool _isChecking = false;

  static Future<void> start() async {
    if (kIsWeb) return;

    _timer?.cancel();
    await checkNow();
    _timer = Timer.periodic(_checkInterval, (_) {
      checkNow();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> markLatestPostAsSeen() async {
    try {
      final posts = await fetchPosts();
      if (posts.isEmpty) return;

      final sortedPosts = List<PostItem>.from(posts)..sort(_comparePosts);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenPostIdKey, sortedPosts.first.id);
    } catch (_) {}
  }

  static Future<void> checkNow() async {
    if (_isChecking || kIsWeb) return;
    _isChecking = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool(_notificationsEnabledKey) ?? false;
      final posts = await fetchPosts();

      if (posts.isEmpty) return;

      final sortedPosts = List<PostItem>.from(posts)..sort(_comparePosts);
      final latestPostId = sortedPosts.first.id;
      final lastSeenPostId = prefs.getString(_lastSeenPostIdKey);

      if (!notificationsEnabled) {
        await prefs.setString(_lastSeenPostIdKey, latestPostId);
        return;
      }

      if (lastSeenPostId == null || lastSeenPostId.isEmpty) {
        await prefs.setString(_lastSeenPostIdKey, latestPostId);
        return;
      }

      if (lastSeenPostId == latestPostId) {
        return;
      }

      final unseenPosts = <PostItem>[];
      for (final post in sortedPosts) {
        if (post.id == lastSeenPostId) {
          break;
        }
        unseenPosts.add(post);
      }

      if (unseenPosts.isEmpty) {
        await prefs.setString(_lastSeenPostIdKey, latestPostId);
        return;
      }

      for (final post in unseenPosts.reversed) {
        await NotificationService.showPostNotification(post);
      }

      await prefs.setString(_lastSeenPostIdKey, latestPostId);
    } catch (_) {
    } finally {
      _isChecking = false;
    }
  }

  static int _comparePosts(PostItem a, PostItem b) {
    final aId = int.tryParse(a.id) ?? 0;
    final bId = int.tryParse(b.id) ?? 0;
    return bId.compareTo(aId);
  }
}

// ============================================================
// 🔍 صفحة البحث المخصصة - نص عربي من اليمين
// ============================================================
class _CustomSearchPage extends StatefulWidget {
  final List<PostItem> posts;
  final bool isDark;
  const _CustomSearchPage({required this.posts, required this.isDark});

  @override
  State<_CustomSearchPage> createState() => _CustomSearchPageState();
}

class _CustomSearchPageState extends State<_CustomSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<PostItem> _results = [];
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _results = widget.posts.take(10).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() {
      _hasQuery = query.isNotEmpty;
      if (query.isEmpty) {
        _results = widget.posts.take(10).toList();
      } else {
        _results = widget.posts.where((p) =>
          p.title.toLowerCase().contains(query.toLowerCase()) ||
          p.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
          automaticallyImplyLeading: false,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.red),
          ),
          title: TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'البحث في المنشورات...',
              hintStyle: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              hintTextDirection: TextDirection.rtl,
              border: InputBorder.none,
              suffixIcon: _hasQuery
                  ? IconButton(
                      icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black45),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    )
                  : Icon(Icons.search, color: Colors.red),
            ),
            cursorColor: Colors.red,
            onChanged: _onChanged,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _results.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: isDark ? Colors.white30 : Colors.black26),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final post = _results[index];
                  return ListTile(
                    leading: post.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.encodedImageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          )
                        : null,
                    title: Text(
                      post.title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: post.description.isNotEmpty
                        ? Text(
                            stripHtmlTags(post.description),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            textAlign: TextAlign.right,
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        _LeftToRightPageRoute(page: _SwipeableLeftToRightPage(child: PostDetailsPage(post: post, isDark: isDark))),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class PostSearchDelegate extends SearchDelegate<String> {
  final List<PostItem> posts;
  final bool isDark;

  PostSearchDelegate({required this.posts, required this.isDark});

  @override
  String get searchFieldLabel => 'البحث في المنشورات...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = super.appBarTheme(context);
    // لجعل النص العربي يبدأ من اليمين نستخدم textDirection RTL في الـ theme
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF111111) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        alignLabelWithHint: true,
      ),
      // هذا هو المفتاح: تعيين اتجاه النص RTL في الـ theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.red,
        selectionColor: Colors.red.withOpacity(0.3),
        selectionHandleColor: Colors.red,
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  PreferredSizeWidget buildBottom(BuildContext context) {
    return PreferredSize(preferredSize: Size.zero, child: SizedBox.shrink());
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = posts.where((post) =>
        post.title.toLowerCase().contains(query.toLowerCase()) ||
        post.description.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(height: 16),
              Text(
                'لا توجد نتائج للبحث',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        itemBuilder: (context, index) {
          final post = results[index];
          return ListTile(
            leading: post.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.encodedImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  )
                : null,
            title: Text(
              post.title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: post.description.isNotEmpty
                ? Text(
                    stripHtmlTags(post.description),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.right,
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                _LeftToRightPageRoute(page: _SwipeableLeftToRightPage(child: PostDetailsPage(post: post, isDark: isDark))),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = posts.where((post) =>
        post.title.toLowerCase().contains(query.toLowerCase())).toList();

    if (suggestions.isEmpty && query.isEmpty) {
      // Show all posts as suggestions when query is empty
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'المقترحات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: posts.length > 10 ? 10 : posts.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return ListTile(
                    leading: post.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.encodedImageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          )
                        : null,
                    title: Text(
                      post.title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      query = post.title;
                      showResults(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'المقترحات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final post = suggestions[index];
                return ListTile(
                  leading: post.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.encodedImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        )
                      : null,
                  title: Text(
                    post.title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    query = post.title;
                    showResults(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final User? currentUser;
  final Function(VoidCallback)? onRegisterScrollCallback;

  const HomePage({
    required this.isDark, 
    required this.onToggle,
    this.currentUser,
    this.onRegisterScrollCallback,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late Future<List<PostItem>> _postsFuture;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _experienceController;
  late final Animation<double> _experienceRotation;
  bool _isOfflineFallback = false;

  @override
  void initState() {
    super.initState();
    // Register scroll callback with parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onRegisterScrollCallback != null) {
        widget.onRegisterScrollCallback!(() {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
    
    _postsFuture = _loadPosts();
    _experienceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _experienceRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _experienceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<List<PostItem>> _loadPosts() async {
    try {
      final posts = await fetchPosts();
      if (mounted) {
        setState(() {
          _isOfflineFallback = false;
        });
      }
      return posts;
    } catch (_) {
      final fallbackPosts = await loadViewedPosts();
      if (fallbackPosts.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isOfflineFallback = true;
          });
        }
        return fallbackPosts;
      }
      rethrow;
    }
  }

  Future<void> _refreshPosts() async {
    final future = _loadPosts();
    if (mounted) {
      setState(() {
        _postsFuture = future;
      });
    }
    try {
      await future;
    } catch (_) {
      // Ignore refresh failures while preserving existing state.
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _showUserPopup(BuildContext context) {
    final isDark = widget.isDark;
    final user = widget.currentUser;
    final RenderBox appBarBox = context.findRenderObject() as RenderBox;
    final Size screenSize = MediaQuery.of(context).size;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Stack(
          children: [
            // خلفية شفافة للإغلاق عند النقر
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(color: Colors.transparent),
              ),
            ),
            // البطاقة
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
              left: 12,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  ),
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // السهم المثلث على يسار المستطيل
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: CustomPaint(
                          size: const Size(16, 10),
                          painter: _TrianglePainter(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          ),
                        ),
                      ),
                      // المستطيل
                      Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                            width: 0.5,
                          ),
                        ),
                        child: user != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user.photoURL != null
                                        ? NetworkImage(user.photoURL!)
                                        : null,
                                    backgroundColor: isDark ? Colors.white12 : Colors.red.shade50,
                                    child: user.photoURL == null
                                        ? const Icon(Icons.person, color: Colors.red, size: 28)
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    user.displayName ?? 'مستخدم',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email ?? '',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 0.5),
                                    ),
                                    child: const Text(
                                      'مسجل دخول بنجاح ✓',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_circle_outlined,
                                    size: 44,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'غير مسجل دخول',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(builder: (_) => SettingsPage(
                                            isDark: widget.isDark,
                                            onToggle: widget.onToggle,
                                            highlightLogin: true),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'اذهب إلى الإعدادات',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = widget.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
        appBar: AppBar(
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color.fromARGB(255, 223, 6, 24)),
          ),
          backgroundColor: isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
          title: Row(
            children: [
              Transform.translate(
                offset: const Offset(0, -2),
                child: ColorFiltered(
                  colorFilter: isDark
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                  child: Image.asset(
                    "assets/images/logo.gif",
                    height: 35,
                    errorBuilder: (c, e, s) {
                      return const Icon(Icons.image_not_supported);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "سكربتاتي",
                style: TextStyle(
                  fontFamily: "Tajawal",
                  fontSize: 24,
                  color: isDark ? Colors.white : Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.red),
              onPressed: () async {
                final posts = await _postsFuture;
                Navigator.push(
                  context,
                  _LeftToRightPageRoute(page: _SwipeableLeftToRightPage(child: _CustomSearchPage(posts: posts, isDark: isDark))),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                // إظهار popup بمعلومات المستخدم
                _showUserPopup(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.currentUser?.photoURL != null
                      ? NetworkImage(widget.currentUser!.photoURL!)
                      : null,
                  child: widget.currentUser?.photoURL == null
                      ? Icon(
                          Icons.account_circle,
                          color: isDark ? Colors.white : Colors.black,
                          size: 36,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: Colors.red,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          child: SingleChildScrollView(
            key: const PageStorageKey('home_scroll_position'),
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          "assets/images/ghlaf.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color.fromARGB(209, 240, 3, 3),
                                const Color.fromARGB(204, 168, 19, 31).withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/logo.png",
                            height: 60,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "سكربتاتي",
                            style: TextStyle(
                              fontFamily: "Tajawal",
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Text(
                              "مجموعة من المشاريع والسكربتات المميزة",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  color: isDark ? const Color.fromARGB(255, 34, 34, 34) : Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        _card(context, Icons.storage, " السكربتات \n والقوالب", HostingPage(), isDark),
                        _card(context, Icons.shopping_cart, "متاجر\nالكترونية", StorePage(), isDark),
                        _card(context, Icons.phone_android, "تطبيقات\nالموبايل", AppsPage(), isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color.fromARGB(0, 255, 255, 255) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'لماذا تختار سكربتاتي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color.fromARGB(255, 221, 43, 43),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'نقدم لعملائنا مجموعة متنوعة من المزايا التي تجعلنا الخيار الأمثل لتنفيذ مشاريعهم التقنية. نحن نجمع بين الخبرة والإبداع والتقنيات المتطورة لتقديم حلول مبتكرة تلبي احتياجات عملائنا.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          height: 1.7,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFeatureItem(
                        'تطوير تطبيقات مخصصة باحدث التقنيات',
                        isDark,
                      ),
                      _buildFeatureItem(
                        'تصميم مواقع احترافية',
                        isDark,
                      ),
                      _buildFeatureItem(
                        'برمجة المنصات المتقدمة',
                        isDark,
                      ),
                      _buildFeatureItem(
                        'حلول مشاكل برمجية',
                        isDark,
                      ),
                      _buildFeatureItem(
                        'الامن العالي والخدمة المميزة',
                        isDark,
                      ),
                      _buildFeatureItem(
                        'انجازات فترة قصيرة',
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color.fromARGB(3, 255, 255, 255) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          child: ClipOval(
                            child: ClickableImage(
                              imagePath: "assets/images/profile.png",
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "محمد السراي",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "مطور ويب محترف مع خبرة في تطوير المواقع والتطبيقات.",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── كرت الموقع الأخضر ──
                GestureDetector(
                  onTap: () => openInAppBrowser(
                    context,
                    'https://www.scrptaty.com',
                    title: 'سكربتاتي',
                    isDark: isDark,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B8A4C), Color(0xFF25D366), Color(0xFF128C50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة الكرة الأرضية
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // النص
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'WWW.SCRPTATY.COM',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'زيارة الموقع الرسمي',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // سهم
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    if (await Vibration.hasVibrator() ?? false) {
                      Vibration.vibrate(duration: 50);
                    }
                    _experienceController.forward(from: 0);
                  },
                  child: AnimatedBuilder(
                    animation: _experienceRotation,
                    builder: (context, child) {
                      final rotationAngle = math.sin(_experienceRotation.value * 2 * math.pi) * (10 * math.pi / 180);
                      return Transform.rotate(
                        angle: rotationAngle,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                      decoration: BoxDecoration(
                        color: isDark ? const Color.fromARGB(255, 218, 36, 36) : const Color.fromARGB(255, 221, 49, 49),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color.fromARGB(255, 177, 125, 125) : const Color.fromARGB(31, 255, 255, 255),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color.fromARGB(0, 0, 0, 0) : const Color.fromARGB(0, 158, 158, 158).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '+15',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 241, 241, 241),
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            'سنوات من الخبرة في التصميم',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                              color: isDark ? Colors.white70 : const Color.fromARGB(221, 223, 222, 222),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "أحدث المنشورات",
                      style: TextStyle(
                        fontFamily: "Tajawal",
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isOfflineFallback)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'لا يوجد اتصال. يتم عرض المنشورات بدون انترنيت .',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                FutureBuilder<List<PostItem>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildPostsMessage(
                        message: "تعذر تحميل المنشورات حالياً.",
                        icon: Icons.cloud_off_rounded,
                      );
                    }

                    final posts = snapshot.data ?? const <PostItem>[];
                    if (posts.isEmpty) {
                      return _buildPostsMessage(
                        message: "لا توجد منشورات حالياً.",
                        icon: Icons.article_outlined,
                      );
                    }

                    return Column(
                      children: _buildPostCards(context, posts),
                    );
                  },
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsMessage({
    required String message,
    required IconData icon,
  }) {
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.red, size: 38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPostCards(BuildContext context, List<PostItem> posts) {
    final isDark = widget.isDark;

    return List<Widget>.generate(
      posts.length * 2 - 1,
      (index) {
        if (index.isEven) {
          final post = posts[index ~/ 2];
          return _buildPostCard(context, post);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Divider(
            height: 2,
            thickness: 0.5,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostItem post) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: () {
        markPostAsViewed(post);
        Navigator.push(
          context,
          _LeftToRightPageRoute(page: _SwipeableLeftToRightPage(child: PostDetailsPage(post: post, isDark: isDark))),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.imageUrl.isNotEmpty)
              SizedBox(
                height: 220,
                child: Image.network(
                  post.encodedImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return Container(
                      color: isDark
                          ? const Color.fromARGB(255, 32, 32, 32)
                          : Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? const Color.fromARGB(255, 32, 32, 32)
                          : Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.red,
                          size: 46,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (post.title.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        post.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (post.title.isNotEmpty && post.description.isNotEmpty)
                    const SizedBox(height: 10),
                  if (post.description.isNotEmpty)
                    _ExpandablePostDescription(
                      post: post,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String text, Widget page,
      bool isDark) {
    return Expanded(
      child: _HoverCard(
        icon: icon,
        text: text,
        page: page,
        isDark: isDark,
      ),
    );
  }
}

class _ExpandablePostDescription extends StatelessWidget {
  final PostItem post;
  final bool isDark;

  const _ExpandablePostDescription({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const int previewLength = 60;
    final plainDescription = stripHtmlTags(post.description)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hasMore = plainDescription.length > previewLength;
    final previewText = hasMore
        ? '${plainDescription.substring(0, previewLength).trim()}...'
        : plainDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          previewText,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            height: 1.7,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        if (hasMore)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                markPostAsViewed(post);
                Navigator.push(
                  context,
                  _LeftToRightPageRoute(page: _SwipeableLeftToRightPage(child: PostDetailsPage(post: post, isDark: isDark))),
                );
              },
              child: const Text(
                'اقرأ المزيد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PostDetailsPage extends StatelessWidget {
  final PostItem post;
  final bool isDark;

  const PostDetailsPage({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
appBar: AppBar(
  backgroundColor:
      isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
  title: Text(
    post.title.isNotEmpty ? post.title : 'تفاصيل المنشور',
    textAlign: TextAlign.right,
    style: TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    ),
  ),
  centerTitle: false, // Added line - ensures text is not centered
  titleTextStyle: TextStyle(
    fontFamily: 'Tajawal',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: isDark ? Colors.white : Colors.black,
  ),
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: Colors.red),
  ),
),
        body: ListView(
          children: [
            if (post.imageUrl.isNotEmpty)
              SizedBox(
                height: 280,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.transparent,
                        transitionDuration: Duration(milliseconds: 100),
                        reverseTransitionDuration: Duration(milliseconds: 100),
                        pageBuilder: (_, __, ___) => NetworkImageViewer(
                          imageUrl: post.encodedImageUrl,
                          downloadFileName: 'post_${post.id}.jpg',
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  child: Image.network(
                    post.encodedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark
                            ? const Color.fromARGB(255, 32, 32, 32)
                            : Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (post.title.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        post.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (post.title.isNotEmpty && post.description.isNotEmpty)
                    const SizedBox(height: 14),
                  if (post.description.isNotEmpty)
                    Html(
                      data: post.description,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontFamily: 'Tajawal',
                          fontSize: FontSize(17),
                          lineHeight: LineHeight.number(1.8),
                          textAlign: TextAlign.right,
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: 8),
                          padding: HtmlPaddings.zero,
                          textAlign: TextAlign.right,
                        ),
                        'h1': Style(
                          color: Colors.red,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: FontSize(24),
                          margin: Margins.only(top: 16, bottom: 8),
                          textAlign: TextAlign.right,
                        ),
                        'h2': Style(
                          color: Colors.red,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: FontSize(20),
                          margin: Margins.only(top: 14, bottom: 6),
                          textAlign: TextAlign.right,
                        ),
                        'h3': Style(
                          color: Colors.red,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: FontSize(18),
                          margin: Margins.only(top: 12, bottom: 4),
                          textAlign: TextAlign.right,
                        ),
                        'strong': Style(fontWeight: FontWeight.bold),
                        'em': Style(fontStyle: FontStyle.italic),
                        'u': Style(textDecoration: TextDecoration.underline),
                        'a': Style(color: Colors.red, textDecoration: TextDecoration.underline),
                        'code': Style(
                          fontFamily: 'monospace',
                          backgroundColor: Colors.red.withOpacity(0.1),
                          color: Colors.red.shade300,
                          fontSize: FontSize(14),
                          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                        ),
                        'blockquote': Style(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontStyle: FontStyle.italic,
                          border: Border(right: BorderSide(color: Colors.red, width: 3)),
                          padding: HtmlPaddings.only(right: 12, top: 4, bottom: 4),
                          margin: Margins.only(right: 0, top: 8, bottom: 8),
                        ),
                        'ul': Style(
                          textAlign: TextAlign.right,
                          margin: Margins.only(right: 16, bottom: 8),
                          padding: HtmlPaddings.zero,
                        ),
                        'ol': Style(
                          textAlign: TextAlign.right,
                          margin: Margins.only(right: 16, bottom: 8),
                          padding: HtmlPaddings.zero,
                        ),
                        'li': Style(
                          textAlign: TextAlign.right,
                          fontFamily: 'Tajawal',
                          fontSize: FontSize(16),
                          lineHeight: LineHeight.number(1.7),
                        ),
                        'hr': Style(
                          border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.3), width: 1)),
                          margin: Margins.symmetric(vertical: 12),
                        ),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url == null || url.isEmpty) return;
                        openInAppBrowser(context, url, isDark: isDark);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  صفحة السكربتات
// ============================================================

// موديل السكربت
class ScriptItem {
  final String id;
  final String title;
  final String imageUrl;

  const ScriptItem({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  String get encodedImageUrl => Uri.encodeFull(imageUrl);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': imageUrl,
  };

  factory ScriptItem.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString().trim() ?? '';
    final resolvedImage = rawImage.isEmpty
        ? ''
        : (rawImage.startsWith('http')
            ? rawImage
            : 'https://scrptaty.com/posts/$rawImage');

    return ScriptItem(
      id: json['id']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      imageUrl: resolvedImage,
    );
  }
}

// موديل التطبيق
class AppItem {
  final String id;
  final String title;
  final String imageUrl;
  final String fileUrl;
  final String fileSize;

  const AppItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.fileUrl,
    this.fileSize = '',
  });

  String get encodedImageUrl => Uri.encodeFull(imageUrl);
  String get encodedFileUrl => Uri.encodeFull(fileUrl);

  /// استخراج صيغة الملف من الرابط (مثل APK, IPA, ZIP)
  String get fileFormat {
    if (fileUrl.isEmpty) return '';
    final ext = fileUrl.split('?').first.split('.').last.toLowerCase();
    return ext.length <= 5 ? ext.toUpperCase() : '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': imageUrl,
    'file': fileUrl,
    'file_size': fileSize,
  };

  factory AppItem.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString().trim() ?? '';
    final resolvedImage = rawImage.isEmpty
        ? ''
        : (rawImage.startsWith('http')
            ? rawImage
            : 'https://scrptaty.com/posts/$rawImage');

    final rawFile = json['file']?.toString().trim() ?? '';
    final resolvedFile = rawFile.isEmpty
        ? ''
        : (rawFile.startsWith('http')
            ? rawFile
            : 'https://scrptaty.com/posts/$rawFile');

    return AppItem(
      id: json['id']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      imageUrl: resolvedImage,
      fileUrl: resolvedFile,
      fileSize: json['file_size']?.toString().trim() ?? '',
    );
  }
}

// ─── مفاتيح الكاش ───
const String _cachedScriptsKey = 'cached_scripts_v1';
const String _cachedAppsKey = 'cached_apps_v1';

// حفظ السكربتات في الكاش
Future<void> _saveScriptsCache(List<ScriptItem> scripts) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedScriptsKey,
      jsonEncode(scripts.map((s) => s.toJson()).toList()),
    );
  } catch (_) {}
}

// قراءة السكربتات من الكاش
Future<List<ScriptItem>> _loadScriptsCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_cachedScriptsKey);
    if (saved == null || saved.isEmpty) return [];
    final decoded = jsonDecode(saved);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => ScriptItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } catch (_) {
    return [];
  }
}

// حفظ التطبيقات في الكاش
Future<void> _saveAppsCache(List<AppItem> apps) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedAppsKey,
      jsonEncode(apps.map((a) => a.toJson()).toList()),
    );
  } catch (_) {}
}

// قراءة التطبيقات من الكاش
Future<List<AppItem>> _loadAppsCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_cachedAppsKey);
    if (saved == null || saved.isEmpty) return [];
    final decoded = jsonDecode(saved);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => AppItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } catch (_) {
    return [];
  }
}

// دالة جلب السكربتات مع دعم الوضع غير المتصل
Future<List<ScriptItem>> fetchScripts() async {
  try {
    final response = await http
        .get(Uri.parse('https://scrptaty.com/posts/get_simple.php'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load scripts: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    final List<dynamic> rawScripts;
    if (decoded is List) {
      rawScripts = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final dynamic nestedScripts =
          decoded['scripts'] ?? decoded['data'] ?? decoded['value'];
      if (nestedScripts is List) {
        rawScripts = nestedScripts;
      } else {
        rawScripts = [decoded];
      }
    } else {
      throw Exception('Unexpected scripts response');
    }

    final scripts = rawScripts
        .whereType<Map>()
        .map((item) => ScriptItem.fromJson(Map<String, dynamic>.from(item)))
        .where((script) => script.title.isNotEmpty || script.imageUrl.isNotEmpty)
        .toList();

    // حفظ في الكاش عند النجاح
    _saveScriptsCache(scripts);
    return scripts;
  } catch (_) {
    // عند فشل الاتصال، نعيد الكاش المحفوظ
    final cached = await _loadScriptsCache();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

// دالة جلب التطبيقات مع دعم الوضع غير المتصل
Future<List<AppItem>> fetchApps() async {
  try {
    final response = await http
        .get(Uri.parse('https://scrptaty.com/posts/get_files.php'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load apps: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    final List<dynamic> rawApps;
    if (decoded is List) {
      rawApps = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final dynamic nestedApps =
          decoded['apps'] ?? decoded['data'] ?? decoded['value'];
      if (nestedApps is List) {
        rawApps = nestedApps;
      } else {
        rawApps = [decoded];
      }
    } else {
      throw Exception('Unexpected apps response');
    }

    final apps = rawApps
        .whereType<Map>()
        .map((item) => AppItem.fromJson(Map<String, dynamic>.from(item)))
        .where((app) => app.title.isNotEmpty || app.imageUrl.isNotEmpty)
        .toList();

    // حفظ في الكاش عند النجاح
    _saveAppsCache(apps);
    return apps;
  } catch (_) {
    // عند فشل الاتصال، نعيد الكاش المحفوظ
    final cached = await _loadAppsCache();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

// دالة تحميل الملف
Future<void> downloadFile(
  String fileUrl,
  String fileName, {
  void Function(double?)? onProgress,
}) async {
  if (kIsWeb) {
    throw UnimplementedError('Web download not implemented yet');
  }

  if (fileUrl.isEmpty) {
    throw Exception('رابط الملف فارغ');
  }

  print('Download started:');
  print('  URL: $fileUrl');
  print('  File: $fileName');

  try {
    // iOS لا يحتاج أي صلاحيات لحفظ الملفات في app-specific directory
    // Android يحتاج صلاحية فقط للمجلدات العامة
    if (!kIsWeb && io.Platform.isAndroid) {
      // Android 13+ نستخدم app-specific directory مباشرة بدون صلاحية
      // Android 12 وما دون نطلب storage permission
      final sdkInt = await _getAndroidSdkVersion();
      if (sdkInt < 33) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          // حتى لو رُفض، سنستخدم app-specific directory
          if (result.isPermanentlyDenied) {
            print('  Storage permanently denied, falling back to app dir');
          }
        }
      }
    }
    // iOS: لا نطلب أي صلاحية - نحفظ مباشرة في app directory

    // تنظيف اسم الملف من الأحرف الخاصة
    String cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (cleanFileName.isEmpty) {
      cleanFileName = 'downloaded_file';
    }

    print('  Clean filename: $cleanFileName');

    final directory = await _getDownloadDirectory();
    final file = io.File('${directory.path}/$cleanFileName');

    await _downloadAndSaveFile(fileUrl, file, onProgress);
  } catch (e) {
    print('Error downloading file: $e');
    rethrow;
  }
}

Future<int> _getAndroidSdkVersion() async {
  try {
    if (!io.Platform.isAndroid) return 0;
    final result = await io.Process.run('getprop', ['ro.build.version.sdk']);
    return int.tryParse(result.stdout.toString().trim()) ?? 30;
  } catch (_) {
    return 30; // افتراضي آمن
  }
}

Future<void> _downloadAndSaveFile(
  String fileUrl,
  io.File file,
  void Function(double?)? onProgress,
) async {
  final uri = Uri.parse(fileUrl);
  final client = http.Client();

  try {
    final request = http.Request('GET', uri);
    print('  Sending request...');
    final streamedResponse = await client.send(request).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('انتهت مهلة التحميل (30 ثانية)');
      },
    );

    print('  Response status: ${streamedResponse.statusCode}');

    if (streamedResponse.statusCode != 200) {
      throw Exception('فشل تحميل الملف: ${streamedResponse.statusCode}');
    }

    final totalBytes = streamedResponse.contentLength;
    print('  Total bytes: $totalBytes');

    final bytes = <int>[];
    var receivedBytes = 0;

    await for (final chunk in streamedResponse.stream) {
      bytes.addAll(chunk);
      receivedBytes += chunk.length;
      if (onProgress != null) {
        onProgress(totalBytes != null && totalBytes > 0
            ? receivedBytes / totalBytes
            : null);
      }
    }

    print('  Received: $receivedBytes bytes');

    if (bytes.isEmpty) {
      throw Exception('الملف المحمّل فارغ');
    }

    // التأكد من وجود المجلد
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await file.writeAsBytes(bytes);
    
    print('  Saved to: ${file.path}');
    print('Download completed successfully!');
  } finally {
    client.close();
  }
}

Future<io.Directory> _getAppSpecificDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  final downloadDir = io.Directory('${appDir.path}/Downloads');
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }
  return downloadDir;
}

Future<io.Directory> _getDownloadDirectory() async {
  // iOS: يجب استخدام getApplicationDocumentsDirectory دائماً بدون أي صلاحيات
  if (io.Platform.isIOS) {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = io.Directory('${appDir.path}/Scrptaty');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  if (io.Platform.isAndroid) {
    // حاول المجلد العام أولاً (يعمل بدون صلاحية على Android 10+)
    try {
      final directory = io.Directory('/storage/emulated/0/Download/Scrptaty');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (_) {
      // fallback إلى app-specific directory
      return _getAppSpecificDirectory();
    }
  }

  if (io.Platform.isWindows) {
    final directory = io.Directory('${io.Directory.current.path}/downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  if (io.Platform.isMacOS || io.Platform.isLinux) {
    final homeDir = io.Platform.environment['HOME'] ?? io.Directory.current.path;
    final directory = io.Directory('$homeDir/Downloads/Scrptaty');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  return _getAppSpecificDirectory();
}

class ScriptsPage extends StatefulWidget {
  final bool isDark;
  const ScriptsPage({required this.isDark});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<List<ScriptItem>> _scriptsFuture;
  late Future<List<AppItem>> _appsFuture;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingFiles = {};
  final ScrollController _scrollController = ScrollController();
  int _visibleAppsCount = 3;
  final List<AnimationController> _appAnimControllers = [];
  final List<Animation<double>> _appFadeAnims = [];
  final List<Animation<Offset>> _appSlideAnims = [];

  @override
  void initState() {
    super.initState();
    _scriptsFuture = fetchScripts();
    _appsFuture = fetchApps();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _appAnimControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _scriptsFuture = fetchScripts();
      _appsFuture = fetchApps();
    });
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _downloadAppFile(AppItem app) async {
    final appId = app.id;
    // استخدم اسم الملف من الرابط مع التأكد من وجود الامتداد
    String fileName = Uri.tryParse(app.fileUrl)?.pathSegments.last ?? '${app.title}.apk';
    if (!fileName.contains('.')) {
      fileName = '$fileName.apk';
    }

    if (app.fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رابط التحميل غير متوفر لـ ${app.title}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _downloadingFiles.add(appId);
      _downloadProgress[appId] = 0.0;
    });

    try {
      await downloadFile(
        app.fileUrl,
        fileName,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress[appId] = progress ?? 0.0;
          });
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحميل ${app.title} بنجاح ✓',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحميل ${app.title}: ${e.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(appId);
          _downloadProgress.remove(appId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor:
              isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            'السكربتات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.red),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.red,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          child: SingleChildScrollView(
            key: const PageStorageKey('scriptsScroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم التطبيقات
                  _buildSectionHeader('التطبيقات', isDark),
                  const SizedBox(height: 16),
                  _buildAppsSection(isDark),
                  
                  const SizedBox(height: 32),
                  
                  // قسم السكربتات
                  _buildSectionHeader('السكربتات', isDark),
                  const SizedBox(height: 16),
                  _buildScriptsSection(isDark),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildScriptsSection(bool isDark) {
    return FutureBuilder<List<ScriptItem>>(
      future: _scriptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorMessage('تعذر تحميل السكربتات');
        }

        final scripts = snapshot.data ?? [];
        if (scripts.isEmpty) {
          return _buildEmptyMessage('لا توجد سكربتات حالياً');
        }

        return Column(
          children: scripts
              .map((script) => _buildFullWidthScriptCard(script, isDark))
              .toList(),
        );
      },
    );
  }

  Widget _buildFullWidthScriptCard(ScriptItem script, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // الصورة - تأخذ عرض كامل
            AspectRatio(
              aspectRatio: 16 / 9,
              child: script.imageUrl.isNotEmpty
                  ? Image.network(
                      script.encodedImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark
                              ? const Color.fromARGB(255, 32, 32, 32)
                              : Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color.fromARGB(255, 32, 32, 32)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: isDark
                          ? const Color.fromARGB(255, 32, 32, 32)
                          : Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 50),
                      ),
                    ),
            ),
            // العنوان - في المنتصف
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                script.title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreApps(int totalApps) {
    final prevCount = _visibleAppsCount;
    final nextCount = (_visibleAppsCount + 3).clamp(0, totalApps);

    // Create animation controllers for newly revealed cards
    for (int i = prevCount; i < nextCount; i++) {
      if (i >= _appAnimControllers.length) {
        final ctrl = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 400 + (i - prevCount) * 80),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

        _appAnimControllers.add(ctrl);
        _appFadeAnims.add(fade);
        _appSlideAnims.add(slide);
      }
    }

    setState(() {
      _visibleAppsCount = nextCount;
    });

    // Start animations with stagger
    for (int i = prevCount; i < nextCount; i++) {
      final delay = (i - prevCount) * 80;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted && i < _appAnimControllers.length) {
          _appAnimControllers[i].forward(from: 0);
        }
      });
    }
  }

  Widget _buildAppsSection(bool isDark) {
    return FutureBuilder<List<AppItem>>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        final hasError = snapshot.hasError;
        final apps = snapshot.data ?? [];

        if (hasError && apps.isEmpty) {
          return _buildErrorMessage('تعذر تحميل التطبيقات');
        }

        if (apps.isEmpty) {
          return _buildEmptyMessage('لا توجد تطبيقات حالياً');
        }

        // Ensure we have enough animation controllers for the initial 3
        while (_appAnimControllers.length < _visibleAppsCount.clamp(0, apps.length)) {
          final i = _appAnimControllers.length;
          final ctrl = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 400),
            value: 1.0, // start completed for initial items
          );
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

          _appAnimControllers.add(ctrl);
          _appFadeAnims.add(fade);
          _appSlideAnims.add(slide);
        }

        final visibleApps = apps.take(_visibleAppsCount).toList();
        final hasMore = _visibleAppsCount < apps.length;

        return Column(
          children: [
            // بانر الوضع غير المتصل
            if (hasError) _buildOfflineBanner(isDark),

            ...visibleApps.asMap().entries.map((entry) {
              final i = entry.key;
              final app = entry.value;

              Widget card = _buildAppCard(app, isDark);

              if (i < _appAnimControllers.length) {
                card = FadeTransition(
                  opacity: _appFadeAnims[i],
                  child: SlideTransition(
                    position: _appSlideAnims[i],
                    child: card,
                  ),
                );
              }

              return card;
            }).toList(),

            if (hasMore) ...[
              const SizedBox(height: 6),
              _buildShowMoreButton(apps.length, isDark),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOfflineBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A00) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لا يوجد اتصال - يتم عرض آخر بيانات محفوظة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: isDark ? Colors.orange[300] : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton(int totalApps, bool isDark) {
    final remaining = totalApps - _visibleAppsCount;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showMoreApps(totalApps),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.6),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.red.withOpacity(0.10),
                      Colors.red.withOpacity(0.04),
                    ]
                  : [
                      Colors.red.withOpacity(0.07),
                      Colors.red.withOpacity(0.02),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.expand_more_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                'اظهار المزيد ($remaining تطبيق)',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScriptCard(ScriptItem script, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: script.imageUrl.isNotEmpty
                ? Image.network(
                    script.encodedImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: isDark
                            ? const Color.fromARGB(255, 32, 32, 32)
                            : Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark
                            ? const Color.fromARGB(255, 32, 32, 32)
                            : Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: isDark
                        ? const Color.fromARGB(255, 32, 32, 32)
                        : Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              script.title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(AppItem app, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // صورة التطبيق
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: app.imageUrl.isNotEmpty
                ? SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.network(
                      app.encodedImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 52,
                          height: 52,
                          color: isDark
                              ? const Color.fromARGB(255, 32, 32, 32)
                              : Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 52,
                          height: 52,
                          color: isDark
                              ? const Color.fromARGB(255, 32, 32, 32)
                              : Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.red,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color.fromARGB(255, 32, 32, 32)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apps, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          // اسم التطبيق + الحجم والصيغة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        app.title,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (app.fileFormat.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app.fileFormat,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                    if (app.fileSize.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        app.fileSize,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // زر التحميل
          if (app.fileUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _downloadingFiles.contains(app.id)
                  ? null
                  : () async {
                      if (await Vibration.hasVibrator() ?? false) {
                        Vibration.vibrate(duration: 50);
                      }
                      await _downloadAppFile(app);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: _downloadingFiles.contains(app.id)
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                        value: _downloadProgress[app.id] != null &&
                                _downloadProgress[app.id]! > 0
                            ? _downloadProgress[app.id]
                            : null,
                      ),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(
                _downloadingFiles.contains(app.id)
                    ? (_downloadProgress[app.id] != null &&
                            _downloadProgress[app.id]! > 0
                        ? 'جارٍ التحميل ${(_downloadProgress[app.id]! * 100).round()}%'
                        : 'جارٍ التحميل...')
                    : 'تحميل',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  صفحة اتصل بنا
// ============================================================
class ContactPage extends StatelessWidget {
  final bool isDark;
  const ContactPage({required this.isDark});

  Future<void> _openLink(BuildContext context, String value, {bool isEmail = false}) async {
    if (isEmail) {
      final Uri uri = Uri(
        scheme: 'mailto',
        path: value,
        query: Uri.encodeFull('subject=تواصل&body=مرحباً'),
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    openInAppBrowser(context, value, isDark: isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            'اتصل بنا',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.red),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage("assets/images/bg-contact.png"),
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              colorFilter: isDark
                  ? null
                  : const ColorFilter.mode(
                      Colors.white,
                      BlendMode.difference,
                    ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: isDark
                    ? const Color.fromARGB(255, 19, 19, 19)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 58, 58, 58),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: const Offset(35, 0),
                            child: ClipOval(
                              child: const ClickableImage(
                                imagePath: "assets/images/profile.png",
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-35, 0),
                            child: ClipOval(
                              child: const ClickableImage(
                                imagePath: "assets/images/icon.png",
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "المطور: محمد السراي",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "مطور تطبيقات Flutter يهتم بتقديم حلول برمجية حديثة مع واجهات استخدام سلسة.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                isDark,
                icon: const Icon(Icons.email, color: Colors.red),
                title: "البريد الإلكتروني",
                subtitle: "info@scrptaty.com",
                onTap: () => _openLink(context, "info@scrptaty.com", isEmail: true),
              ),
              _buildCard(
                isDark,
                icon: const Icon(Icons.language, color: Colors.blue),
                title: "الموقع الإلكتروني",
                subtitle: "https://scrptaty.com",
                onTap: () => _openLink(context, "https://scrptaty.com"),
              ),
              _buildCard(
                isDark,
                icon: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFFEDA77),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                      Color(0xFF515BD4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(
                    FontAwesomeIcons.instagram,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                title: "إنستكرام",
                subtitle: "@Eng.mu7med",
                onTap: () => _openLink(context, "https://instagram.com/Eng.mu7med"),
              ),
              _buildCard(
                isDark,
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                title: "تلكرام",
                subtitle: "@Mooo5",
                onTap: () => _openLink(context, "https://t.me/Mooo5"),
              ),
              _buildCard(
                isDark,
                icon:
                    const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: "واتساب",
                subtitle: "+964 772 653 7514",
                onTap: () => _openLink(context, "https://wa.me/9647726537514"),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    bool isDark, {
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashColor: Colors.red.withOpacity(0.3),
          highlightColor: Colors.red.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color.fromARGB(223, 19, 19, 19)
                  : const Color.fromARGB(160, 255, 255, 255),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color.fromARGB(255, 58, 58, 58),
                width: 0.5,
              ),
            ),
            child: ListTile(
              leading: icon,
              title: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: isDark
                        ? const Color.fromARGB(82, 255, 255, 255)
                        : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Star Rain Overlay - مطر النجوم الاحتفالي
// ============================================================
class _StarParticle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double rotation;
  Color color;

  _StarParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.color,
  });
}

class StarRainOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const StarRainOverlay({Key? key, required this.onFinished}) : super(key: key);

  @override
  State<StarRainOverlay> createState() => _StarRainOverlayState();
}

class _StarRainOverlayState extends State<StarRainOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_StarParticle> _particles = [];
  final math.Random _random = math.Random();

  final List<Color> _colors = [
    Colors.amber,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.white,
    const Color(0xFFFFD700),
    const Color(0xFFFFA500),
  ];

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.y += p.speed;
            p.rotation += 0.05;
            if (p.y > 1.1) {
              p.y = -0.05;
              p.x = _random.nextDouble();
            }
          }
        });
      });

    _controller.repeat();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _controller.stop();
        widget.onFinished();
      }
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 80; i++) {
      _particles.add(_StarParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.004 + _random.nextDouble() * 0.008,
        size: 8 + _random.nextDouble() * 16,
        opacity: 0.6 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * math.pi * 2,
        color: _colors[_random.nextInt(_colors.length)],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarRainPainter(particles: _particles),
        ),
      ),
    );
  }
}

class _StarRainPainter extends CustomPainter {
  final List<_StarParticle> particles;
  _StarRainPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);

      final path = Path();
      final r = p.size / 2;
      for (int i = 0; i < 5; i++) {
        final angle = (i * 4 * math.pi / 5) - math.pi / 2;
        final innerAngle = angle + 2 * math.pi / 10;
        if (i == 0) {
          path.moveTo(r * math.cos(angle), r * math.sin(angle));
        } else {
          path.lineTo(r * math.cos(angle), r * math.sin(angle));
        }
        path.lineTo(
            (r * 0.4) * math.cos(innerAngle), (r * 0.4) * math.sin(innerAngle));
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarRainPainter oldDelegate) => true;
}

// ============================================================
//  صفحة الإعدادات
// ============================================================
class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final bool highlightLogin;
  const SettingsPage({required this.isDark, required this.onToggle, this.highlightLogin = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  bool notificationsEnabled = false;
  bool _isSigningIn = false;
  User? _currentUser;
  bool _showStarRain = false;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? '279825670275-2quhbvdtagv7he8s9juc9dvl6i40bgtc.apps.googleusercontent.com'
        : null,
  );

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );
    // Start highlight animation if coming from profile tap
    if (widget.highlightLogin) {
      _highlightController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _highlightController.reverse();
        });
      });
    }
    _loadNotificationPreference();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

Future<void> _handleGoogleSignIn() async {
  if (_isSigningIn) return;

  setState(() {
    _isSigningIn = true;
  });

  try {
    print('Starting Google Sign-In...');

    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      setState(() {
        _isSigningIn = false;
      });
      return;
    }

    print("Google user: ${googleUser.email}");

    // الحصول على بيانات المصادقة من جوجل
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // إنشاء بيانات اعتماد Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // تسجيل الدخول في Firebase للحصول على بيانات المستخدم الكاملة
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (mounted) {
      setState(() {
        _currentUser = userCredential.user;
        _isSigningIn = false;
      });

      final userName = userCredential.user?.displayName ?? 'بك';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'مرحباً $userName 👋',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
    }

  } catch (e) {
    print("Google Sign-In Error: $e");

    if (mounted) {
      setState(() {
        _isSigningIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدخول'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() {
          _currentUser = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: const Text(
                'تم تسجيل الخروج بنجاح',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 8,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Sign Out Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تسجيل الخروج'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLoginCard() {
    if (_currentUser != null) {
      // User is logged in - show user info card
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة المستخدم الشخصية
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _currentUser!.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    backgroundColor: widget.isDark ? Colors.white12 : Colors.red.shade50,
                    child: _currentUser!.photoURL == null
                        ? const Icon(Icons.person, color: Colors.red, size: 40)
                        : null,
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // اسم المستخدم
            Text(
              _currentUser!.displayName ?? 'مستخدم',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // شارة العضو المميز - قابلة للضغط لتطلق مطر النجوم
            GestureDetector(
              onTap: () {
                setState(() {
                  _showStarRain = true;
                });
              },
              child: Builder(builder: (context) {
                final email = _currentUser?.email ?? '';
                final Color badgeColor1;
                final Color badgeColor2;
                final String badgeText;
                final IconData badgeIcon;

                if (email == 'hmode.qq@gmail.com') {
                  badgeColor1 = const Color(0xFF1B5E20);
                  badgeColor2 = const Color(0xFF4CAF50);
                  badgeText = 'المالك الرسمي لـ سكربتاتي';
                  badgeIcon = Icons.verified_rounded;
                } else if (email == 'hmode.qu@gmail.com') {
                  badgeColor1 = const Color(0xFF0D47A1);
                  badgeColor2 = const Color(0xFF42A5F5);
                  badgeText = 'المشرف لتطبيق سكربتاتي';
                  badgeIcon = Icons.admin_panel_settings_rounded;
                } else {
                  badgeColor1 = Colors.red.shade700;
                  badgeColor2 = Colors.red.shade400;
                  badgeText = 'عضو مميز في سكربتاتي';
                  badgeIcon = Icons.star_rounded;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badgeColor1, badgeColor2],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: Colors.amber, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            // البريد الإلكتروني
            Text(
              _currentUser!.email ?? '',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: widget.isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // زر تسجيل الخروج
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // User is not logged in - show login button
    return _buildCard(
      onTap: _handleGoogleSignIn,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white12 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.login,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سجل دخولك باستخدام حساب جوجل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (_isSigningIn)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 2,
              ),
            )
          else
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.red,
              size: 18,
            ),
        ],
      ),
    );
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _setNotificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!mounted) return;
    setState(() {
      notificationsEnabled = value;
    });
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (!value) {
      PostNotificationMonitor.stop();
      await NotificationService.cancelAll();
      await _setNotificationEnabled(false);
      return;
    }

    // Open system app settings to allow user to enable notifications
    await openAppSettings();

    // Wait a bit and check if permission was granted
    await Future.delayed(const Duration(seconds: 1));

    final granted = await NotificationService.requestPermission();
    await _setNotificationEnabled(granted);

    if (granted && mounted) {
      await PostNotificationMonitor.markLatestPostAsSeen();
      await PostNotificationMonitor.start();
      await NotificationService.showWelcomeNotificationAfterDelay();
    }
  }

  void _openLink(BuildContext context, String value) {
    openInAppBrowser(context, value, isDark: widget.isDark);
  }

  void _showDonationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: [0.3, 0.5, 0.95],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      children: [
                        Text(
                          'التبرع والدعم',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            ' MOHAMMED RAHEEM MOHAMMED',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: 300,
                              height: 190,
                              child: Image.asset(
                                'assets/images/mastercard.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.transparent,
                                    child: Center(
                                      child: Icon(
                                        Icons.credit_card,
                                        size: 0,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'شكراً لدعمك!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تبرعك يساعد في تطوير تطبيقات أفضل ومحتوى عالي الجودة.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: widget.isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'أغلاق ',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── التحقق من صلاحيات المشرف ──
  bool _isAdminUser() {
    final email = _currentUser?.email ?? '';
    return email == 'hmode.qu@gmail.com' || email == 'hmode.qq@gmail.com';
  }

  // ── كرت لوحة التحكم ──
  Widget _buildAdminPanelCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            _LeftToRightPageRoute(
              page: AdminPanelPage(isDark: widget.isDark),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0000),
                const Color(0xFF3D0000),
                const Color(0xFF7B0000),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.red.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // خلفية زخرفية
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.08),
                    ),
                  ),
                ),
                // المحتوى
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'لوحة التحكم',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'مشرف',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'إدارة المنشورات والتعديلات',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.red.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.red.withOpacity(0.2),
          highlightColor: Colors.red.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.isDark
                    ? const Color.fromARGB(120, 255, 255, 255)
                    : const Color.fromARGB(80, 0, 0, 0),
                width: 0.5,
              ),
              boxShadow: [
                if (!widget.isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor:
                widget.isDark ? const Color(0xFF111111) : const Color(0xFFF4F4F4),
            appBar: AppBar(
              backgroundColor:
                  widget.isDark ? const Color(0xFF161616) : Colors.white,
              automaticallyImplyLeading: false,
              title: Text(
                'الإعدادات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: Colors.red),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

              const SizedBox(height: 8),
            
              const SizedBox(height: 24),
              // Login Card
              _buildLoginCard(),
              // ── كرت لوحة التحكم (للمشرفين فقط) ──
              if (_isAdminUser()) _buildAdminPanelCard(),
              _buildCard(
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 42, 42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'سكربتاتي',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'الإصدار 1.0.0',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          widget.isDark ? Colors.white12 : Colors.red.shade50,
                      child: const Icon(
                        Icons.palette,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لون الثيم',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isDark
                                ? 'وضع داكن مفعل'
                                : 'الوضع الفاتح مفعل',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.isDark,
                      onChanged: (_) => widget.onToggle(),
                      activeColor: Colors.red,
                      activeTrackColor: Colors.redAccent.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
              _buildCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          widget.isDark ? Colors.white12 : Colors.red.shade50,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التبرع',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ادعم تطوير التطبيق والمحتوى المستقبلي.',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: const Color.fromARGB(255, 207, 202, 202),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showDonationSheet(context),
                      child: const Text(
                        'تبرع الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: widget.isDark
                          ? Colors.white12
                          : const Color.fromARGB(255, 255, 235, 235),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الإشعارات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notificationsEnabled
                                ? 'تم تفعيل الإشعارات'
                                : 'الإشعارات متوقفة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: _handleNotificationToggle,
                      activeColor: Colors.red,
                      activeTrackColor: Colors.redAccent.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
                    const SizedBox(height: 90),
            ],
          ),
        ),
      ), // end Scaffold
          if (_showStarRain)
            StarRainOverlay(
              onFinished: () {
                if (mounted) setState(() => _showStarRain = false);
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// مرسم المثلث للـ popup
// ============================================================
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}

// ============================================================
// انتقال مخصص: يفتح من اليسار لليمين
// ============================================================
class _LeftToRightPageRoute extends PageRouteBuilder {
  final Widget page;

  _LeftToRightPageRoute({required this.page})
      : super(
          opaque: false, // ضروري: يجعل الصفحة الخلفية مرئية أثناء السحب
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // الصفحة الجديدة تدخل من اليسار (begin -1 → end 0)
            final slideIn = Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

            // الصفحة الخلفية تتحرك لليمين (0 → 0.3) — تعمل تلقائياً عند الإغلاق أيضاً
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.3, 0.0),
            ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic));

            return Stack(
              children: [
                // الصفحة الخلفية تتحرك لليمين
                SlideTransition(
                  position: slideOut,
                  child: const SizedBox.expand(),
                ),
                // الصفحة الجديدة تدخل من اليسار
                SlideTransition(
                  position: slideIn,
                  child: child,
                ),
              ],
            );
          },
        );
}

// ============================================================
//  صفحة الكرت مع دعم السحب من اليمين لليسار للإغلاق
// ============================================================
class _SwipeableLeftToRightPage extends StatefulWidget {
  final Widget child;
  const _SwipeableLeftToRightPage({required this.child});

  @override
  State<_SwipeableLeftToRightPage> createState() => _SwipeableLeftToRightPageState();
}

class _SwipeableLeftToRightPageState extends State<_SwipeableLeftToRightPage>
    with SingleTickerProviderStateMixin {
  // السحب لليسار يُغلق الصفحة مع تحريك الخلفية معها
  // الحل: تحريك الـ route controller مباشرة (animation 1→0 = إغلاق)
  double _dragOffset = 0.0;
  bool _isGesturing = false;
  late AnimationController _snapController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _isGesturing = true;
    _dragOffset = 0.0;
    _snapController.stop();
    // نُبلغ الـ Navigator ببدء gesture يدوي
    Navigator.of(context).didStartUserGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isGesturing) return;
    final screenWidth = MediaQuery.of(context).size.width;
    // dx سالب = سحب لليسار = إغلاق (نقلل قيمة الـ animation)
    // dx موجب = سحب لليمين = فتح (نزيد قيمة الـ animation)
    final route = ModalRoute.of(context);
    if (route?.controller == null) return;

    final delta = -details.delta.dx / screenWidth; // سالب للسحب لليسار
    final newValue = (route!.controller!.value - delta).clamp(0.0, 1.0);
    route.controller!.value = newValue;
    setState(() => _dragOffset = details.delta.dx);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isGesturing) return;
    _isGesturing = false;
    final route = ModalRoute.of(context);
    final velocity = details.primaryVelocity ?? 0;
    final currentValue = route?.controller?.value ?? 1.0;

    // إغلاق: animation أقل من 0.6 أو سرعة عالية لليسار
    if (currentValue < 0.5 || velocity < -800) {
      Navigator.of(context).pop();
    } else {
      // رجوع للوضع الطبيعي (فتح)
      route?.controller?.animateTo(
        1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
    Navigator.of(context).didStopUserGesture();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}

// ============================================================
// 🔥 الكرت مع انتقال من اليسار لليمين
// ============================================================
class _HoverCard extends StatefulWidget {
  final IconData icon;
  final String text;
  final Widget page;
  final bool isDark;

  const _HoverCard({
    required this.icon,
    required this.text,
    required this.page,
    required this.isDark,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            _LeftToRightPageRoute(
              page: _SwipeableLeftToRightPage(child: widget.page),
            ),
          );
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isPressed
                ? Colors.red.withOpacity(0.4)
                : isHovered
                    ? (widget.isDark
                        ? const Color.fromARGB(255, 212, 42, 42)
                            .withOpacity(0.7)
                        : const Color.fromARGB(255, 212, 42, 42)
                            .withOpacity(0.2))
                    : (widget.isDark ? Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: Colors.red),
              SizedBox(height: 10),
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Tajawal",
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// 🛡️ صفحة لوحة التحكم (للمشرفين فقط)
// ============================================================
class AdminPanelPage extends StatefulWidget {
  final bool isDark;
  const AdminPanelPage({Key? key, required this.isDark}) : super(key: key);

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selectedTab = 0; // 0 = النشر, 1 = التعديل

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Column(
              children: [
                // ── البار العلوي ──
                _AdminTopBar(isDark: widget.isDark, onBack: () => Navigator.pop(context)),

                // ── المحتوى ──
                Expanded(
                  child: _selectedTab == 0
                      ? _AdminPublishTab(isDark: widget.isDark)
                      : _AdminEditTab(isDark: widget.isDark),
                ),

                // مساحة للبار الزجاجي السفلي
                const SizedBox(height: 90),
              ],
            ),

            // ── البار الزجاجي السفلي ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AdminGlassNavBar(
                selectedTab: _selectedTab,
                isDark: widget.isDark,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// البار العلوي للوحة التحكم
class _AdminTopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;

  const _AdminTopBar({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // زر الرجوع
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // اللوجو
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // نص لوحة التحكم
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              // شارة المشرف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B0000), Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'مشرف',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// البار الزجاجي السفلي للوحة التحكم
class _AdminGlassNavBar extends StatelessWidget {
  final int selectedTab;
  final bool isDark;
  final ValueChanged<int> onTabChanged;

  const _AdminGlassNavBar({
    required this.selectedTab,
    required this.isDark,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.withOpacity(0.03)
                    : const Color.fromARGB(255, 243, 33, 33).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.black.withOpacity(0.10),
                  width: 0.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / 2;
                  return Stack(
                    children: [
                      // المؤشر المتحرك (معكوس - يذهب للجهة المقابلة)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: (1 - selectedTab) * itemWidth + 5,
                        top: 5,
                        bottom: 5,
                        width: itemWidth - 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                const Color(0xFFFF3333).withOpacity(0.3),
                                const Color(0xFFFF3333).withOpacity(0.12),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFFF3333).withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // الأزرار
                      Row(
                        children: [
                          _AdminNavItem(
                            icon: Icons.publish_rounded,
                            label: 'النشر',
                            isActive: selectedTab == 0,
                            isDark: isDark,
                            onTap: () => onTabChanged(0),
                          ),
                          _AdminNavItem(
                            icon: Icons.edit_rounded,
                            label: 'التعديل',
                            isActive: selectedTab == 1,
                            isDark: isDark,
                            onTap: () => onTabChanged(1),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Colors.red
        : (isDark ? Colors.white.withOpacity(0.7) : Colors.black54);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// ثوابت Admin API
// ────────────────────────────────────────────────────────────
const String _adminBaseUrl = 'https://scrptaty.com/posts';
const String _apiAdd = '$_adminBaseUrl/api_add_post.php';
const String _apiList = '$_adminBaseUrl/api_get_posts.php';
const String _apiEdit = '$_adminBaseUrl/api_edit_post.php';
const String _apiDelete = '$_adminBaseUrl/api_delete_post.php';

// ────────────────────────────────────────────────────────────
// نموذج البيانات
// ────────────────────────────────────────────────────────────
class AdminPost {
  final String id;
  final String title;
  final String description;
  final String image;
  final String file;
  final String type;

  AdminPost({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.file,
    required this.type,
  });

  factory AdminPost.fromJson(Map<String, dynamic> j) => AdminPost(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        image: j['image']?.toString() ?? '',
        file: j['file']?.toString() ?? '',
        type: j['type']?.toString() ?? 'normal',
      );

  String get imageUrl {
    final img = image;
    if (img.isEmpty) return '';
    return img.startsWith('http') ? img : '$_adminBaseUrl/$img';
  }
}

// ────────────────────────────────────────────────────────────
// WYSIWYG محرر النصوص بملء الشاشة
// ────────────────────────────────────────────────────────────

/// بناء RichText من Markdown للعرض المباشر داخل المحرر
List<InlineSpan> _buildRichSpans(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  // نعالج سطراً سطراً
  final lines = text.split('\n');
  for (int li = 0; li < lines.length; li++) {
    if (li > 0) spans.add(const TextSpan(text: '\n'));
    final line = lines[li];

    // عنوان ##
    if (line.startsWith('## ')) {
      spans.add(TextSpan(
        text: line.substring(3),
        style: base.copyWith(fontSize: (base.fontSize ?? 16) * 1.3, fontWeight: FontWeight.bold, color: Colors.red),
      ));
      continue;
    }
    // عنوان #
    if (line.startsWith('# ')) {
      spans.add(TextSpan(
        text: line.substring(2),
        style: base.copyWith(fontSize: (base.fontSize ?? 16) * 1.6, fontWeight: FontWeight.bold, color: Colors.red),
      ));
      continue;
    }
    // اقتباس >
    if (line.startsWith('> ')) {
      spans.add(TextSpan(
        text: '❝ ${line.substring(2)}',
        style: base.copyWith(
          color: (base.color ?? Colors.white).withOpacity(0.55),
          fontStyle: FontStyle.italic,
        ),
      ));
      continue;
    }
    // قائمة نقطية
    if (RegExp(r'^[•\-\*] ').hasMatch(line)) {
      spans.add(TextSpan(
        text: '• ${line.substring(2)}',
        style: base,
      ));
      continue;
    }
    // قائمة مرقمة
    final numMatch = RegExp(r'^\d+\. (.+)$').firstMatch(line);
    if (numMatch != null) {
      spans.add(TextSpan(text: line, style: base));
      continue;
    }
    // سطر عادي - نطبق inline formatting
    spans.addAll(_parseInline(line, base));
  }
  return spans;
}

List<InlineSpan> _parseInline(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  // نمط يتعرف على: ***x***, **x**, *x*, `x`, [label](url), <u>x</u>
  final pattern = RegExp(
    r'\*\*\*(.+?)\*\*\*'
    r'|\*\*(.+?)\*\*'
    r'|\*(.+?)\*'
    r'|`(.+?)`'
    r'|\[([^\]]+)\]\(([^)]+)\)'
    r'|<u>(.+?)</u>',
  );

  int cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
    }
    if (m.group(1) != null) {
      // ***bold+italic***
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
      ));
    } else if (m.group(2) != null) {
      // **bold**
      spans.add(TextSpan(
        text: m.group(2),
        style: base.copyWith(fontWeight: FontWeight.bold),
      ));
    } else if (m.group(3) != null) {
      // *italic*
      spans.add(TextSpan(
        text: m.group(3),
        style: base.copyWith(fontStyle: FontStyle.italic),
      ));
    } else if (m.group(4) != null) {
      // `code`
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFF3B3B), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x55FF3B3B), blurRadius: 6, spreadRadius: 0),
            ],
          ),
          child: Text(
            m.group(4)!,
            style: base.copyWith(
              fontFamily: 'monospace',
              color: const Color(0xFFFF6E6E),
              fontSize: (base.fontSize ?? 16) * 0.88,
              height: 1.4,
            ),
          ),
        ),
      ));
    } else if (m.group(5) != null) {
      // [label](url) - عرض كمربع أحمر جميل كأنه زر
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.red.withOpacity(0.7), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded, size: 13, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 4),
              Text(
                m.group(5)!,
                style: base.copyWith(
                  color: const Color(0xFFFF6B6B),
                  fontSize: (base.fontSize ?? 16) * 0.9,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFFF6B6B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ));
    } else if (m.group(7) != null) {
      // <u>underline</u>
      spans.add(TextSpan(
        text: m.group(7),
        style: base.copyWith(decoration: TextDecoration.underline),
      ));
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  return spans;
}

/// صفحة المحرر الكاملة
class _FullScreenEditorPage extends StatefulWidget {
  final String initialText;
  final bool isDark;
  const _FullScreenEditorPage({required this.initialText, required this.isDark});

  @override
  State<_FullScreenEditorPage> createState() => _FullScreenEditorPageState();
}

class _FullScreenEditorPageState extends State<_FullScreenEditorPage> {
  // المحرر يعمل على markdown داخلياً لكن يعرضه كـ WYSIWYG
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  late ScrollController _scrollCtrl;

  // وضع المعاينة
  bool _previewMode = false;

  // حالة نافذة الرابط المدمجة
  bool _showLinkPanel = false;
  final TextEditingController _linkLabelCtrl = TextEditingController();
  final TextEditingController _linkUrlCtrl = TextEditingController();
  TextSelection? _savedSelection;

  // محاذاة السطر الحالي (يحفظ per-line باستخدام <div align="...">)
  TextAlign _currentLineAlign = TextAlign.right;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _scrollCtrl = ScrollController();
    _ctrl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() => _updateCurrentLineAlign());
  }

  // قراءة محاذاة السطر الحالي من النص
  void _updateCurrentLineAlign() {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    if (!sel.isValid || text.isEmpty) return;
    final pos = sel.start.clamp(0, text.length);
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final lineEnd = text.indexOf('\n', pos);
    final line = text.substring(lineStart, lineEnd < 0 ? text.length : lineEnd);
    if (line.contains('<div align="center">') || line.contains('<div style="text-align:center">')) {
      _currentLineAlign = TextAlign.center;
    } else if (line.contains('<div align="left">') || line.contains('<div style="text-align:left">')) {
      _currentLineAlign = TextAlign.left;
    } else {
      _currentLineAlign = TextAlign.right;
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    _linkLabelCtrl.dispose();
    _linkUrlCtrl.dispose();
    super.dispose();
  }

  // ── تطبيق التنسيق على النص المحدد مع toggle ──
  void _wrapSelection(String before, String after) {
    final sel = _ctrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final text = _ctrl.text;
    final selected = sel.textInside(text);

    // Toggle: إذا كان التنسيق موجوداً أزله
    if (text.substring(sel.start >= before.length ? sel.start - before.length : 0)
        .startsWith(before) || selected.startsWith(before)) {
      // فحص بسيط: هل يوجد التنسيق حول النص المحدد
      final startCheck = sel.start >= before.length
          ? text.substring(sel.start - before.length, sel.start) == before
          : false;
      final endCheck = sel.end + after.length <= text.length
          ? text.substring(sel.end, sel.end + after.length) == after
          : false;
      if (startCheck && endCheck) {
        // إزالة التنسيق
        final newText = text.replaceRange(sel.end, sel.end + after.length, '')
            .replaceRange(sel.start - before.length, sel.start, '');
        _ctrl.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: sel.start - before.length,
            extentOffset: sel.end - before.length,
          ),
        );
        return;
      }
    }

    // إضافة التنسيق
    final newText = text.replaceRange(sel.start, sel.end, '$before$selected$after');
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      ),
    );
  }

  void _insertLinePrefix(String prefix) {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    if (text.substring(lineStart).startsWith(prefix)) {
      final newText = text.replaceRange(lineStart, lineStart + prefix.length, '');
      _ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: (pos - prefix.length).clamp(0, newText.length)),
      );
    } else {
      final newText = text.replaceRange(lineStart, lineStart, prefix);
      _ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    }
  }

  void _insertNumberedListItem() {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final currentLine = text.substring(lineStart, pos);
    final currentMatch = RegExp(r'^(\d+)\. ').firstMatch(currentLine);
    if (currentMatch != null) {
      final prefix = currentMatch.group(0)!;
      final newText = text.replaceRange(lineStart, lineStart + prefix.length, '');
      _ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: (pos - prefix.length).clamp(0, newText.length)),
      );
      return;
    }
    int nextNumber = 1;
    if (lineStart > 0) {
      final prevLineEnd = lineStart - 1;
      final prevLineStart = text.lastIndexOf('\n', prevLineEnd - 1) + 1;
      final prevLine = text.substring(prevLineStart, prevLineEnd);
      final prevMatch = RegExp(r'^(\d+)\. ').firstMatch(prevLine);
      if (prevMatch != null) {
        nextNumber = int.parse(prevMatch.group(1)!) + 1;
      }
    }
    final prefix = '$nextNumber. ';
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
  }

  void _insertHorizontalRule() {
    final pos = _ctrl.selection.isValid ? _ctrl.selection.end : _ctrl.text.length;
    final text = _ctrl.text;
    final insert = '\n---\n';
    final newText = text.replaceRange(pos, pos, insert);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
  }

  // ── فتح لوحة الرابط المدمجة ──
  void _openLinkPanel() {
    final sel = _ctrl.selection;
    // استخراج النص المحدد مع تجاهل التنسيق
    String selectedText = '';
    if (sel.isValid && !sel.isCollapsed) {
      final raw = sel.textInside(_ctrl.text);
      // إزالة رموز markdown لعرض النص فقط
      selectedText = raw
          .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
          .replaceAll(RegExp(r'<u>([^<]+)</u>'), r'$1');
    }
    setState(() {
      _savedSelection = sel.isValid ? sel : null;
      _linkLabelCtrl.text = selectedText;
      _linkUrlCtrl.text = '';
      _showLinkPanel = true;
    });
    _focusNode.unfocus();
  }

  void _closeLinkPanel() {
    setState(() {
      _showLinkPanel = false;
      _linkLabelCtrl.text = '';
      _linkUrlCtrl.text = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _confirmLink() {
    final url = _linkUrlCtrl.text.trim();
    final label = _linkLabelCtrl.text.trim();
    if (url.isNotEmpty) {
      final finalLabel = label.isNotEmpty ? label : url;
      final finalUrl = url.startsWith('http') ? url : 'https://$url';
      final linkText = '[$finalLabel]($finalUrl)';
      final currentText = _ctrl.text;
      final sel = _savedSelection;
      final start = (sel != null && sel.isValid) ? sel.start : currentText.length;
      final end = (sel != null && sel.isValid) ? sel.end : currentText.length;
      final newText = currentText.replaceRange(start, end, linkText);
      _ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + linkText.length),
      );
    }
    _closeLinkPanel();
  }

  // ── محاذاة السطر المحدد فقط ──
  void _applyLineAlignment(TextAlign align) {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final lineEndIdx = text.indexOf('\n', pos);
    final lineEnd = lineEndIdx < 0 ? text.length : lineEndIdx;
    String line = text.substring(lineStart, lineEnd);

    // إزالة أي محاذاة سابقة من السطر
    line = line
        .replaceAll(RegExp(r'<div align="[^"]*">'), '')
        .replaceAll(RegExp(r'</div>'), '')
        .replaceAll(RegExp(r'<div style="text-align:[^"]*">'), '');

    // إضافة المحاذاة الجديدة (يمين = الافتراضي، لا نضيف له وسم)
    String newLine;
    if (align == TextAlign.right) {
      newLine = line; // الافتراضي
    } else if (align == TextAlign.center) {
      newLine = '<div align="center">$line</div>';
    } else {
      newLine = '<div align="left">$line</div>';
    }

    final newText = text.replaceRange(lineStart, lineEnd, newLine);
    final cursorOffset = (pos - lineStart + (newLine.length - line.length)).clamp(lineStart, lineStart + newLine.length);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + (pos - lineStart).clamp(0, newLine.length)),
    );
    setState(() => _currentLineAlign = align);
  }

  void _cycleAlignment() {
    if (_currentLineAlign == TextAlign.right) {
      _applyLineAlignment(TextAlign.center);
    } else if (_currentLineAlign == TextAlign.center) {
      _applyLineAlignment(TextAlign.left);
    } else {
      _applyLineAlignment(TextAlign.right);
    }
  }

  IconData get _alignIcon {
    if (_currentLineAlign == TextAlign.right) return Icons.format_align_right;
    if (_currentLineAlign == TextAlign.center) return Icons.format_align_center;
    return Icons.format_align_left;
  }

  // ── بناء TextSpan للعرض WYSIWYG ──
  // يحوّل markdown إلى TextSpan مباشرة في المحرر
  TextSpan _buildRichSpan(String text, TextStyle base, Color linkColor) {
    final spans = <InlineSpan>[];
    // معالجة سطر بسطر
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      final line = lines[i];
      spans.addAll(_parseLineSpans(line, base, linkColor));
    }
    return TextSpan(children: spans);
  }

  List<InlineSpan> _parseLineSpans(String line, TextStyle base, Color linkColor) {
    // إزالة وسوم المحاذاة من العرض
    String displayLine = line
        .replaceAll(RegExp(r'<div align="[^"]*">'), '')
        .replaceAll(RegExp(r'</div>'), '')
        .replaceAll(RegExp(r'<div style="text-align:[^"]*">'), '');

    // عناوين
    if (displayLine.startsWith('## ')) {
      return [TextSpan(text: displayLine.substring(3), style: base.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red))];
    }
    if (displayLine.startsWith('# ')) {
      return [TextSpan(text: displayLine.substring(2), style: base.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red))];
    }
    if (displayLine.startsWith('### ')) {
      return [TextSpan(text: displayLine.substring(4), style: base.copyWith(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red))];
    }
    // اقتباس
    if (displayLine.startsWith('> ')) {
      return [TextSpan(text: '❝ ${displayLine.substring(2)}', style: base.copyWith(fontStyle: FontStyle.italic, color: base.color?.withOpacity(0.6)))];
    }
    // خط أفقي
    if (displayLine.trim() == '---') {
      return [WidgetSpan(child: Container(height: 1.5, color: Colors.red.withOpacity(0.4), margin: const EdgeInsets.symmetric(vertical: 4)))];
    }
    // قائمة نقطية
    if (displayLine.startsWith('• ')) {
      final rest = _parseInlineSpans(displayLine.substring(2), base, linkColor);
      return [TextSpan(text: '• ', style: base.copyWith(color: Colors.red)), ...rest];
    }
    // قائمة مرقمة
    final numMatch = RegExp(r'^(\d+)\. (.*)').firstMatch(displayLine);
    if (numMatch != null) {
      final rest = _parseInlineSpans(numMatch.group(2)!, base, linkColor);
      return [TextSpan(text: '${numMatch.group(1)}. ', style: base.copyWith(color: Colors.red)), ...rest];
    }

    return _parseInlineSpans(displayLine, base, linkColor);
  }

  List<InlineSpan> _parseInlineSpans(String text, TextStyle base, Color linkColor) {
    final spans = <InlineSpan>[];
    // Regex يجمع كل التنسيقات
    final pattern = RegExp(
      r'\*\*\*(.+?)\*\*\*'         // bold+italic
      r'|\*\*(.+?)\*\*'             // bold
      r'|\*(.+?)\*'                 // italic
      r'|<u>(.+?)</u>'              // underline
      r'|`(.+?)`'                   // code
      r'|\[([^\]]+)\]\(([^)]+)\)',  // link
    );

    int lastEnd = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(fontWeight: FontWeight.bold)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(text: m.group(3), style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base.copyWith(decoration: TextDecoration.underline)));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
          text: m.group(5),
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.red.withOpacity(0.12),
            color: Colors.red.shade300,
          ),
        ));
      } else if (m.group(6) != null && m.group(7) != null) {
        // رابط: نعرض النص فقط بلون أحمر ومسطر
        spans.add(TextSpan(
          text: m.group(6),
          style: base.copyWith(color: linkColor, decoration: TextDecoration.underline),
        ));
      }
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: base));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: base)] : spans;
  }

  // حساب محاذاة السطر الحالي للعرض
  TextAlign _getLineAlign(String line) {
    if (line.contains('<div align="center">') || line.contains('<div style="text-align:center">')) return TextAlign.center;
    if (line.contains('<div align="left">') || line.contains('<div style="text-align:left">')) return TextAlign.left;
    return TextAlign.right;
  }

  Widget _toolbarBtn({required IconData icon, required String tooltip, required VoidCallback onTap, bool active = false}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? Colors.red.withOpacity(0.22)
                : (widget.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? Colors.red.withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: active ? Colors.red : (widget.isDark ? Colors.white70 : Colors.black54)),
        ),
      ),
    );
  }

  // فحص حالة التنسيق على النص المحدد
  bool _isFormatActive(String before, String after) {
    final sel = _ctrl.selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    final text = _ctrl.text;
    final startCheck = sel.start >= before.length
        ? text.substring(sel.start - before.length, sel.start) == before
        : false;
    final endCheck = sel.end + after.length <= text.length
        ? text.substring(sel.end, sel.end + after.length) == after
        : false;
    return startCheck && endCheck;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF111111) : Colors.white;
    final surface = widget.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final linkColor = Colors.red;
    final baseStyle = TextStyle(
      fontFamily: 'Tajawal',
      fontSize: 16,
      height: 1.75,
      color: textColor,
    );

    final isBold = _isFormatActive('**', '**');
    final isItalic = _isFormatActive('*', '*');
    final isUnderline = _isFormatActive('<u>', '</u>');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // ── شريط العنوان ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.22), width: 1)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, _ctrl.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7B1A14), Color(0xFFE53935)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('حفظ', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _previewMode ? 'معاينة المنشور' : 'محرر الوصف',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _previewMode = !_previewMode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: _previewMode
                              ? Colors.red.withOpacity(0.2)
                              : (widget.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _previewMode ? Colors.red.withOpacity(0.5) : Colors.transparent),
                        ),
                        child: Icon(
                          _previewMode ? Icons.edit_rounded : Icons.visibility_rounded,
                          color: _previewMode ? Colors.red : (widget.isDark ? Colors.white54 : Colors.black45),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, null),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.close_rounded, color: widget.isDark ? Colors.white54 : Colors.black45, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // ── شريط الأدوات ──
              if (!_previewMode)
                Container(
                  height: 50,
                  color: widget.isDark ? const Color(0xFF161616) : const Color(0xFFEAEAEA),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        _toolbarBtn(icon: Icons.format_bold, tooltip: 'عريض', active: isBold, onTap: () => _wrapSelection('**', '**')),
                        _toolbarBtn(icon: Icons.format_italic, tooltip: 'مائل', active: isItalic, onTap: () => _wrapSelection('*', '*')),
                        _toolbarBtn(icon: Icons.format_underline, tooltip: 'تحته خط', active: isUnderline, onTap: () => _wrapSelection('<u>', '</u>')),
                        Container(width: 1, height: 26, color: widget.isDark ? Colors.white12 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        _toolbarBtn(icon: Icons.title, tooltip: 'عنوان كبير', onTap: () => _insertLinePrefix('## ')),
                        _toolbarBtn(icon: Icons.format_list_bulleted, tooltip: 'قائمة نقطية', onTap: () => _insertLinePrefix('• ')),
                        _toolbarBtn(icon: Icons.format_list_numbered, tooltip: 'قائمة مرقمة', onTap: _insertNumberedListItem),
                        _toolbarBtn(icon: Icons.format_quote, tooltip: 'اقتباس', onTap: () => _insertLinePrefix('> ')),
                        _toolbarBtn(icon: Icons.horizontal_rule, tooltip: 'فاصل أفقي', onTap: _insertHorizontalRule),
                        Container(width: 1, height: 26, color: widget.isDark ? Colors.white12 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        _toolbarBtn(
                          icon: Icons.link,
                          tooltip: 'رابط',
                          active: _showLinkPanel,
                          onTap: _showLinkPanel ? _closeLinkPanel : _openLinkPanel,
                        ),
                        _toolbarBtn(icon: Icons.code, tooltip: 'كود', onTap: () => _wrapSelection('`', '`')),
                        Container(width: 1, height: 26, color: widget.isDark ? Colors.white12 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        _toolbarBtn(icon: _alignIcon, tooltip: 'محاذاة النص', active: _currentLineAlign != TextAlign.right, onTap: _cycleAlignment),
                      ],
                    ),
                  ),
                ),

              // ── لوحة إدخال الرابط المدمجة ──
              if (!_previewMode && _showLinkPanel)
                Container(
                  color: widget.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text('إضافة رابط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : Colors.black54)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _closeLinkPanel,
                            child: Icon(Icons.close_rounded, size: 18, color: widget.isDark ? Colors.white38 : Colors.black38),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.isDark ? const Color(0xFF111111) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.25)),
                              ),
                              child: TextField(
                                controller: _linkLabelCtrl,
                                textDirection: TextDirection.rtl,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: widget.isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'نص الرابط',
                                  hintStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: widget.isDark ? Colors.white30 : Colors.black38),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.isDark ? const Color(0xFF111111) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.25)),
                              ),
                              child: TextField(
                                controller: _linkUrlCtrl,
                                textDirection: TextDirection.ltr,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: widget.isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'https://...',
                                  hintStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: widget.isDark ? Colors.white30 : Colors.black38),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _confirmLink(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _confirmLink,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7B1A14), Color(0xFFE53935)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('إضافة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── منطقة المحرر أو المعاينة ──
              Expanded(
                child: _previewMode
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: _ctrl.text.trim().isEmpty
                              ? Text(
                                  'لا يوجد محتوى للمعاينة',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: widget.isDark ? Colors.white24 : Colors.black26,
                                    fontSize: 15,
                                  ),
                                )
                              : Html(
                                  data: markdownToHtml(_ctrl.text),
                                  style: {
                                    'body': Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      color: textColor,
                                      fontFamily: 'Tajawal',
                                      fontSize: FontSize(16),
                                      lineHeight: LineHeight.number(1.8),
                                      textAlign: TextAlign.right,
                                    ),
                                    'strong': Style(fontWeight: FontWeight.bold),
                                    'em': Style(fontStyle: FontStyle.italic),
                                    'a': Style(color: Colors.red),
                                    'h1': Style(color: Colors.red, fontFamily: 'Tajawal'),
                                    'h2': Style(color: Colors.red, fontFamily: 'Tajawal'),
                                    'h3': Style(color: Colors.red, fontFamily: 'Tajawal'),
                                    'code': Style(
                                      backgroundColor: const Color(0xFF0D0D0D),
                                      color: const Color(0xFFFF6E6E),
                                      fontFamily: 'monospace',
                                      border: Border.all(color: const Color(0xFFFF3B3B), width: 1.2),
                                      padding: HtmlPaddings.symmetric(horizontal: 7, vertical: 2),
                                    ),
                                    'blockquote': Style(
                                      color: (textColor).withOpacity(0.55),
                                      fontStyle: FontStyle.italic,
                                      border: Border(right: BorderSide(color: Colors.red, width: 3)),
                                      padding: HtmlPaddings.only(right: 12),
                                    ),
                                    'div': Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      fontFamily: 'Tajawal',
                                    ),
                                  },
                                ),
                        ),
                      )
                    // ── وضع التحرير WYSIWYG: يعرض التنسيق مباشرة بدون أكواد ──
                    : _WysiwygEditor(
                        ctrl: _ctrl,
                        focusNode: _focusNode,
                        scrollCtrl: _scrollCtrl,
                        isDark: widget.isDark,
                        baseStyle: baseStyle,
                        currentLineAlign: _currentLineAlign,
                        linkColor: linkColor,
                        buildRichSpan: _buildRichSpan,
                      ),
              ),

              // ── شريط المعلومات السفلي ──
              Container(
                height: 36,
                color: widget.isDark ? const Color(0xFF161616) : const Color(0xFFEAEAEA),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      _previewMode ? Icons.visibility_rounded : Icons.text_fields_rounded,
                      size: 14,
                      color: widget.isDark ? Colors.white30 : Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _ctrl,
                      builder: (_, v, __) => Text(
                        '${v.text.length} حرف  |  ${v.text.split('\n').length} سطر'
                        '${_previewMode ? '  |  معاينة' : ''}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: widget.isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!_previewMode) ...[
                      // مؤشر المحاذاة الحالية
                      Icon(_alignIcon, size: 13, color: Colors.red.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _previewMode = true),
                        child: Text(
                          'معاينة المنشور ←',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── محرر WYSIWYG: يعرض rich text overlay فوق TextField ──
class _WysiwygEditor extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final ScrollController scrollCtrl;
  final bool isDark;
  final TextStyle baseStyle;
  final TextAlign currentLineAlign;
  final Color linkColor;
  final TextSpan Function(String, TextStyle, Color) buildRichSpan;

  const _WysiwygEditor({
    required this.ctrl,
    required this.focusNode,
    required this.scrollCtrl,
    required this.isDark,
    required this.baseStyle,
    required this.currentLineAlign,
    required this.linkColor,
    required this.buildRichSpan,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollCtrl,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollCtrl,
        padding: EdgeInsets.fromLTRB(
          16, 12, 16,
          MediaQuery.of(context).viewInsets.bottom + 80,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (context, value, _) {
              final richSpan = buildRichSpan(value.text, baseStyle, linkColor);
              return Stack(
                children: [
                  // طبقة النص المنسق (WYSIWYG display)
                  IgnorePointer(
                    child: RichText(
                      text: richSpan,
                      textDirection: TextDirection.rtl,
                      textAlign: currentLineAlign,
                    ),
                  ),
                  // طبقة الـ TextField الشفافة للكتابة والتحرير
                  TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textDirection: TextDirection.rtl,
                    textAlign: currentLineAlign,
                    textAlignVertical: TextAlignVertical.top,
                    style: baseStyle.copyWith(color: Colors.transparent),
                    cursorColor: Colors.red,
                    cursorWidth: 2,
                    decoration: InputDecoration(
                      hintText: value.text.isEmpty ? 'اكتب وصف المنشور هنا...' : null,
                      hintStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        color: isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.2),
                        height: 1.75,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// حقل الوصف WYSIWYG - يفتح المحرر الكامل عند الضغط
class _WysiwygDescField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  const _WysiwygDescField({required this.controller, required this.isDark});

  @override
  State<_WysiwygDescField> createState() => _WysiwygDescFieldState();
}

class _WysiwygDescFieldState extends State<_WysiwygDescField> {
  Future<void> _openEditor() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenEditorPage(
          initialText: widget.controller.text,
          isDark: widget.isDark,
        ),
      ),
    );
    if (result != null) {
      widget.controller.text = result;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.controller.text.trim().isEmpty;
    final previewHtml = isEmpty ? '' : markdownToHtml(widget.controller.text);
    return GestureDetector(
      onTap: _openEditor,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF111111) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: isEmpty
                  ? Text(
                      'اضغط للكتابة بملء الشاشة...',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: widget.isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                      ),
                    )
                  : IgnorePointer(
                      child: Html(
                        data: previewHtml,
                        style: {
                          'body': Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color: widget.isDark ? Colors.white70 : Colors.black87,
                            fontFamily: 'Tajawal',
                            fontSize: FontSize(14),
                            lineHeight: LineHeight.number(1.6),
                            textAlign: TextAlign.right,
                          ),
                          'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                          'strong': Style(fontWeight: FontWeight.bold),
                          'em': Style(fontStyle: FontStyle.italic),
                          'a': Style(color: Colors.red),
                          'h1': Style(color: Colors.red, fontFamily: 'Tajawal'),
                          'h2': Style(color: Colors.red, fontFamily: 'Tajawal'),
                          'code': Style(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            color: Colors.red.shade300,
                          ),
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_full_rounded, color: Colors.red.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// تاب النشر
// ────────────────────────────────────────────────────────────
class _AdminPublishTab extends StatefulWidget {
  final bool isDark;
  const _AdminPublishTab({required this.isDark});

  @override
  State<_AdminPublishTab> createState() => _AdminPublishTabState();
}

class _AdminPublishTabState extends State<_AdminPublishTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'normal';
  XFile? _imageFile;
  XFile? _attachFile;
  bool _loading = false;
  String? _msg;
  bool _success = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final f = await p.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) setState(() => _imageFile = f);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          setState(() => _attachFile = XFile(filePath));
        }
      }
    } catch (e) {
      if (mounted) _show('❌ تعذر فتح اختيار الملف', false);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _show('يرجى إدخال العنوان', false);
      return;
    }
    if (_imageFile == null) {
      _show('يرجى اختيار صورة', false);
      return;
    }
    if (_type == 'normal' && _descCtrl.text.trim().isEmpty) {
      _show('يرجى إدخال الوصف', false);
      return;
    }

    setState(() => _loading = true);

    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiAdd));
      req.fields['title'] = _titleCtrl.text.trim();
      req.fields['description'] = _type == 'normal' ? markdownToHtml(_descCtrl.text.trim()) : '';
      req.fields['type'] = _type;
      req.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      if (_type == 'file' && _attachFile != null) {
        req.files.add(await http.MultipartFile.fromPath('file', _attachFile!.path));
      }
      final res = await req.send();
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);
      if (json['success'] == true) {
        _titleCtrl.clear();
        _descCtrl.clear();
        setState(() { _imageFile = null; _attachFile = null; _type = 'normal'; });
        _show('✅ تم النشر بنجاح', true);
      } else {
        _show('❌ ${json['message'] ?? 'حدث خطأ'}', false);
      }
    } catch (e) {
      _show('❌ تعذر الاتصال بالخادم', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg, bool ok) {
    if (!mounted) return;
    setState(() { _msg = msg; _success = ok; });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _msg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_msg != null) ...[
            _AdminStatusBanner(message: _msg!, success: _success, isDark: widget.isDark),
            const SizedBox(height: 14),
          ],
          _AdminSectionCard(
            isDark: widget.isDark,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _AdminFieldLabel('نوع المنشور', Icons.category_rounded, widget.isDark),
              const SizedBox(height: 10),
              _AdminTypeSelector(selected: _type, isDark: widget.isDark, onChanged: (v) => setState(() => _type = v)),
            ]),
          ),
          const SizedBox(height: 14),
          _AdminSectionCard(
            isDark: widget.isDark,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _AdminFieldLabel('العنوان', Icons.title_rounded, widget.isDark),
              const SizedBox(height: 10),
              _AdminTextField(controller: _titleCtrl, hint: 'أدخل عنوان المنشور...', isDark: widget.isDark),
            ]),
          ),
          const SizedBox(height: 14),
          if (_type == 'normal') ...[
            _AdminSectionCard(
              isDark: widget.isDark,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _AdminFieldLabel('الوصف', Icons.notes_rounded, widget.isDark),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.open_in_full_rounded, color: Colors.red.withOpacity(0.5), size: 13),
                  const SizedBox(width: 4),
                  Text('اضغط لفتح المحرر بملء الشاشة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: widget.isDark ? Colors.white30 : Colors.black38)),
                ]),
                const SizedBox(height: 8),
                _WysiwygDescField(controller: _descCtrl, isDark: widget.isDark),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          _AdminSectionCard(
            isDark: widget.isDark,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _AdminFieldLabel('الصورة', Icons.image_rounded, widget.isDark),
              const SizedBox(height: 10),
              _AdminImagePickerBox(file: _imageFile, isDark: widget.isDark, onTap: _pickImage),
            ]),
          ),
          const SizedBox(height: 14),
          if (_type == 'file') ...[
            _AdminSectionCard(
              isDark: widget.isDark,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _AdminFieldLabel('ملف مرفق', Icons.attach_file_rounded, widget.isDark),
                const SizedBox(height: 10),
                _AdminFilePickerBox(file: _attachFile, isDark: widget.isDark, onTap: _pickFile),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          _AdminSubmitButton(label: 'نشر المنشور', icon: Icons.send_rounded, loading: _loading, onTap: _submit),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// تاب التعديل
// ────────────────────────────────────────────────────────────
class _AdminEditTab extends StatefulWidget {
  final bool isDark;
  const _AdminEditTab({required this.isDark});

  @override
  State<_AdminEditTab> createState() => _AdminEditTabState();
}

class _AdminEditTabState extends State<_AdminEditTab> {
  List<AdminPost> _posts = [];
  bool _loading = true;
  String? _msg;
  bool _success = false;

  AdminPost? _editing;
  final _editTitleCtrl = TextEditingController();
  final _editDescCtrl = TextEditingController();
  String _editType = 'normal';
  XFile? _editImageFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _editTitleCtrl.dispose();
    _editDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(_apiList));
      final list = jsonDecode(res.body) as List;
      setState(() {
        _posts = list.map((e) => AdminPost.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      _show('تعذر تحميل المنشورات', false);
    }
  }

  void _startEdit(AdminPost post) {
    _editTitleCtrl.text = post.title;
    // تحويل HTML إلى Markdown لعرضه بشكل صحيح في المحرر
    _editDescCtrl.text = htmlToMarkdown(post.description);
    _editType = post.type;
    _editImageFile = null;
    setState(() => _editing = post);
  }

  void _cancelEdit() => setState(() => _editing = null);

  Future<void> _saveEdit() async {
    if (_editTitleCtrl.text.trim().isEmpty) { _show('يرجى إدخال العنوان', false); return; }
    setState(() => _saving = true);
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiEdit));
      req.fields['post_id'] = _editing!.id;
      req.fields['title'] = _editTitleCtrl.text.trim();
      req.fields['description'] = _editType == 'normal' ? markdownToHtml(_editDescCtrl.text.trim()) : '';
      req.fields['type'] = _editType;
      if (_editImageFile != null) {
        req.files.add(await http.MultipartFile.fromPath('image', _editImageFile!.path));
      }
      final res = await req.send();
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);
      if (json['success'] == true) {
        // تحديث المنشور محلياً بدون إعادة تحميل الصفحة
        final updatedPost = AdminPost(
          id: _editing!.id,
          title: _editTitleCtrl.text.trim(),
          description: _editType == 'normal' ? markdownToHtml(_editDescCtrl.text.trim()) : '',
          image: _editImageFile != null
              ? (json['image']?.toString() ?? _editing!.image)
              : _editing!.image,
          file: _editing!.file,
          type: _editType,
        );
        setState(() {
          final idx = _posts.indexWhere((p) => p.id == _editing!.id);
          if (idx != -1) _posts[idx] = updatedPost;
          _editing = null;
        });
        _show('✅ تم التعديل بنجاح', true);
      } else {
        _show('❌ ${json['message'] ?? 'حدث خطأ'}', false);
      }
    } catch (_) {
      _show('❌ تعذر الاتصال بالخادم', false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePost(AdminPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminConfirmDialog(isDark: widget.isDark, title: post.title),
    );
    if (confirmed != true) return;
    try {
      final res = await http.post(Uri.parse(_apiDelete), body: {'post_id': post.id});
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        // حذف المنشور محلياً بدون إعادة تحميل الصفحة
        setState(() => _posts.removeWhere((p) => p.id == post.id));
        _show('🗑️ تم الحذف بنجاح', true);
      } else {
        _show('❌ فشل الحذف', false);
      }
    } catch (_) {
      _show('❌ تعذر الاتصال بالخادم', false);
    }
  }

  void _show(String msg, bool ok) {
    if (!mounted) return;
    setState(() { _msg = msg; _success = ok; });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _msg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: _fetchPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_msg != null) ...[
              _AdminStatusBanner(message: _msg!, success: _success, isDark: widget.isDark),
              const SizedBox(height: 14),
            ],
            if (_editing != null) ...[
              _AdminEditForm(
                post: _editing!,
                isDark: widget.isDark,
                titleCtrl: _editTitleCtrl,
                descCtrl: _editDescCtrl,
                type: _editType,
                imageFile: _editImageFile,
                saving: _saving,
                onTypeChanged: (v) => setState(() => _editType = v),
                onPickImage: () async {
                  final p = ImagePicker();
                  final f = await p.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (f != null) setState(() => _editImageFile = f);
                },
                onSave: _saveEdit,
                onCancel: _cancelEdit,
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                const Icon(Icons.dashboard_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text('جميع المنشورات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 17, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black)),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3), width: 1)),
                    child: Text('${_posts.length}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchPosts,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.refresh_rounded, color: Colors.red, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.red)))
            else if (_posts.isEmpty)
              _AdminEmptyState(isDark: widget.isDark)
            else
              ...(_posts.map((p) => _AdminPostCard(post: p, isDark: widget.isDark, onEdit: () => _startEdit(p), onDelete: () => _deletePost(p)))),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// بطاقة منشور
// ────────────────────────────────────────────────────────────
class _AdminPostCard extends StatelessWidget {
  final AdminPost post;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminPostCard({required this.post, required this.isDark, required this.onEdit, required this.onDelete});

  String get _typeLabel { switch (post.type) { case 'file': return 'تطبيق'; case 'simple': return 'سكربت'; default: return 'منشور'; } }
  Color get _typeColor { switch (post.type) { case 'file': return Colors.blue; case 'simple': return Colors.orange; default: return Colors.green; } }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
            child: SizedBox(
              width: 88, height: 88,
              child: post.imageUrl.isNotEmpty
                  ? Image.network(post.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(post.title, style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(_typeLabel, style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, fontWeight: FontWeight.bold, color: _typeColor)),
                  ),
                ]),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(post.description, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ),
          Column(children: [
            _AdminActionBtn(icon: Icons.edit_rounded, color: Colors.blue, onTap: onEdit),
            Container(height: 0.5, width: 48, color: isDark ? Colors.white12 : Colors.black12),
            _AdminActionBtn(icon: Icons.delete_rounded, color: Colors.red, onTap: onDelete),
          ]),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
    child: const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 28)),
  );
}

// ────────────────────────────────────────────────────────────
// نموذج التعديل
// ────────────────────────────────────────────────────────────
class _AdminEditForm extends StatefulWidget {
  final AdminPost post;
  final bool isDark;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final XFile? imageFile;
  final bool saving;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AdminEditForm({required this.post, required this.isDark, required this.titleCtrl, required this.descCtrl, required this.type, required this.imageFile, required this.saving, required this.onTypeChanged, required this.onPickImage, required this.onSave, required this.onCancel});

  @override
  State<_AdminEditForm> createState() => _AdminEditFormState();
}

class _AdminEditFormState extends State<_AdminEditForm> {
  @override
  Widget build(BuildContext context) {
    return _AdminSectionCard(
      isDark: widget.isDark,
      borderColor: Colors.blue.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('تعديل: ${widget.post.title}', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 16),
        _AdminFieldLabel('نوع المنشور', Icons.category_rounded, widget.isDark),
        const SizedBox(height: 8),
        _AdminTypeSelector(selected: widget.type, isDark: widget.isDark, onChanged: widget.onTypeChanged),
        const SizedBox(height: 14),
        _AdminFieldLabel('العنوان', Icons.title_rounded, widget.isDark),
        const SizedBox(height: 8),
        _AdminTextField(controller: widget.titleCtrl, hint: 'العنوان', isDark: widget.isDark),
        const SizedBox(height: 14),
        if (widget.type == 'normal') ...[
          _AdminFieldLabel('الوصف', Icons.notes_rounded, widget.isDark),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.open_in_full_rounded, color: Colors.red.withOpacity(0.5), size: 13),
            const SizedBox(width: 4),
            Text('اضغط لفتح المحرر بملء الشاشة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: widget.isDark ? Colors.white30 : Colors.black38)),
          ]),
          const SizedBox(height: 8),
          _WysiwygDescField(controller: widget.descCtrl, isDark: widget.isDark),
          const SizedBox(height: 14),
        ],
        _AdminFieldLabel('تغيير الصورة (اختياري)', Icons.image_rounded, widget.isDark),
        const SizedBox(height: 8),
        _AdminImagePickerBox(file: widget.imageFile, isDark: widget.isDark, onTap: widget.onPickImage, existingUrl: widget.post.imageUrl),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: widget.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white70 : Colors.black54))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _AdminSubmitButton(label: 'حفظ التعديلات', icon: Icons.save_rounded, loading: widget.saving, onTap: widget.onSave)),
        ]),
      ]),
    );
  }
}

// ────────────────────────────────────────────────────────────
// مكوّنات Admin المشتركة
// ────────────────────────────────────────────────────────────
class _AdminSectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? borderColor;
  const _AdminSectionCard({required this.isDark, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? (isDark ? Colors.white12 : Colors.black.withOpacity(0.07)), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}

class _AdminFieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;
  const _AdminFieldLabel(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.red, size: 16),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
    ]);
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  const _AdminTextField({required this.controller, required this.hint, required this.isDark, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white30 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _AdminTypeSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _AdminTypeSelector({required this.selected, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [('normal', 'منشور', Icons.article_rounded), ('file', 'تطبيق', Icons.android_rounded), ('simple', 'سكربت', Icons.code_rounded)];
    return Row(
      children: types.map((t) {
        final isActive = selected == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? Colors.red.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? Colors.red.withOpacity(0.5) : Colors.transparent, width: 1),
              ),
              child: Column(children: [
                Icon(t.$3, color: isActive ? Colors.red : (isDark ? Colors.white38 : Colors.black38), size: 20),
                const SizedBox(height: 4),
                Text(t.$2, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.red : (isDark ? Colors.white54 : Colors.black54))),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AdminImagePickerBox extends StatelessWidget {
  final XFile? file;
  final bool isDark;
  final VoidCallback onTap;
  final String? existingUrl;
  const _AdminImagePickerBox({required this.file, required this.isDark, required this.onTap, this.existingUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(fit: StackFit.expand, children: [
                Image.file(io.File(file!.path), fit: BoxFit.cover),
                Positioned(top: 6, left: 6, child: _changeLabel()),
              ])
            : existingUrl != null && existingUrl!.isNotEmpty
                ? Stack(fit: StackFit.expand, children: [
                    Image.network(existingUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emptyBox()),
                    Positioned(top: 6, left: 6, child: _changeLabel()),
                  ])
                : _emptyBox(),
      ),
    );
  }

  Widget _changeLabel() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
    child: const Text('تغيير', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white)),
  );

  Widget _emptyBox() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.add_photo_alternate_rounded, color: Colors.red.withOpacity(0.6), size: 32),
    const SizedBox(height: 8),
    Text('اضغط لاختيار صورة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.red.withOpacity(0.7))),
  ]);
}

class _AdminFilePickerBox extends StatelessWidget {
  final XFile? file;
  final bool isDark;
  final VoidCallback onTap;
  const _AdminFilePickerBox({required this.file, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          Icon(file != null ? Icons.check_circle_rounded : Icons.attach_file_rounded, color: file != null ? Colors.green : Colors.red.withOpacity(0.6), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(file != null ? file!.name : 'اختر ملفاً للرفع...', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: file != null ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38)), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _AdminSubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  const _AdminSubmitButton({required this.label, required this.icon, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7B1A14), Color(0xFFE53935)], begin: Alignment.centerRight, end: Alignment.centerLeft),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
        ),
      ),
    );
  }
}

class _AdminStatusBanner extends StatelessWidget {
  final String message;
  final bool success;
  final bool isDark;
  const _AdminStatusBanner({required this.message, required this.success, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: success ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4), width: 1),
      ),
      child: Row(children: [
        Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: success ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w600, color: success ? Colors.green : Colors.red))),
      ]),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  final bool isDark;
  const _AdminEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.8),
      ),
      child: Column(children: [
        Icon(Icons.inbox_rounded, color: Colors.red.withOpacity(0.4), size: 48),
        const SizedBox(height: 12),
        Text('لا توجد منشورات بعد', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: isDark ? Colors.white38 : Colors.black38)),
      ]),
    );
  }
}

class _AdminActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AdminActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 48, height: 44, child: Icon(icon, color: color, size: 20)),
    );
  }
}

class _AdminConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  const _AdminConfirmDialog({required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28)),
            const SizedBox(height: 16),
            Text('حذف المنشور', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 8),
            Text('هل أنت متأكد من حذف "$title"؟\nلا يمكن التراجع عن هذا الإجراء.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: isDark ? Colors.white60 : Colors.black54, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(height: 46, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(height: 46, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B1A14), Color(0xFFE53935)]), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('حذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white)))),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AdminPostTile extends StatelessWidget {
  final bool isDark;
  final int index;
  const _AdminPostTile({required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    final titles = ['منشور تجريبي #1', 'منشور تجريبي #2', 'منشور تجريبي #3'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.article_rounded, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titles[index],
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminInputField extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  final String hint;
  final int maxLines;

  const _AdminInputField({
    required this.isDark,
    required this.label,
    required this.icon,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            maxLines: maxLines,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Tajawal',
                color: isDark ? Colors.white30 : Colors.black38,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }
}


class HostingPage extends StatefulWidget {
  const HostingPage({super.key});

  @override
  State<HostingPage> createState() => _HostingPageState();
}

class _HostingPageState extends State<HostingPage> {
  late Future<List<ScriptItem>> _scriptsFuture;

  @override
  void initState() {
    super.initState();
    _scriptsFuture = fetchScripts();
  }

  Future<void> _refreshScripts() async {
    setState(() {
      _scriptsFuture = fetchScripts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor:
              isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
          elevation: 2,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            ' القوالب والسكربتات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: const [SizedBox(width: 48)],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox(height: 1),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshScripts,
          color: Colors.red,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          child: FutureBuilder<List<ScriptItem>>(
            future: _scriptsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              final hasError = snapshot.hasError;
              final scripts = snapshot.data ?? [];

              if (hasError && scripts.isEmpty) {
                return _buildPageMessage(
                    'تعذر تحميل السكربتات حالياً', isDark, Icons.error_outline);
              }

              if (scripts.isEmpty) {
                return _buildPageMessage('لا توجد سكربتات حالياً', isDark, Icons.inbox_outlined);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: scripts.length + (hasError ? 1 : 0),
                itemBuilder: (context, index) {
                  if (hasError && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1A00) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'لا يوجد اتصال - يتم عرض آخر بيانات محفوظة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: isDark ? Colors.orange[300] : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final scriptIndex = hasError ? index - 1 : index;
                  return _buildScriptCard(scripts[scriptIndex], isDark);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScriptCard(ScriptItem script, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة بنسبة 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: script.imageUrl.isNotEmpty
                ? Image.network(
                    script.encodedImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: isDark
                            ? const Color.fromARGB(255, 32, 32, 32)
                            : Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 48),
                      ),
                    ),
                  )
                : Container(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey, size: 48),
                    ),
                  ),
          ),
          // العنوان تحت الصورة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              script.title.isNotEmpty ? script.title : 'سكربت جديد',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageMessage(String message, bool isDark, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.red, size: 42),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _innerPage(context, "متاجر الكترونية", "تفاصيل المتاجر...");
  }
}

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  late Future<List<AppItem>> _appsFuture;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _appsFuture = fetchApps();
  }

  Future<void> _refreshApps() async {
    setState(() {
      _appsFuture = fetchApps();
    });
  }

  Future<void> _downloadAppFile(AppItem app) async {
    final appId = app.id;
    final fileName = Uri.tryParse(app.fileUrl)?.pathSegments.last ?? app.title;

    if (app.fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رابط التحميل غير متوفر لـ ${app.title}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _downloadingFiles.add(appId);
      _downloadProgress[appId] = 0.0;
    });

    try {
      await downloadFile(
        app.fileUrl,
        fileName,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress[appId] = progress ?? 0.0;
          });
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحميل ${app.title} بنجاح ✓',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحميل ${app.title} ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(appId);
          _downloadProgress.remove(appId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor:
              isDark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white,
          elevation: 2,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تطبيقات الموبايل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: const [SizedBox(width: 48)],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox(height: 1),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshApps,
          color: Colors.red,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          child: FutureBuilder<List<AppItem>>(
            future: _appsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              final hasError = snapshot.hasError;
              final apps = snapshot.data ?? [];

              if (hasError && apps.isEmpty) {
                return _buildPageMessage('تعذر تحميل التطبيقات حالياً', isDark, Icons.error_outline);
              }

              if (apps.isEmpty) {
                return _buildPageMessage('لا توجد تطبيقات حالياً', isDark, Icons.inbox_outlined);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: apps.length + (hasError ? 1 : 0),
                itemBuilder: (context, index) {
                  if (hasError && index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1A00) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'لا يوجد اتصال - يتم عرض آخر بيانات محفوظة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: isDark ? Colors.orange[300] : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final appIndex = hasError ? index - 1 : index;
                  return _buildAppListCard(apps[appIndex], isDark);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppListCard(AppItem app, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: app.imageUrl.isNotEmpty
                ? SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.network(
                      app.encodedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 52,
                          height: 52,
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                          child: const Icon(Icons.broken_image_outlined, color: Colors.red),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apps, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  app.title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (app.fileSize.isNotEmpty || app.fileFormat.isNotEmpty)
                  const SizedBox(height: 4),
                if (app.fileSize.isNotEmpty || app.fileFormat.isNotEmpty)
                  Row(
                    children: [
                      if (app.fileFormat.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            app.fileFormat,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      if (app.fileFormat.isNotEmpty && app.fileSize.isNotEmpty)
                        const SizedBox(width: 6),
                      if (app.fileSize.isNotEmpty)
                        Text(
                          app.fileSize,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _downloadingFiles.contains(app.id)
                ? null
                : () async {
                    if (await Vibration.hasVibrator() ?? false) {
                      Vibration.vibrate(duration: 50);
                    }
                    await _downloadAppFile(app);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: _downloadingFiles.contains(app.id)
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                      value: _downloadProgress[app.id] != null && _downloadProgress[app.id]! > 0
                          ? _downloadProgress[app.id]
                          : null,
                    ),
                  )
                : const Icon(Icons.download, size: 18),
            label: Text(
              _downloadingFiles.contains(app.id)
                  ? (_downloadProgress[app.id] != null && _downloadProgress[app.id]! > 0
                      ? 'جارٍ التحميل ${(_downloadProgress[app.id]! * 100).round()}%'
                      : 'جارٍ التحميل...')
                  : 'تحميل',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageMessage(String message, bool isDark, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.red, size: 42),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _innerPage(BuildContext context, String title, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor:
            isDark ? Color.fromARGB(255, 22, 22, 22) : Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Tajawal",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [SizedBox(width: 48)],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.red),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: "Tajawal",
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    ),
  );
}

class ClickableImage extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ClickableImage({
    required this.imagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.transparent,
            transitionDuration: Duration(milliseconds: 100),
            reverseTransitionDuration: Duration(milliseconds: 100),
            pageBuilder: (_, __, ___) => ImageViewer(imagePath: imagePath),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  final String imagePath;
  const ImageViewer({required this.imagePath});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  double offsetY = 0;
  double scale = 1.0;

  late AnimationController controller;
  late Animation<double> animation;

  void close() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    animation = Tween<double>(begin: 0, end: 0).animate(controller)
      ..addListener(() {
        setState(() {
          offsetY = animation.value;
          scale = 1 - (offsetY.abs() / 600);
        });
      });
  }

  void animateBack() {
    animation = Tween<double>(begin: offsetY, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    controller.forward(from: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double opacity = 1 - (offsetY.abs() / 300);
    opacity = opacity.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: close,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20 * (1 - (offsetY.abs() / 300)).clamp(0.0, 1.0),
                sigmaY: 20 * (1 - (offsetY.abs() / 300)).clamp(0.0, 1.0),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  offsetY += details.delta.dy;
                  scale = 1 - (offsetY.abs() / 600);
                  scale = scale.clamp(0.7, 1.0);
                });
              },
              onVerticalDragEnd: (details) {
                if (offsetY.abs() > 150) {
                  close();
                } else {
                  animateBack();
                }
              },
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: Transform.scale(
                  scale: scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (offsetY.abs()).clamp(0, 50),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Image.asset(widget.imagePath),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? downloadFileName;

  const NetworkImageViewer({
    required this.imageUrl,
    this.downloadFileName,
  });

  @override
  State<NetworkImageViewer> createState() => _NetworkImageViewerState();
}

// Custom notification overlay for top slide-down animation
class _TopNotification extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onAnimationComplete;

  const _TopNotification({
    required this.message,
    required this.isSuccess,
    required this.onAnimationComplete,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isSuccess
                    ? (isDark ? const Color(0xFF1E3A1E) : const Color(0xFFE8F5E9))
                    : (isDark ? const Color(0xFF3A1E1E) : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSuccess
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isSuccess ? Icons.check_circle : Icons.error,
                    color: widget.isSuccess ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
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

class _NetworkImageViewerState extends State<NetworkImageViewer>
    with SingleTickerProviderStateMixin {
  double offsetY = 0;
  double scale = 1.0;
  bool _isDownloading = false;
  String? _notificationMessage;
  bool _notificationSuccess = false;

  late AnimationController controller;
  late Animation<double> animation;

  void _showTopNotification(String message, bool isSuccess) {
    setState(() {
      _notificationMessage = message;
      _notificationSuccess = isSuccess;
    });
  }

  void _hideNotification() {
    setState(() {
      _notificationMessage = null;
    });
  }

  void close() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    animation = Tween<double>(begin: 0, end: 0).animate(controller)
      ..addListener(() {
        setState(() {
          offsetY = animation.value;
          scale = 1 - (offsetY.abs() / 600);
        });
      });
  }

  void animateBack() {
    animation = Tween<double>(begin: offsetY, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    controller.forward(from: 0);
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // طلب الإذن أولاً
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted || await Permission.photos.isGranted) {
        // تنزيل الصورة باستخدام http
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode == 200) {
          // حفظ الصورة في ألبوم الصور
          final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(response.bodyBytes),
            name: widget.downloadFileName ?? 'post_image',
            quality: 100,
          );

          if (!mounted) return;

          if (result != null && result['isSuccess'] == true) {
            _showTopNotification('تم حفظ الصورة في ألبوم الصور بنجاح ✓', true);
          } else {
            _showTopNotification('تعذر حفظ الصورة.', false);
          }
        } else {
          if (!mounted) return;
          _showTopNotification('تعذر تنزيل الصورة.', false);
        }
      } else {
        if (!mounted) return;
        _showTopNotification('يجب منح إذن الوصول إلى التخزين لحفظ الصورة.', false);
      }
    } catch (_) {
      if (!mounted) return;
      _showTopNotification('تعذر تنزيل الصورة.', false);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: close,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20 * (1 - (offsetY.abs() / 300)).clamp(0.0, 1.0),
                sigmaY: 20 * (1 - (offsetY.abs() / 300)).clamp(0.0, 1.0),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  offsetY += details.delta.dy;
                  scale = 1 - (offsetY.abs() / 600);
                  scale = scale.clamp(0.7, 1.0);
                });
              },
              onVerticalDragEnd: (details) {
                if (offsetY.abs() > 150) {
                  close();
                } else {
                  animateBack();
                }
              },
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: Transform.scale(
                  scale: scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (offsetY.abs()).clamp(0, 50),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            padding: const EdgeInsets.all(40),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.red,
                              size: 56,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _isDownloading ? null : _downloadImage,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isDownloading ? 'جاري التنزيل...' : 'تنزيل الصورة'),
            ),
          ),
          // Top notification overlay
          if (_notificationMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopNotification(
                message: _notificationMessage!,
                isSuccess: _notificationSuccess,
                onAnimationComplete: _hideNotification,
              ),
            ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  bool isDark = true;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadTheme();

    player.play(AssetSource("sounds/start.mp3"));

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: 1200), () {
      controller.forward().then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 200),
            pageBuilder: (_, __, ___) => MyApp(),
          ),
        );
      });
    });
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool("theme") ?? true;
    });
  }

  @override
  void dispose() {
    player.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: fadeAnimation.value,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: ColorFiltered(
            colorFilter: isDark
                ? ColorFilter.mode(Colors.transparent, BlendMode.dst)
                : ColorFilter.mode(Colors.red, BlendMode.srcIn),
            child: Image.asset(
              "assets/images/logo.png",
              width: 120,
            ),
          ),
        ),
      ),
    );
  }
}