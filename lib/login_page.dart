import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'feed_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // STATE
  bool isSignUp = false;
  bool isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- HANDLE AUTH ACTIONS ---
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnack("Please enter your email", isError: true);
      return;
    }
    if (password.isEmpty) {
      _showSnack("Please enter your password", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (isSignUp) {
        // --- SIGN UP (Direct Supabase) ---
        // We assume 'Confirm Email' is disabled in Supabase Console
        // so this logs the user in immediately.
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (res.user != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const FeedPage())
            );
          }
        }
      } else {
        // --- LOGIN (Direct Supabase) ---
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.user != null) {
           if (mounted) {
             Navigator.pushReplacement(
               context, 
               MaterialPageRoute(builder: (_) => const FeedPage())
             );
           }
        }
      }
    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack("Unexpected error occurred", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI HELPERS ---
  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.neonBlue,
        child: Icon(isDark ? PhosphorIcons.sun() : PhosphorIcons.moon(),
            color: Colors.black),
        onPressed: () {
          AppTheme.isDarkNotifier.value = !AppTheme.isDarkNotifier.value;
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: isDark
                ? [const Color(0xFF2A2A2A), const Color(0xFF000000)]
                : [Colors.white, const Color(0xFFEEEEEE)],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 180,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          PhosphorIcons.hexagon(),
                          size: 100,
                          color: AppTheme.neonBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("SECURE ACCESS TERMINAL",
                      style: AppTheme.fontCode.copyWith(color: Colors.grey)),
                  const SizedBox(height: 50),

                  // FORM CONTAINER
                  GlassmorphicContainer(
                    width: double.infinity,
                    height: 400, // Reduced height since fields are fewer
                    borderRadius: 20,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05)
                    ]),
                    borderGradient: LinearGradient(
                        colors: [Colors.white24, Colors.white10]),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              isSignUp ? "NEW OPERATOR SIGNUP" : "SYSTEM LOGIN",
                              style: AppTheme.fontTech.copyWith(color: AppTheme.neonBlue)
                          ),
                          const SizedBox(height: 25),
                          
                          // Email Field
                          CyberField(
                              label: "EMAIL ADDRESS",
                              controller: _emailController),
                          
                          const SizedBox(height: 15),

                          // Password Field
                          CyberField(
                              label: "PASSWORD",
                              controller: _passwordController,
                              isPassword: true),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonBlue,
                                  foregroundColor: Colors.black),
                              onPressed: isLoading ? null : _handleAuth,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                                    )
                                  : Text(isSignUp ? "REGISTER" : "ACCESS SYSTEM"),
                            ),
                          ),

                          const Spacer(),

                          // TOGGLE LOGIN/SIGNUP
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() {
                                isSignUp = !isSignUp;
                                _passwordController.clear();
                              }),
                              child: Text(
                                isSignUp
                                    ? "Have account? Login"
                                    : "Create Account",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CyberField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;

  const CyberField(
      {super.key,
      required this.label,
      this.isPassword = false,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.fontCode.copyWith(
                fontSize: 10, color: isDark ? Colors.white54 : Colors.grey)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.black45 : Colors.grey.shade200,
            border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: AppTheme.fontCode
                .copyWith(color: isDark ? Colors.white : Colors.black),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}