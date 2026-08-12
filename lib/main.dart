import 'package:flutter/material.dart';

import './Home.dart';

void main() {
  runApp(const MyApp());
}

Color appbar = Color(0XFF0D1F2D);
Color btmclr = Color(0XFF0F1C28);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //  title: 'Caller',
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
