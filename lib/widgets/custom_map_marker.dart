import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/theme_provider.dart'; // Import for AppColors

enum MarkerType { start, end, current, poi }

class CustomMapMarker extends Marker {
  CustomMapMarker({
    required LatLng point,
    required MarkerType type,
    VoidCallback? onTap,
    double size = 30.0, // Default size
  }) : super(
         point: point,
         width: size,
         height: size,
         // Use builder instead of child
         builder: (ctx) => _buildMarkerIcon(type, size),
         // anchorPos: AnchorPos.align(AnchorAlign.top), // Adjust anchor if needed
       );

  static Widget _buildMarkerIcon(MarkerType type, double size) {
    IconData iconData;
    Color color;
    Color iconColor = Colors.white; // Default icon color

    switch (type) {
      case MarkerType.start:
        iconData = Icons.flag;
        color = Colors.green;
        break;
      case MarkerType.end:
        iconData = Icons.sports_score;
        color = Colors.red;
        break;
      case MarkerType.current:
        iconData = Icons.my_location;
        color = AppColors.primary; // Use theme primary color
        break;
      case MarkerType.poi:
        iconData = Icons.location_pin;
        color = AppColors.secondary; // Use theme secondary color
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.6, // Make icon slightly smaller than container
          color: iconColor,
        ),
      ),
    );
  }
}

// Helper function to easily create markers (optional but convenient)
Marker createMarker({
  required double lat,
  required double lng,
  required MarkerType type,
  VoidCallback? onTap,
  double size = 30.0,
}) {
  return CustomMapMarker(
    point: LatLng(lat, lng),
    type: type,
    onTap: onTap,
    size: size,
  );
}

// AppColors is imported from theme_provider.dart
