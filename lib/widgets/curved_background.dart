import 'package:flutter/material.dart';

class CurvedTopBackground extends StatelessWidget {
  final double height;
  const CurvedTopBackground({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TopClipper(),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF344D59), Color(0xFF52B8AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}

class TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height + 20, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BottomCurvedBackground extends StatelessWidget {
  final double height;
  const BottomCurvedBackground({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomClipper(),
      child: Container(
        height: height,
        color: const Color(0xFFE8F2F1), // Light green-ish color at bottom
      ),
    );
  }
}

class BottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 50);
    path.quadraticBezierTo(
        size.width / 2, -20, size.width, 50);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
