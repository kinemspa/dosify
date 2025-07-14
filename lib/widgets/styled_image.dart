import 'package:flutter/material.dart';

class StyledImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsets? padding;

  const StyledImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
    );

    // Apply padding if specified
    if (padding != null) {
      image = Padding(
        padding: padding!,
        child: image,
      );
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    // Apply elevation and background color if specified
    if (elevation != null || backgroundColor != null) {
      image = Material(
        elevation: elevation ?? 0,
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius,
        child: image,
      );
    }

    return image;
  }

  // Factory constructors for common use cases
  factory StyledImage.rounded({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    double radius = 8.0,
  }) {
    return StyledImage(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  factory StyledImage.card({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    double radius = 12.0,
    Color backgroundColor = Colors.white,
    double elevation = 2.0,
    EdgeInsets padding = const EdgeInsets.all(8.0),
  }) {
    return StyledImage(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(radius),
      backgroundColor: backgroundColor,
      elevation: elevation,
      padding: padding,
    );
  }
} 