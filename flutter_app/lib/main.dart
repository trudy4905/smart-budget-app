import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/recurring/view_models/recurring_view_model.dart';
import 'package:flutter_app/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/home/views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, RecurringViewModel>(
          create: (context) => RecurringViewModel(Provider.of<AppState>(context, listen: false)),
          update: (context, appState, previous) => previous ?? RecurringViewModel(appState),
        ),
        ChangeNotifierProxyProvider<AppState, DashboardViewModel>(
          create: (context) => DashboardViewModel(Provider.of<AppState>(context, listen: false)),
          update: (context, appState, previous) => previous ?? DashboardViewModel(appState),
        ),
      ],
      child: const SmartBudgetApp(),
    ),
  );
}

// ============================================================
// APP ROOT
// ============================================================
class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Budget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        primaryColor: const Color(0xFF4F46E5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF2563EB),
          surface: Color(0xFFFFFFFF),
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.light().textTheme),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFFF1F5F9)),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN (Calendar-first)
// ============================================================
