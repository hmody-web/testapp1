import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color.fromARGB(255, 22, 22, 22),
appBar: AppBar(
    bottom: PreferredSize(
    preferredSize: Size.fromHeight(1), // الارتفاع 1 بكسل
    child: Container(
      height: 1,
      color: const Color.fromARGB(255, 223, 6, 24),
    ),
  ),
  backgroundColor: Color.fromARGB(255, 22, 22, 22),
  title: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(
        "سكربتاتي",
        style: TextStyle(
          fontFamily: "Tajawal",
          fontSize: 24,
          color: Colors.white,
        ),
      ),

      SizedBox(width: 10), // مسافة بين النص واللوجو

Transform.translate(
  offset: Offset(0, -2), // x=0, y=5 ينزل
  child: Image.asset(
    "assets/images/logo.png",
    height: 35,
  ),
)
    ],
  ),
),
     



body: SingleChildScrollView(
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
                    Color.fromARGB(209, 240, 3, 3),
                    Color.fromARGB(204, 168, 19, 31).withOpacity(0.9),
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

  SizedBox(height: 0),

Container(
  width: double.infinity,
  padding: EdgeInsets.symmetric(vertical: 25),
  decoration: BoxDecoration(
    color: Color.fromARGB(255, 34, 34, 34),
  ),
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 15),
    child: Row(
      children: [

        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Icon(Icons.storage, color: Colors.red, size: 30),
                SizedBox(height: 10),
                Text(
                  "استضافة\nالمواقع",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_cart, color: Colors.red, size: 30),
                SizedBox(height: 10),
                Text(
                  "متاجر\nالكترونية",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Icon(Icons.phone_android, color: Colors.red, size: 30),
                SizedBox(height: 10),
                Text(
                  "تطبيقات\nالموبايل",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    ),
  ),
),

SizedBox(height: 30),

Container(
  margin: EdgeInsets.symmetric(horizontal: 15),
  padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
  decoration: BoxDecoration(
    color: Color.fromARGB(3, 255, 255, 255),
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
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      SizedBox(height: 10),

      Text(
        "مطور ويب محترف مع خبرة في تطوير المواقع والتطبيقات والويب المتقدمة.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "Tajawal",
          color: Colors.white70,
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
            color: Colors.white,
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

Column(
  children: List.generate(8, (index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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

               

                SizedBox(height: 5),

                Text(
                  "عنوان المنشور ${index + 1}",
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),

                SizedBox(height: 5),

                Text(
                  "هذا وصف تجريبي للمنشور، يمكنك تعديله وربطه مع قاعدة البيانات لاحقاً.",
                  style: TextStyle(
                    fontFamily: "Tajawal",
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
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
  
}
