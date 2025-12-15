import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'theme.dart';
import 'feed_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "icon": PhosphorIcons.hexagon(PhosphorIconsStyle.duotone),
      "title": "WELCOME OPERATOR",
      "desc":
          "DevDeck is your secure terminal for showcasing code. Treat your projects like assets."
    },
    {
      "icon": PhosphorIcons.cards(PhosphorIconsStyle.duotone),
      "title": "MINT & BOOST",
      "desc":
          "Upload projects as Trading Cards. The more community boosts you get, the rarer your card becomes."
    },
    {
      "icon": PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
      "title": "NETWORK & CHAT",
      "desc":
          "Follow top developers and start encrypted chats to collaborate or request access."
    },
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_slides[index]["icon"],
                              size: 120, color: AppTheme.neonBlue),
                          const SizedBox(height: 40),
                          Text(_slides[index]["title"],
                              style: AppTheme.fontTech.copyWith(
                                  fontSize: 24,
                                  color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 20),
                          Text(
                            _slides[index]["desc"],
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle
                                .copyWith(color: Colors.grey, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.neonBlue
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(4)),
                        )),
              ),

              const SizedBox(height: 40),

              // Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonBlue,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut);
                      } else {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeedPage()));
                      }
                    },
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? "ENTER SYSTEM"
                          : "NEXT",
                      style: AppTheme.fontTech
                          .copyWith(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
