import 'package:flutter/material.dart';

class PlaceholderImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PlaceholderImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final color = getColorForImage(imageUrl);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 40,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

// Helper to get color for placeholder images
Color getColorForImage(String imageUrl) {
  final colorMap = {
    'tan_polo': const Color(0xFFD2B48C),
    'silver_chain': const Color(0xFFC0C0C0),
    'silver_watch': const Color(0xFFA9A9A9),
    'tan_khakis': const Color(0xFFF5DEB3),
    'blue_jeans': const Color(0xFF4169E1),
    'blue_jeans_2': const Color(0xFF1E90FF),
    'olive_cargo': const Color(0xFF556B2F),
    'olive_cargo_2': const Color(0xFF6B8E23),
    'cream_shorts': const Color(0xFFFFFACD),
    'pink_shorts': const Color(0xFFFFB6C1),
    'dark_cream_ls': const Color(0xFFD2B48C),
    'cream_ls': const Color(0xFFFFF8DC),
    'white_ls': const Color(0xFFF5F5F5),
    'blue_tee': const Color(0xFF1E90FF),
    'blue_tee_2': const Color(0xFF4682B4),
    'white_tee': const Color(0xFFFFFFFF),
    'casual_outfit': const Color(0xFF808080),
    'denim_look': const Color(0xFF2F4F4F),
    'street_style': const Color(0xFF708090),
    'urban_threads': const Color(0xFFFF6B6B),
    'minimal_basics': const Color(0xFF4ECDC4),
    'vintage_revival': const Color(0xFF95E1D3),
    'athleisure_lab': const Color(0xFFF38181),
    'black_tee': const Color(0xFF1A1A1A),
    'black_crewneck': const Color(0xFF2C2C2C),
    'white_polo': const Color(0xFFFAFAFA),
    'white_sneakers': const Color(0xFFF8F8F8),
    'blue_paris': const Color(0xFF1E3A5F),
    'blue_button_up': const Color(0xFF87CEEB),
  };
  return colorMap[imageUrl] ?? const Color(0xFFCCCCCC);
}