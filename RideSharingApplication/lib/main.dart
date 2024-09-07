import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vivi_ride_app/appInfo/app_info.dart';

import 'package:vivi_ride_app/splash_screen/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (Platform.isAndroid)
  {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCl5-_JW6ap9Y7LnC7k7mZ2xIyblMVQqpU",
          authDomain: "vivi0809-d0aa9.firebaseapp.com",
          projectId: "vivi0809-d0aa9",
          storageBucket: "vivi0809-d0aa9.appspot.com",
          messagingSenderId: "958317255406",
          appId: "1:958317255406:web:1326a0d43d8589994bb1ff",
          measurementId: "G-HYZYKT92ST"
          )
    );
  }
  else {
    await Firebase.initializeApp();
  }
  await Permission.locationWhenInUse.isDenied.then((value)
  {
    if(value)
      {
        Permission.locationWhenInUse.request();
      }
  });

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  // Customize the status bar and navigation bar appearance
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // or Brightness.dark
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light, // or Brightness.dark
  ));



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=> AppInfo(),
      child: MaterialApp(
        title: 'vivi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
      
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        home: const SplashScreen(),//FirebaseAuth.instance.currentUser == null ? const SignInPage() : const HomePage(),
      ),
    );
  }
}
