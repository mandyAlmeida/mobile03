import 'package:flutter/material.dart';
import './page_currently.dart';
import './page_today.dart' as today_page;
import './page_weekly.dart' as weekly;
import './searcher.dart';

class BodyOfApp extends StatelessWidget {
  final String text;
  final String errorText;
  final TabController controller;
  final Map<String, String> location;
  final Map<String, String> current;
  final Map<String, Map<String, String>> today;
  final Map<String, Map<String, String>> week;
  final dynamic listOfCities;
  final Function(String newText) changeText;
  final Function(double, double) changeLatAndLong;
  final Function(String, String, String) changeLocation;

  const BodyOfApp({
    Key? key,
    required this.text,
    required this.errorText,
    required this.controller,
    required this.location,
    required this.current,
    required this.today,
    required this.week,
    required this.listOfCities,
    required this.changeText,
    required this.changeLatAndLong,
    required this.changeLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se houver texto na barra de pesquisa, exibe a página de sugestões de cidade.
    if (text.isNotEmpty) {
      return CityInfoPage(
        listOfCities: listOfCities,
        changeText: changeText,
        changeLatAndLong: changeLatAndLong,
        changeLocation: changeLocation,
        errorText: errorText,
      );
    }
    // Caso contrário, exibe as tabs com os dados do clima.
    return Column(
      children: [
        // Aqui você pode inserir sua SearchBar personalizada, se desejar.
        // Exemplo: SearchBar(...),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              CurrentlyPage(
                coord: location,
                current: current,
                errorText: errorText,
              ),
              today_page.TodayPage(
                coord: location,
                today: today,
                errorText: errorText,
              ),
              weekly.WeeklyPage(
                coord: location,
                weekly: week,
                errorText: errorText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
