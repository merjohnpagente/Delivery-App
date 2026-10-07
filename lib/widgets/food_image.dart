import 'package:flutter/material.dart';

/// Displays a food image from either a bundled asset or a network URL.
class FoodImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const FoodImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isNetwork => image.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, color: Colors.orange, size: 40),
    );

    Widget img;
    if (image.isEmpty) {
      img = placeholder;
    } else if (_isNetwork) {
      img = Image.network(
        image,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      img = Image.asset(
        image,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
