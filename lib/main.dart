import 'package:flutter/material.dart';
import './Home.dart';


void main() {
  runApp(
 const MyApp());
}

Color appbar = Color(0XFF0D1F2D);
Color btmclr = Color(0XFF0F1C28);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false).copyWith(
          scaffoldBackgroundColor: appbar,
          appBarTheme: AppBarTheme(
            backgroundColor: appbar,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: btmclr,
          )),
      home: HomePage(),
    );
  }
}
