import 'package:dio/dio.dart';
import 'dart:io';

/// PROFESSIONAL ENGLISH DOCUMENTATION
/// * CLASS: ApiService
/// PURPOSE: Transmits image data to the Azure-hosted CNN model for identification.
/// * TECHNICAL LOGIC:
/// 1. Endpoint: Uses the provided Azure URL for the /predict endpoint.
/// 2. Payload: Wraps the image file in a FormData object (Multi-part request).
/// 3. Exception Handling: Catches network timeouts or server-side crashes during inference.

class ApiService {
  // English: Your Azure API Endpoint
  final String _azureUrl =
      "https://snake-api-eshan123.azurewebsites.net/predict";
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> identifySnake(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      // English: Creating the Multi-part form data request
      FormData formData = FormData.fromMap({
        "file":
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      var response = await _dio.post(_azureUrl, data: formData);

      if (response.statusCode == 200) {
        // English: The API returns the snake ID and confidence score
        return response.data;
      }
      return null;
    } catch (e) {
      print("Nexora API Error (Azure): $e");
      return null;
    }
  }
}
