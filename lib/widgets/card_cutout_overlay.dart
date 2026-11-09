import 'package:flutter/material.dart';

class CardCutoutOverlay extends StatelessWidget {
  final Rect cutoutRect;
  final bool isTorchOn;
  final VoidCallback onToggleTorch;

  const CardCutoutOverlay({
    super.key,
    required this.cutoutRect,
    required this.isTorchOn,
    required this.onToggleTorch,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _CardCutoutPainter(cutoutRect: cutoutRect),
    );
  }
}

class _CardCutoutPainter extends CustomPainter {
  final Rect cutoutRect;

  _CardCutoutPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dark translucent overlay with cutout hole
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.68)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final rrect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16));
    final cutoutPath = Path()..addRRect(rrect);

    // Difference between whole screen and card cutout
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, backgroundPaint);

    // 2. Draw card frame border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Draw stylish Corner Brackets (Amber / Pokeball Yellow)
    final cornerPaint = Paint()
      ..color = const Color(0xFFFFCB05) // Official Pokemon yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-Left
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + cornerLength),
      Offset(cutoutRect.left, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top),
      Offset(cutoutRect.left + cornerLength, cutoutRect.top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(cutoutRect.right - cornerLength, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - cornerLength),
      Offset(cutoutRect.left, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom),
      Offset(cutoutRect.left + cornerLength, cutoutRect.bottom),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(cutoutRect.right - cornerLength, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom - cornerLength),
      cornerPaint,
    );

    // 4. Subtle guide zones for Card Name (Header) and Set Info (Footer)
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Header guide line (~18% from top)
    final headerY = cutoutRect.top + (cutoutRect.height * 0.18);
    canvas.drawLine(
      Offset(cutoutRect.left + 14, headerY),
      Offset(cutoutRect.right - 14, headerY),
      guidePaint,
    );

    // Footer guide line (~84% from top)
    final footerY = cutoutRect.top + (cutoutRect.height * 0.84);
    canvas.drawLine(
      Offset(cutoutRect.left + 14, footerY),
      Offset(cutoutRect.right - 14, footerY),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CardCutoutPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}

