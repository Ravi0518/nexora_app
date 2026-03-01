import 'package:flutter/material.dart';

class EnthusiastHistoryTab extends StatelessWidget {
  final String lang;

  const EnthusiastHistoryTab({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    // Mock History for now. Connect to NexoraApiService.getHistory later.
    final history = [
      {
        'date': 'Today, 10:30 AM',
        'species': 'Rat Snake (Non-venomous)',
        'location': 'Mihintale',
        'status': 'Caught'
      },
      {
        'date': 'Yesterday, 4:15 PM',
        'species': 'Russell\'s Viper (Venomous)',
        'location': 'Anuradhapura',
        'status': 'Caught'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text('Past Rescues',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          );
        }

        final item = history[index - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A261D),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.history, color: Color(0xFF00FF66)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['species']!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${item['location']} • ${item['date']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Text(item['status']!,
                  style: const TextStyle(
                      color: Color(0xFF00FF66),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
