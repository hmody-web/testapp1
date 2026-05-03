import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        physics: ClampingScrollPhysics(), // 🔥 منع السحب الزائد
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
                        child: Image.asset(
                          "assets/images/profile.png",
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
                      Image.asset(
                        "assets/images/post.png",
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
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 200),

pageBuilder: (_, __, ___) => page,

transitionsBuilder: (_, animation, secondaryAnimation, child) {

  final fadeIn = Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ),
  );

  final fadeOut = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOut,
    ),
  );

  return FadeTransition(
    opacity: fadeIn,
    child: FadeTransition(
      opacity: fadeOut,
      child: child,
    ),
  );
},
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.red),
              SizedBox(height: 10),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    color: isDark ? Colors.white : Colors.black,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔥 الصفحات
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

// 🔥 صفحة مع رجوع يمين + سحب
Widget _page(BuildContext context, String title, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor:
          isDark ? Color(0xFF121212) : Colors.grey[100],

 appBar: PreferredSize(
  preferredSize: Size.fromHeight(100),
  child: Container(
    height: 53,
    decoration: BoxDecoration(
      color: isDark ? Color.fromARGB(255, 22, 22, 22) : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false, // 🔥 يمنع زيادة الارتفاع من الأسفل
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [

            // 🔙 زر الرجوع (يمين)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),

            SizedBox(width: 10),

            // 🔤 العنوان
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Tajawal",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            SizedBox(width: 48),
          ],
        ),
      ),
    ),
  ),
),

      // 🔥 سحب للرجوع
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 10) {
            Navigator.pop(context);
          }
        },
        child: Padding(
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
    ),
  );
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

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300), // مدة الانميشن
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

    // انتظار بسيط قبل الانميشن
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

