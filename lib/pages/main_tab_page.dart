import 'package:flutter/material.dart';
import 'tab1_page.dart';
import 'tab2_page.dart';
import 'tab3_page.dart';
import 'tab4_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Tab1Page(),
    const Tab2Page(),
    const Tab3Page(),
    const Tab4Page(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF24F8D5).withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Image.asset(
                      isSelected
                          ? 'assets/images/x_pre/xvibe_tab${index + 1}_pre.png'
                          : 'assets/images/x_nor/xvibe_tab${index + 1}_nor.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
} 