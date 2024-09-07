import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/sign_in_page.dart';
import '../pages/home_page.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: LetterFormation(
          text: 'RIDERAPP',
          animationController: _animationController,
        ),
      ),
    );
  }
}

class LetterFormation extends StatelessWidget {
  final String text;
  final AnimationController animationController;

  const LetterFormation({super.key,
    required this.text,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> letterWidgets = text
        .split('')
        .asMap()
        .entries
        .map((entry) {
      int index = entry.key;
      String letter = entry.value;
      return AnimatedLetter(
        letter: letter,
        animationController: animationController,
        delay: Duration(milliseconds: 100 * index),
      );
    })
        .toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: letterWidgets,
    );
  }
}

class AnimatedLetter extends StatelessWidget {
  final String letter;
  final AnimationController animationController;
  final Duration delay;

  const AnimatedLetter({super.key,
    required this.letter,
    required this.animationController,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        delay.inMilliseconds / 3000,
        (delay.inMilliseconds + 300) / 3000,
        curve: Curves.easeInOut,
      ),
    );

    final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
    final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(animation);
    final positionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(
      position: positionAnimation,
      child: FadeTransition(
        opacity: opacityAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 62,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}


