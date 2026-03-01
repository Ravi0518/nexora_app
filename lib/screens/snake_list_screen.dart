import 'package:flutter/material.dart';
import 'id_result_screen.dart';

// Change "SnakeListScreen" to "CollectionScreen"
class CollectionScreen extends StatelessWidget {
  final List<dynamic> allSnakes;
  final String lang;

  const CollectionScreen({super.key, required this.allSnakes, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        title: Text(
          lang == 'si' ? "සර්ප එකතුව" : (lang == 'ta' ? "பாம்பு சேகரிப்பு" : "Snake Collection"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: allSnakes.length,
        itemBuilder: (context, index) {
          final snake = allSnakes[index];
          final bool isVenomous = snake['is_venomous'] ?? false;
          final Color statusColor = isVenomous ? Colors.redAccent : const Color(0xFF00FF66);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IDResultScreen(
                    snakeData: {
                      'top_prediction': {'species': snake['id']}
                    },
                    currentLang: lang,
                    confidenceScore: double.tryParse(snake['confidence']?.toString().replaceAll('%', '') ?? '100') ?? 100.0,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131A14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      snake['main_image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snake['names'][lang] ?? snake['names']['en'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          snake['scientific_name'],
                          style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            snake['danger_level'][lang] ?? snake['danger_level']['en'],
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}