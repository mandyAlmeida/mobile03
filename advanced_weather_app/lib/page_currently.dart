import 'package:flutter/material.dart';
import './error_message.dart';

class CurrentlyPage extends StatelessWidget {
  const CurrentlyPage({
    super.key,
    required this.coord,
    required this.current,
    required this.errorText,
  });

  final Map<String, String> coord;
  final Map<String, String> current;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    return errorText.isEmpty
        ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coord['cityName']?.isNotEmpty == true
                    ? coord['cityName']!
                    : 'Unknown city',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                coord['region']?.isNotEmpty == true ? coord['region']! : '',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                coord['country']?.isNotEmpty == true ? coord['country']! : '',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                'Temperature: ${current['temp']?.isNotEmpty == true ? current['temp'] : 'N/A'}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Weather: ${current['weather']?.isNotEmpty == true ? current['weather'] : 'N/A'}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Wind Speed: ${current['wind']?.isNotEmpty == true ? current['wind'] : 'N/A'}',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        )
        : ErrorMessage(errorMessage: errorText);
  }
}
