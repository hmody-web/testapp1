import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        isDark: isDark,
        onToggle: () {
          setState(() {
            isDark = !isDark;
          });
        },
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

            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isDark,
                onChanged: (v) => onToggle(),
                activeColor: Colors.red,
              ),
            ),

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
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
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

            // 🔥 الكروت (تم تعديلها فقط)
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
                    "مطور ويب محترف مع خبرة في تطوير المواقع والتطبيقات والويب المتقدمة.",
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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "أحدث المنشورات",
                      style: TextStyle(
                        fontFamily: "Tajawal",
                        fontSize: 22,
                        color:
                            isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 60,
                      height: 2,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15)),
                        child: Image.asset(
                          "assets/images/post.png",
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "عنوان المنشور ${index + 1}",
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "هذا وصف تجريبي للمنشور، يمكنك تعديله لاحقاً.",
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                color: isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),

                            SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                ),
                                onPressed: () {},
                                child: Text("الدخول للموقع"),
                              ),
                            ),
                          ],
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

  Widget _card(BuildContext context, IconData icon, String text, Widget page, bool isDark) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 350),
              pageBuilder: (_, __, ___) => page,
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
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
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.red, size: 30),
              SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Tajawal",
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
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
    return _page("استضافة المواقع", "هنا تضيف تفاصيل الاستضافة...");
  }
}

class StorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _page("متاجر الكترونية", "هنا تضيف تفاصيل المتاجر...");
  }
}

class AppsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _page("تطبيقات الموبايل", "هنا تضيف تفاصيل التطبيقات...");
  }
}

Widget _page(String title, String text) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}