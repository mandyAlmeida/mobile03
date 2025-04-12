import 'package:flutter/material.dart';
import 'package:advanced_weather_app/advanced_weather_app.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App de Clima',
      debugShowCheckedModeBanner: false,
      home: const AppWithBackground(),
    );
  }
}

class AppWithBackground extends StatelessWidget {
  const AppWithBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Fundo transparente para mostrar a imagem
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo que cobre a tela inteira
          Image.asset('assets/images/background1.jpeg', fit: BoxFit.cover),
          // Conteúdo principal do aplicativo
          const SafeArea(child: WeatherApp()),
        ],
      ),
    );
  }
}
