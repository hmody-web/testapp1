import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// 🔥 Stateful للتحكم بالثيم + حفظه
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    loadTheme();
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        isDark: isDark,
        onToggle: toggleTheme,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  HomePage({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? Color.fromARGB(255, 22, 22, 22) : Colors.white,

      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Color.fromARGB(255, 223, 6, 24),
          ),
        ),
        backgroundColor:
            isDark ? Color.fromARGB(255, 22, 22, 22) : Colors.white,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // 🔴 السويتش
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isDark,
                onChanged: (v) => onToggle(),
                activeColor: Colors.red,
              ),
            ),

            // 🔵 اللوجو + النص
            Row(
              children: [
                Text(
                  "سكربتاتي",
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    fontSize: 24,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: 10),
                Transform.translate(
                  offset: Offset(0, -2),
                  child: ColorFiltered(
                    colorFilter: isDark
                        ? ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 35,
                      errorBuilder: (c, e, s) {
                        return Icon(Icons.image_not_supported);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [

            // 🔥 الهيدر
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
                            Color.fromARGB(209, 240, 3, 3),
                            Color.fromARGB(204, 168, 19, 31)
                                .withOpacity(0.9),
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
                      SizedBox(height: 10),
                      Text(
                        "سكربتاتي",
                        style: TextStyle(
                          fontFamily: "Tajawal",
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
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

            // 🔥 الكروت
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 25),
              color: isDark
                  ? Color.fromARGB(255, 34, 34, 34)
                  : Colors.grey[200],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    _card(context, Icons.storage, "استضافة\nالمواقع", HostingPage(), isDark),
                    _card(context, Icons.shopping_cart, "متاجر\nالكترونية", StorePage(), isDark),
                    _card(context, Icons.phone_android, "تطبيقات\nالموبايل", AppsPage(), isDark),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 🔥 البروفايل
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Color.fromARGB(3, 255, 255, 255)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [

                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 100,
                      child: ClipOval(
                        child: ClickableImage(
                          imagePath: "assets/images/profile.png",
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    "محمد السراي",
                    style: TextStyle(
                      fontFamily: "Tajawal",
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "مطور ويب محترف مع خبرة في تطوير المواقع والتطبيقات.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Tajawal",
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 🔥 المنشورات
            Column(
              children: List.generate(8, (index) {
                return Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Color(0xFF1E1E1E)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ClickableImage(
                        imagePath: "assets/images/post.png",
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          "عنوان المنشور ${index + 1}",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 كرت
  Widget _card(BuildContext context, IconData icon, String text, Widget page, bool isDark) {
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
  bool isPressed = false; // ✅ حالة الضغط

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),

      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),   // ✅ عند بداية الضغط
        onTapUp: (_) => setState(() => isPressed = false),    // ✅ عند رفع الإصبع
        onTapCancel: () => setState(() => isPressed = false), // ✅ إذا ألغي الضغط
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
                ? Colors.red.withOpacity(0.4) // ✅ لون مختلف عند الضغط
                : isHovered
                    ? (widget.isDark
                        ? const Color.fromARGB(255, 212, 42, 42).withOpacity(0.7)
                        : const Color.fromARGB(255, 212, 42, 42).withOpacity(0.2))
                    : (widget.isDark
                        ? Color(0xFF1E1E1E)
                        : Colors.white),
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
// 🔥 Notifier مشترك لتمرير قيمة السحب للـ Route
// ============================================================
final _globalDragNotifier = ValueNotifier<double>(0);

// ============================================================
// 🔥 Route مخصص: الصفحة تدخل من اليسار
//    الصفحة الخلفية تتحرك معها عند السحب
// ============================================================
class _SlideFromLeftRoute extends PageRouteBuilder {
  final Widget page;

  _SlideFromLeftRoute({required this.page})
      : super(
          opaque: false,
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              _SwipeToCloseWrapper(child: page),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final slideIn = Tween<Offset>(
              begin: Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));

            // الصفحة الخلفية تتحرك 30% من سحب الأمامية
            return ValueListenableBuilder<double>(
              valueListenable: _globalDragNotifier,
              builder: (_, drag, __) {
                return Transform.translate(
                  offset: Offset(drag * 0.3, 0),
                  child: SlideTransition(
                    position: slideIn,
                    child: Transform.translate(
                      offset: Offset(-drag * 0.3, 0),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

// ============================================================
// 🔥 Wrapper يدعم السحب من اليمين لليسار للإغلاق
//    ويُحدّث _globalDragNotifier لتحريك الصفحة الخلفية معها
// ============================================================
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
          // أخبر الـ Route بقيمة السحب لتحريك الخلفية
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

// ============================================================
// 🔥 الصفحات
// ============================================================
class HostingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _page(context, "استضافة المواقع", "تفاصيل الاستضافة...");
  }
}

class StorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _page(context, "متاجر الكترونية", "تفاصيل المتاجر...");
  }
}

class AppsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _page(context, "تطبيقات الموبايل", "تفاصيل التطبيقات...");
  }
}

// ============================================================
// 🔥 صفحة داخلية
// ============================================================
Widget _page(BuildContext context, String title, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[100],

      appBar: AppBar(
        backgroundColor: isDark
            ? Color.fromARGB(255, 22, 22, 22)
            : Colors.white,
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

// ============================================================
// 🔥 ClickableImage
// ============================================================
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
              return FadeTransition(
                opacity: animation,
                child: child,
              );
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

// ============================================================
// 🔥 ImageViewer
// ============================================================
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

          // 🔥 الخلفية
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

          // 📸 الصورة
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

// ============================================================
// 🔥 SplashScreen
// ============================================================
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ),
    );

    fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
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
          child: Image.asset(
            "assets/images/logo.png",
            width: 120,
          ),
        ),
      ),
    );
  }
}