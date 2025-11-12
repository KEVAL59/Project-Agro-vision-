
import 'package:flutter/material.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageContent> _pages = const [
    OnboardingPageContent(
      icon: Icons.wb_cloudy_outlined,
      color: Colors.blue,
      title: 'Live Weather & Prediction',
      description: 'Live weather updates for smarter farming',
    ),
    OnboardingPageContent(
      icon: Icons.local_florist_outlined,
      color: Colors.green,
      title: 'Crop Health Diagnosis',
      description: 'Instant crop health check made easy',
    ),
    OnboardingPageContent(
      icon: Icons.trending_up_rounded,
      color: Colors.orange,
      title: 'Market Prices',
      description: "Know today's rates, sell smartly",
    ),
    OnboardingPageContent(
      icon: Icons.account_balance_outlined,
      color: Colors.purple,
      title: 'Government Schemes',
      description: 'Latest schemes and benefits for farmers',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _pages[_currentPage].color.withOpacity(0.1),
          ),
          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(content: _pages[index]);
            },
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentPage > 0 ? 1.0 : 0.0,
              child: IconButton(
                onPressed: _currentPage > 0 ? () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } : null,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: _pages[_currentPage].color,
                  size: 28,
                ),
              ),
            ),
          ),
          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(4, (index) => buildDot(index, context)),
                  ),
                  if (_currentPage == 3)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Get Started', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 20),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _pages[_currentPage].color,
      ),
    );
  }
}

// A simple data class for the page content
class OnboardingPageContent {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const OnboardingPageContent({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  final OnboardingPageContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Glassy Icon
        FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(_animation),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(150),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.content.color.withOpacity(0.25),
                    border: Border.all(color: widget.content.color.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(widget.content.icon, size: 120, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        // Floating Text Card
        FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_animation),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.content.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.content.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
