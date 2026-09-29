import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/view_models/recurring_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/home/views/home_screen.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UiViewModel()..init()),
        ChangeNotifierProvider(create: (_) => AccountViewModel()..init()),
        ChangeNotifierProvider(create: (_) => TransactionViewModel()..init()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()..init()),
        ChangeNotifierProxyProvider4<AccountViewModel, TransactionViewModel, CategoryViewModel, UiViewModel, AppState>(
          create: (context) => AppState(
            Provider.of<AccountViewModel>(context, listen: false),
            Provider.of<TransactionViewModel>(context, listen: false),
            Provider.of<CategoryViewModel>(context, listen: false),
            Provider.of<UiViewModel>(context, listen: false),
          ),
          update: (context, accVM, txVM, catVM, uiVM, previous) => previous ?? AppState(accVM, txVM, catVM, uiVM),
        ),
        ChangeNotifierProxyProvider<AppState, RecurringViewModel>(
          create: (context) => RecurringViewModel(Provider.of<AppState>(context, listen: false)),
          update: (context, appState, previous) => previous ?? RecurringViewModel(appState),
        ),
        ChangeNotifierProxyProvider3<AccountViewModel, TransactionViewModel, UiViewModel, DashboardViewModel>(
          create: (context) => DashboardViewModel(
            Provider.of<AccountViewModel>(context, listen: false),
            Provider.of<TransactionViewModel>(context, listen: false),
            Provider.of<UiViewModel>(context, listen: false),
          ),
          update: (context, accVM, txVM, uiVM, previous) => previous ?? DashboardViewModel(accVM, txVM, uiVM),
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
      theme: AppTheme.lightTheme,
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






