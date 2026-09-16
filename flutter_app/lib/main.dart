import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const SmartBudgetApp(),
    ),
  );
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Budget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Tailwind slate-900
        primaryColor: const Color(0xFF6366F1), // Indigo 500
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF3B82F6), // Blue 500
          surface: Color(0xFF1E293B), // slate-800
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradients for glassmorphism effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF6366F1), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF3B82F6), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildBudgetCard(context),
                        const SizedBox(height: 20),
                        _buildDailyList(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add transaction logic
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Open drawer
            },
          ),
          const Text(
            '9월 가계부',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('총 예산', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          const Text('₩ 500,000', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)), // Emerald 500
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('지출: ₩ 300,000', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text('남음: ₩ 200,000', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDailyList(BuildContext context) {
    return const Column(
      children: [
        // Dummy data for now
        Text('거래 내역이 여기에 표시됩니다.', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}
