import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
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
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

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
            onRegisterScrollCallback: (callback) {
              _homeScrollToTopCallback = callback;
            },
          ),
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
  final Function(VoidCallback)? onRegisterScrollCallback;

  const HomePage({
    required this.isDark, 
    required this.onToggle,
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
            physics: const ClampingScrollPhysics(
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
          _SlideFromLeftRoute(
            page: PostDetailsPage(post: post, isDark: isDark),
          ),
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

  const AppItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.fileUrl,
  });

  String get encodedImageUrl => Uri.encodeFull(imageUrl);
  String get encodedFileUrl => Uri.encodeFull(fileUrl);

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
    );
  }
}

// دالة جلب السكربتات
Future<List<ScriptItem>> fetchScripts() async {
  final response =
      await http.get(Uri.parse('https://scrptaty.com/posts/get_simple.php'));

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

  return rawScripts
      .whereType<Map>()
      .map((item) => ScriptItem.fromJson(Map<String, dynamic>.from(item)))
      .where((script) =>
          script.title.isNotEmpty || script.imageUrl.isNotEmpty)
      .toList();
}

// دالة جلب التطبيقات
Future<List<AppItem>> fetchApps() async {
  final response =
      await http.get(Uri.parse('https://scrptaty.com/posts/get_files.php'));

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

  return rawApps
      .whereType<Map>()
      .map((item) => AppItem.fromJson(Map<String, dynamic>.from(item)))
      .where((app) => app.title.isNotEmpty || app.imageUrl.isNotEmpty)
      .toList();
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
    PermissionStatus status;
    if (io.Platform.isIOS) {
      status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    } else {
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (!status.isGranted) {
      throw Exception('لم يتم منح إذن الوصول إلى التخزين');
    }

    // تنظيف اسم الملف من الأحرف الخاصة
    String cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (cleanFileName.isEmpty) {
      cleanFileName = 'downloaded_file';
    }

    print('  Clean filename: $cleanFileName');

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

      final directory = await _getDownloadDirectory();
      final file = io.File('${directory.path}/$cleanFileName');
      await file.writeAsBytes(bytes);
      
      print('  Saved to: ${file.path}');
      print('Download completed successfully!');
    } finally {
      client.close();
    }
  } catch (e) {
    print('Error downloading file: $e');
    rethrow;
  }
}

Future<io.Directory> _getDownloadDirectory() async {
  if (io.Platform.isAndroid) {
    final directory = io.Directory('/storage/emulated/0/Download/Scrptaty');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  if (io.Platform.isWindows) {
    final directory = io.Directory('${io.Directory.current.path}/downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  if (io.Platform.isMacOS || io.Platform.isLinux || io.Platform.isIOS) {
    final homeDir = io.Platform.environment['HOME'] ?? io.Directory.current.path;
    final directory = io.Directory('$homeDir/Downloads/Scrptaty');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  return io.Directory.current;
}

class ScriptsPage extends StatefulWidget {
  final bool isDark;
  const ScriptsPage({required this.isDark});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<ScriptItem>> _scriptsFuture;
  late Future<List<AppItem>> _appsFuture;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingFiles = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scriptsFuture = fetchScripts();
    _appsFuture = fetchApps();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          content: Text('تم تحميل ${app.title} بنجاح ✓'),
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
            content: Text('فشل تحميل ${app.title}: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Widget _buildAppsSection(bool isDark) {
    return FutureBuilder<List<AppItem>>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorMessage('تعذر تحميل التطبيقات');
        }

        final apps = snapshot.data ?? [];
        if (apps.isEmpty) {
          return _buildEmptyMessage('لا توجد تطبيقات حالياً');
        }

        return Column(
          children: apps
              .map((app) => _buildAppCard(app, isDark))
              .toList(),
        );
      },
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
          // اسم التطبيق
          Expanded(
            child: Text(
              app.title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 8),
            
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

class HostingPage extends StatefulWidget {
  const HostingPage({super.key});

  @override
  State<HostingPage> createState() => _HostingPageState();
}

class _HostingPageState extends State<HostingPage> {
  late Future<List<PostItem>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = fetchPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = fetchPosts();
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
            'استضافة المواقع',
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
          onRefresh: _refreshPosts,
          color: Colors.red,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          child: FutureBuilder<List<PostItem>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              if (snapshot.hasError) {
                return _buildPageMessage(
                    'تعذر تحميل المنشورات حالياً', isDark, Icons.error_outline);
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return _buildPageMessage('لا توجد منشورات حالياً', isDark, Icons.inbox_outlined);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return _buildHostingPostCard(posts[index], isDark);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHostingPostCard(PostItem post, bool isDark) {
    final plainDescription = stripHtmlTags(post.description)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.encodedImageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
                  child: const Icon(Icons.broken_image_outlined, color: Colors.red),
                ),
              ),
            ),
          if (post.imageUrl.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  post.title.isNotEmpty ? post.title : 'منشور جديد',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  plainDescription.isNotEmpty ? plainDescription : 'لا يوجد وصف متاح.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
          content: Text('تم تحميل ${app.title} بنجاح ✓'),
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
            content: Text('فشل تحميل ${app.title}: ${e.toString().replaceAll('Exception: ', '')}'),
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

              if (snapshot.hasError) {
                return _buildPageMessage('تعذر تحميل التطبيقات حالياً', isDark, Icons.error_outline);
              }

              final apps = snapshot.data ?? [];
              if (apps.isEmpty) {
                return _buildPageMessage('لا توجد تطبيقات حالياً', isDark, Icons.inbox_outlined);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  return _buildAppListCard(apps[index], isDark);
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
            child: Text(
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
