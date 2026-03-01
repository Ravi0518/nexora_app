import 'dart:convert';
import 'package:flutter/services.dart';

class SnakeService {
  static Future<Map<String, dynamic>?> getFullDetails(String topSpecies) async {
    // 1. Load Mapping & Details
    final String mapRes = await rootBundle.loadString('assets/class_mapping.json');
    final String snakeRes = await rootBundle.loadString('assets/data/snakes.json');

    final Map<String, dynamic> mapping = json.decode(mapRes);
    final List<dynamic> snakes = json.decode(snakeRes);

    // 2. Format ID to match (e.g., "Indian cobra" -> "indian_cobra")
    String targetId = topSpecies.toLowerCase().replaceAll(' ', '_');

    // 3. Find match in snakes.json
    final snakeDetails = snakes.firstWhere(
          (s) => s['id'] == targetId,
      orElse: () => null,
    );

    if (snakeDetails != null) {
      // Add venom status from mapping file
      snakeDetails['venom_label'] = mapping['venom_status'][topSpecies] ?? "Unknown Status";
      return snakeDetails;
    }
    return null;
  }
}