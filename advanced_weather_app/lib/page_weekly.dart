import 'package:flutter/material.dart';

class WeeklyPage extends StatelessWidget {
  final Map<String, dynamic> coord;
  final Map<String, dynamic> weekly;
  final String? errorText;

  const WeeklyPage({
    super.key,
    required this.coord,
    required this.weekly,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(child: Text(coord['cityName'] ?? 'Unknown city')),
        Center(child: Text(coord['region'] ?? '')),
        Center(child: Text(coord['country'] ?? '')),
        const SizedBox(height: 16),
        ...weekly.entries.map((entry) {
          final date = entry.value['date'] ?? 'Unknown';
          final tempMin = entry.value['tempMin'] ?? '-';
          final tempMax = entry.value['tempMax'] ?? '-';
          final weather = entry.value['weather'] ?? 'Unknown';
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Min: $tempMin   Max: $tempMax'),
                Text('Weather: $weather'),
                const Divider(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
