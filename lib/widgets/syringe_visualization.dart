import 'package:flutter/material.dart';

class SyringeVisualization extends StatelessWidget {
  final double syringeSize; // Total syringe size in mL
  final double targetVolume; // Target volume to highlight
  final bool isDarkMode; // Whether to use dark mode colors
  final Color? fillColor; // Color for the syringe fill

  const SyringeVisualization({
    super.key,
    required this.syringeSize,
    required this.targetVolume,
    this.isDarkMode = true,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate fill percentage (clamped between 0-100%)
    final fillPercentage = (targetVolume / syringeSize).clamp(0.0, 1.0);
    
    final primaryColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? const Color(0xFF1E2B3D) : Colors.grey[100];
    final highlightColor = Colors.blue[500]!;
    final actualFillColor = fillColor ?? Colors.blue[300]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        return Container(
          height: 110, // Increased height for better padding
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Syringe body
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                bottom: 40, // Increased bottom padding for scale numbers
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
                  ),
                ),
              ),
              
              // Fill indicator - constrained to syringe body width
              Positioned(
                left: 16,
                top: 16,
                bottom: 40, // Increased bottom padding for scale numbers
                width: (availableWidth - 32) * fillPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: actualFillColor.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(3),
                      bottomLeft: const Radius.circular(3),
                      topRight: fillPercentage >= 0.99 ? const Radius.circular(3) : Radius.zero,
                      bottomRight: fillPercentage >= 0.99 ? const Radius.circular(3) : Radius.zero,
                    ),
                  ),
                ),
              ),
              
              // Scale markings
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  painter: ScalePainter(
                    maxValue: syringeSize,
                    primaryColor: primaryColor,
                    targetValue: targetVolume,
                    highlightColor: highlightColor,
                    syringeSize: syringeSize,
                    availableWidth: availableWidth,
                  ),
                ),
              ),
              
              // Syringe size indicator
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$syringeSize mL Syringe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Target volume indicator
              Positioned(
                left: 16 + ((availableWidth - 32) * fillPercentage),
                top: 16,
                bottom: 40, // Increased bottom padding for scale numbers
                child: Container(
                  width: 2,
                  color: highlightColor,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class ScalePainter extends CustomPainter {
  final double maxValue; // Maximum value in mL
  final Color primaryColor;
  final double targetValue; // Target value in mL
  final Color highlightColor;
  final double syringeSize;
  final double availableWidth;

  ScalePainter({
    required this.maxValue,
    required this.primaryColor,
    required this.targetValue,
    required this.highlightColor,
    required this.syringeSize,
    required this.availableWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.7)
      ..strokeWidth = 1;

    // Determine how many major divisions to show based on syringe size
    int divisions;
    double increment;
    
    if (syringeSize <= 0.3) {
      divisions = 6; // 0.05mL increments for 0.3mL syringe
      increment = 0.05;
    } else if (syringeSize <= 0.5) {
      divisions = 5; // 0.1mL increments for 0.5mL syringe
      increment = 0.1;
    } else if (syringeSize <= 1.0) {
      divisions = 10; // 0.1mL increments for 1mL syringe
      increment = 0.1;
    } else if (syringeSize <= 3.0) {
      divisions = 6; // 0.5mL increments for 3mL syringe
      increment = 0.5;
    } else {
      divisions = 10; // 0.5mL increments for 5mL syringe
      increment = 0.5;
    }
    
    final usableWidth = availableWidth - 32; // Account for left/right padding
    final spacing = usableWidth / divisions;

    for (var i = 0; i <= divisions; i++) {
      final x = 16 + (i * spacing);
      final value = i * increment;
      
      // Major tick
      canvas.drawLine(
        Offset(x, size.height - 40), // Bottom of syringe body
        Offset(x, size.height - 30), // Length of tick mark
        paint,
      );

      // Draw tick label for major divisions
      if (i % 2 == 0 || divisions <= 6) { // Show all labels for small divisions
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
            style: TextStyle(color: primaryColor, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // Center the text under the tick
        final textX = x - (textPainter.width / 2);
        final textY = size.height - 28; // Position text below tick mark
        
        // Draw a background rectangle for better visibility
        final bgRect = Rect.fromLTWH(
          textX - 2, 
          textY - 2, 
          textPainter.width + 4, 
          textPainter.height + 2
        );
        
        final bgPaint = Paint()..color = Color(0xFF1E2B3D);
        canvas.drawRect(bgRect, bgPaint);
        
        textPainter.paint(canvas, Offset(textX, textY));
      }

      // Minor ticks
      if (i < divisions && spacing > 15) {
        for (var j = 1; j < 5; j++) {
          final minorX = x + (spacing * j / 5);
          canvas.drawLine(
            Offset(minorX, size.height - 38),
            Offset(minorX, size.height - 32),
            paint,
          );
        }
      }
    }
    
    // Draw the 0 and max labels with better positioning
    final zeroTextPainter = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    zeroTextPainter.layout();
    
    final maxTextPainter = TextPainter(
      text: TextSpan(
        text: '${syringeSize.toStringAsFixed(1)} mL',
        style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    maxTextPainter.layout();
    
    // Draw background rectangles for the labels
    final zeroBgRect = Rect.fromLTWH(
      14, 
      size.height - 18, 
      zeroTextPainter.width + 4, 
      zeroTextPainter.height + 2
    );
    
    final maxBgRect = Rect.fromLTWH(
      availableWidth - maxTextPainter.width - 18, 
      size.height - 18, 
      maxTextPainter.width + 4, 
      maxTextPainter.height + 2
    );
    
    final bgPaint = Paint()..color = Color(0xFF1E2B3D);
    canvas.drawRect(zeroBgRect, bgPaint);
    canvas.drawRect(maxBgRect, bgPaint);
    
    // Draw the labels
    zeroTextPainter.paint(canvas, Offset(16, size.height - 18));
    maxTextPainter.paint(canvas, Offset(availableWidth - maxTextPainter.width - 16, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 