import 'dart:async';
import 'dart:convert';
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
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'image_download_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Tajawal',
        brightness: Brightness.dark,
      ),
      home: SplashScreen(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadTheme();
    PostNotificationMonitor.start();
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool("theme") ?? true;
    });
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
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const MainShell({required this.isDark, required this.onToggle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  double _currentPage = 0.0;
  late final PageController _pageController;

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
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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
          HomePage(isDark: widget.isDark, onToggle: widget.onToggle),
          ScriptsPage(isDark: widget.isDark),
          ContactPage(isDark: widget.isDark),
          SettingsPage(isDark: widget.isDark, onToggle: widget.onToggle),
        ],
      ),
      bottomNavigationBar: _GlassNavBar(
        currentPage: _currentPage,
        currentIndex: _currentIndex,
        items: _items,
        isDark: widget.isDark,
        onTap: _onTabTap,
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

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const HomePage({required this.isDark, required this.onToggle});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: ColorFiltered(
                      colorFilter: isDark
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                          : const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                      child: Image.asset(
                        "assets/images/logo.png",
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
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isDark,
                  onChanged: (v) => widget.onToggle(),
                  activeColor: Colors.red,
                ),
              ),
            ],
          ),
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
                        _card(context, Icons.storage, "استضافة\nالمواقع", HostingPage(), isDark),
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
                        'لا يوجد اتصال. عرض المنشورات التي شاهدتها سابقاً.',
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
                      children: posts
                          .map((post) => _buildPostCard(context, post))
                          .toList(),
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

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          const SizedBox(width: 12),
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
          _SlideFromLeftRoute(
            page: PostDetailsPage(post: post, isDark: isDark),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                    Text(
                      post.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
    final plainDescription = stripHtmlTags(post.description);
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
                  _SlideFromLeftRoute(
                    page: PostDetailsPage(post: post, isDark: isDark),
                  ),
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
                    Text(
                      post.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        'strong': Style(fontWeight: FontWeight.bold),
                        'a': Style(color: Colors.red),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url == null || url.isEmpty) return;
                        final uri = Uri.tryParse(url);
                        if (uri != null) {
                          launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
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
class ScriptsPage extends StatelessWidget {
  final bool isDark;
  const ScriptsPage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.grey[100],
        appBar: AppBar(
          backgroundColor:
              isDark ? Color.fromARGB(255, 22, 22, 22) : Colors.white,
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(height: 1, color: Colors.red),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded,
                  size: 80, color: Colors.red.withOpacity(0.4)),
              SizedBox(height: 20),
              Text(
                'السكربتات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'ستظهر هنا جميع السكربتات والمشاريع المميزة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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

  Future<void> _openLink(String value, {bool isEmail = false}) async {
    final Uri uri;

    if (isEmail) {
      uri = Uri(
        scheme: 'mailto',
        path: value,
        query: Uri.encodeFull('subject=تواصل&body=مرحباً'),
      );
    } else {
      uri = Uri.parse(value);
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ ماكدر أفتح الرابط");
    }
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
                onTap: () => _openLink("info@scrptaty.com", isEmail: true),
              ),
              _buildCard(
                isDark,
                icon: const Icon(Icons.language, color: Colors.blue),
                title: "الموقع الإلكتروني",
                subtitle: "https://scrptaty.com",
                onTap: () => _openLink("https://scrptaty.com"),
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
                onTap: () => _openLink("https://instagram.com/Eng.mu7med"),
              ),
              _buildCard(
                isDark,
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                title: "تلكرام",
                subtitle: "@Mooo5",
                onTap: () => _openLink("https://t.me/Mooo5"),
              ),
              _buildCard(
                isDark,
                icon:
                    const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: "واتساب",
                subtitle: "+964 772 653 7514",
                onTap: () => _openLink("https://wa.me/9647726537514"),
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
//  صفحة الإعدادات
// ============================================================
class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const SettingsPage({required this.isDark, required this.onToggle});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
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

    final granted = await NotificationService.requestPermission();

    if (!granted) {
      await _setNotificationEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('يجب السماح بالإشعارات من الجهاز لتفعيلها داخل التطبيق.'),
        ),
      );
      return;
    }

    await _setNotificationEnabled(true);
    await PostNotificationMonitor.markLatestPostAsSeen();
    await PostNotificationMonitor.start();
    await NotificationService.showWelcomeNotificationAfterDelay();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تفعيل الإشعارات، وسيصل إشعار ترحيبي خلال 5 ثوانٍ.'),
      ),
    );
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      child: Scaffold(
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
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إعدادات التطبيق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هنا يمكنك التحكم في خيارات التطبيق الأساسية  .',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
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
            ],
          ),
        ),
      ),
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
            _SlideFromLeftRoute(page: widget.page),
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

final _globalDragNotifier = ValueNotifier<double>(0);

class _SlideFromLeftRoute extends PageRouteBuilder {
  final Widget page;

  _SlideFromLeftRoute({required this.page})
      : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              _SwipeToCloseWrapper(child: page),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleIn = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            final fadeIn = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ));

            return ValueListenableBuilder<double>(
              valueListenable: _globalDragNotifier,
              builder: (_, drag, __) {
                return Transform.translate(
                  offset: Offset(drag * 0.3, 0),
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: Transform.scale(
                      scale: scaleIn.value,
                      child: Transform.translate(
                        offset: Offset(-drag * 0.3, 0),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
}

class _SwipeToCloseWrapper extends StatefulWidget {
  final Widget child;
  const _SwipeToCloseWrapper({required this.child});

  @override
  State<_SwipeToCloseWrapper> createState() => _SwipeToCloseWrapperState();
}

class _SwipeToCloseWrapperState extends State<_SwipeToCloseWrapper> {
  double _dragStartX = 0;
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void dispose() {
    _globalDragNotifier.value = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (details.globalPosition.dx > screenWidth * 0.75) {
          _dragStartX = details.globalPosition.dx;
          _isDragging = true;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!_isDragging) return;
        final delta = details.globalPosition.dx - _dragStartX;
        if (delta < 0) {
          setState(() => _dragOffset = delta);
          _globalDragNotifier.value = delta;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isDragging) return;
        _isDragging = false;
        _globalDragNotifier.value = 0;

        if (_dragOffset < -100 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! < -500)) {
          Navigator.pop(context);
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: widget.child,
        ),
      ),
    );
  }
}

class HostingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _innerPage(context, "استضافة المواقع", "تفاصيل الاستضافة...");
  }
}

class StorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _innerPage(context, "متاجر الكترونية", "تفاصيل المتاجر...");
  }
}

class AppsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _innerPage(context, "تطبيقات الموبايل", "تفاصيل التطبيقات...");
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

class _NetworkImageViewerState extends State<NetworkImageViewer>
    with SingleTickerProviderStateMixin {
  double offsetY = 0;
  double scale = 1.0;
  bool _isDownloading = false;

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

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final savedPath = await downloadNetworkImage(
        widget.imageUrl,
        fileName: widget.downloadFileName,
      );

      if (!mounted) return;

      final message = savedPath == 'web_download_started'
          ? 'تم بدء تنزيل الصورة.'
          : 'تم حفظ الصورة في: $savedPath';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تنزيل الصورة.')),
      );
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
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
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
