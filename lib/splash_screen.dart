import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Ensure 'intro.mp4' is in your assets folder
    _controller = VideoPlayerController.asset('assets/intro.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          // CRITICAL FIX FOR WEB:
          // Browsers block autoplay unless the video is muted.
          _controller.setVolume(0.0);
          _controller.play();
          _controller.setLooping(false);
        }
      });

    // Navigate when video finishes
    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use a curved fade for a "perfectly smooth" transition
          var curve = Curves.easeInOut;
          var tween =
              Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        // Increase duration for a noticeable, smooth fade effect
        transitionDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // AnimatedSwitcher creates a smooth cross-fade between the loader and the video
        // This prevents the "black screen" pop-in on web
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: _initialized
              ? AspectRatio(
                  key: const ValueKey('video'),
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : CircularProgressIndicator(
                  key: const ValueKey('loader'),
                  color: AppTheme.neonBlue,
                ),
        ),
      ),
    );
  }
}
