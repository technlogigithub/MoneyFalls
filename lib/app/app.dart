import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:lottery/app/routes/app_pages.dart';
import 'package:lottery/main.dart';
import 'package:toastification/toastification.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        title: "Lottery",
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        initialRoute: Routes.SPLASH,
        getPages: AppPages.routes,
      ),
    );
  }
}
