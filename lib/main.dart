import 'package:civicsnap_android/firebase_options.dart';
import 'package:civicsnap_android/router/router.dart';
import 'package:civicsnap_android/themes/light.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: civicSnapLightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
