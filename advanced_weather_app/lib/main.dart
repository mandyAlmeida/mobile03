import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData.dark(),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _location = "No location selected";
  String _weatherInfo = "";
  String _hourlyWeather = "";
  String _weeklyWeather = "";
  List<Map<String, dynamic>> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = "35ecb04db738d79690cfde3b5a964e6a";

  // Nouveaux états pour le Weekly Tab
  List<Map<String, dynamic>> _weeklyForecastData = [];
  String _locationFull =
      ""; // affichera "City, Region, Country" (la région est ici "N/A")
  String _currentWeatherDescription = "";
  double _currentWindSpeed = 0.0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background.jpg"), // Ajoute l'image ici
          fit: BoxFit.cover, // Couvre tout l'écran
        ),
      ),
    );
  }

  /// 📌 Fetch weekly weather forecast
  Future<void> _fetchWeeklyWeather(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$_apiKey&units=metric",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // --- Partie existante : récupération d'un affichage textuel simplifié ---
        Map<String, dynamic> dailyData = {};
        for (var entry in data["list"]) {
          String date = entry["dt_txt"].split(" ")[0];
          if (!dailyData.containsKey(date)) {
            dailyData[date] = entry;
          }
        }
        setState(() {
          _weeklyWeather = dailyData.entries
              .map((entry) {
                return "${entry.key} - Min: ${entry.value["main"]["temp_min"]}°C - Max: ${entry.value["main"]["temp_max"]}°C - ${entry.value["weather"][0]["description"]}";
              })
              .join("\n");
        });

        // --- Nouvelle partie pour le Weekly Tab complet ---
        // Regroupement des prévisions par date
        Map<String, List<dynamic>> groupedData = {};
        for (var entry in data["list"]) {
          String date = entry["dt_txt"].split(" ")[0];
          if (!groupedData.containsKey(date)) {
            groupedData[date] = [];
          }
          groupedData[date]!.add(entry);
        }
        List<Map<String, dynamic>> forecastList = [];
        groupedData.forEach((date, entries) {
          double minTemp = entries
              .map<double>((e) => (e["main"]["temp_min"] as num).toDouble())
              .reduce((a, b) => a < b ? a : b);
          double maxTemp = entries
              .map<double>((e) => (e["main"]["temp_max"] as num).toDouble())
              .reduce((a, b) => a > b ? a : b);
          String weatherDescription = entries[0]["weather"][0]["description"];
          DateTime parsedDate = DateTime.parse(date);
          String dayName = _getDayName(parsedDate);
          forecastList.add({
            "date": date,
            "day": dayName,
            "min": minTemp,
            "max": maxTemp,
            "weather": weatherDescription,
          });
        });
        setState(() {
          // On prend les 7 premiers jours
          _weeklyForecastData = forecastList.take(7).toList();
          // Mise à jour de la localisation complète à partir des données de l'API forecast
          _locationFull =
              "${data['city']['name']}, N/A, ${data['city']['country']}";
        });
      }
    } catch (e) {
      setState(() {
        _weeklyWeather = "Error loading weekly forecast.";
      });
    }
  }

  /// 📌 Fetch hourly weather forecast
  List<Map<String, dynamic>> _hourlyTemperatures =
      []; // 🔥 Liste des données du graphique

  Future<void> _fetchHourlyWeather(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$_apiKey&units=metric",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List forecasts =
            data["list"]
                .take(10)
                .toList(); // 🔥 On prend 10 prévisions horaires

        setState(() {
          _hourlyTemperatures =
              forecasts.map((entry) {
                return {
                  "time": entry["dt_txt"].split(" ")[1].substring(0, 5),
                  "temp": entry["main"]["temp"],
                  "weather": entry["weather"][0]["description"],
                  "wind": entry["wind"]["speed"],
                };
              }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _hourlyWeather = "Error loading hourly forecast.";
      });
    }
  }

  Widget _buildTemperatureChart() {
    // Si aucune localisation n'est sélectionnée ou s'il n'y a pas de données horaires, ne pas afficher le graphique.
    if (_location == "No location selected" || _hourlyTemperatures.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(15),
        ),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX:
                _hourlyTemperatures.isNotEmpty
                    ? (_hourlyTemperatures.length - 1).toDouble()
                    : 0,
            minY: 0,
            maxY: 45,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < _hourlyTemperatures.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _hourlyTemperatures[index]["time"],
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const Text("");
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}°',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots:
                    _hourlyTemperatures.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        (e.value["temp"] as num).toDouble(),
                      );
                    }).toList(),
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyWeatherList() {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _hourlyTemperatures.length,
        itemBuilder: (context, index) {
          final forecast = _hourlyTemperatures[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(
                (0.3 * 255).toInt(),
              ), // Convertit 0.3 en valeur alpha 0-255,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  forecast["time"],
                  style: const TextStyle(color: Colors.white),
                ),
                Icon(
                  _getWeatherIcon(forecast["weather"]),
                  size: 30,
                  color: Colors.blueAccent,
                ),
                Text(
                  "${forecast["temp"]}°C",
                  style: const TextStyle(color: Colors.orange, fontSize: 16),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.air, size: 16, color: Colors.white),
                    Text(
                      "${forecast["wind"]} km/h",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 📌 Recherche des suggestions de ville
  Future<void> _fetchCitySuggestions(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    final url = Uri.parse(
      "https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$_apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions =
              data.map((city) {
                return {
                  "name": city["name"],
                  "region": city["state"] ?? "",
                  "country": city["country"],
                };
              }).toList();
        });
      }
    } catch (e) {
      setState(() => _suggestions = []);
    }
  }

  IconData _getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case "clear sky":
        return Icons.wb_sunny;
      case "few clouds":
        return Icons.wb_cloudy;
      case "scattered clouds":
        return Icons.cloud;
      case "broken clouds":
        return Icons.cloud_queue;
      case "shower rain":
        return Icons.grain;
      case "rain":
        return Icons.umbrella;
      case "thunderstorm":
        return Icons.flash_on;
      case "snow":
        return Icons.ac_unit;
      case "mist":
        return Icons.blur_on;
      default:
        return Icons.help_outline; // Icône par défaut
    }
  }

  /// 📌 Récupère la météo en fonction du nom de la ville
  Future<void> _fetchWeatherByCity(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _location = "${data['name']}, ${data['sys']['country']}";
          _weatherInfo =
              "${data['weather'][0]['description'].toUpperCase()} - ${data['main']['temp']}°C";
          _currentWeatherDescription = data['weather'][0]['description'];
          _currentWindSpeed = (data['wind']['speed'] as num).toDouble();
          _suggestions = [];
        });
        _fetchHourlyWeather(city);
        _fetchWeeklyWeather(city);
      } else {
        setState(() {
          _weatherInfo =
              "Could not find any result for the supplied address or coordinates.";
        });
      }
    } catch (e) {
      setState(() {
        _weatherInfo =
            "The service connection is lost, please check your internet connection or try again later.";
      });
    }
  }

  /// 📌 Récupère la météo par géolocalisation
  Future<void> _fetchWeatherByLocation() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric",
        );

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _currentWeatherDescription = data['weather'][0]['description'];
            _currentWindSpeed = (data['wind']['speed'] as num).toDouble();
            _location = "${data['name']}, ${data['sys']['country']}";
            _weatherInfo =
                "${data['weather'][0]['description'].toUpperCase()} - ${data['main']['temp']}°C - Wind: ${data['wind']['speed']} km/h";
          });
          _fetchHourlyWeather(data['name']);
          _fetchWeeklyWeather(data['name']);
        } else {
          setState(() {
            _weatherInfo =
                "Could not find any result for the supplied address or coordinates.";
          });
        }
      } catch (e) {
        setState(() {
          _weatherInfo =
              "The service connection is lost, please check your internet connection or try again later.";
        });
      }
    }
  }

  /// ----------------- Nouveaux Widgets pour le Weekly Tab -----------------

  // Retourne le nom du jour de la semaine à partir d'un objet DateTime
  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "";
    }
  }

  // Graphique pour les températures minimales et maximales sur la semaine
  Widget _buildWeeklyTemperatureChart() {
    if (_weeklyForecastData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text("No weekly data", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(15),
        ),
        child: LineChart(
          LineChartData(
            // Configuration des axes X et Y
            minX: 0,
            maxX:
                _weeklyForecastData.isNotEmpty
                    ? (_weeklyForecastData.length - 1).toDouble()
                    : 6,
            minY: 0,
            maxY: 45,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (_weeklyForecastData.isNotEmpty &&
                        index >= 0 &&
                        index < _weeklyForecastData.length) {
                      // Récupère la première lettre du jour
                      String day = _weeklyForecastData[index]["day"];
                      String firstLetter = day.substring(0, 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const Text("");
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}°',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.black.withAlpha((0.3 * 255).toInt()),
              ),
            ),
            // Les deux courbes : température min (bleu) et max (rouge)
            lineBarsData: [
              LineChartBarData(
                spots:
                    _weeklyForecastData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value["min"] as num).toDouble(),
                      );
                    }).toList(),
                isCurved: true,
                color: Colors.lightBlueAccent,
                barWidth: 3,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
              LineChartBarData(
                spots:
                    _weeklyForecastData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value["max"] as num).toDouble(),
                      );
                    }).toList(),
                isCurved: true,
                color: Colors.redAccent,
                barWidth: 3,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Contenu complet du tab Weekly
  Widget _buildWeeklyTabContent() {
    bool isError =
        _weeklyWeather.contains("Could not find") ||
        _weeklyWeather.contains("The service connection is lost");

    return Stack(
      children: [
        _buildBackground(),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Weekly Forecast",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _locationFull,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _buildWeeklyTemperatureChart(),
                const SizedBox(height: 20),
                // Liste scrollable des prévisions journalières
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _weeklyForecastData.length,
                    itemBuilder: (context, index) {
                      final dayForecast = _weeklyForecastData[index];
                      return ListTile(
                        leading: Text(
                          dayForecast["day"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        title: Text(
                          "Min: ${dayForecast["min"]}°C   -   Max: ${dayForecast["max"]}°C",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Icon(
                          _getWeatherIcon(dayForecast["weather"]),
                          color: Colors.blueAccent,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (isError)
                  Text(
                    _weeklyWeather,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _fetchWeatherByLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_suggestions.isNotEmpty) _buildSuggestionList(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  "Currently",
                  _weatherInfo,
                  weatherIcon: _currentWeatherDescription,
                  windSpeed: _currentWindSpeed,
                ), // 🔥 Ajout icône & vent
                _buildTabContent("Today", _hourlyWeather),
                // Remplacement du contenu Weekly par le widget complet
                _buildWeeklyTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 📌 Barre de recherche avec suggestions
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search location...",
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: _fetchCitySuggestions,
        onSubmitted: _fetchWeatherByCity,
      ),
    );
  }

  /// 📌 Liste des suggestions de ville
  Widget _buildSuggestionList() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children:
            _suggestions.map((city) {
              return ListTile(
                title: Text(
                  "${city["name"]}, ${city["region"]}",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  city["country"],
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  _fetchWeatherByCity(city["name"]!);
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTabContent(
    String tabName,
    String data, {
    String? weatherIcon,
    double? windSpeed,
  }) {
    bool isError =
        data.contains("Could not find") ||
        data.contains("The service connection is lost");

    if (_location == "No location selected") {
      return Stack(
        children: [
          _buildBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tabName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "No location selected",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _buildBackground(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tabName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _location,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(height: 5),
            if (tabName == "Today") ...[
              _buildTemperatureChart(), // Graphique pour Today
              _buildHourlyWeatherList(), // Liste des prévisions horaires
            ] else if (tabName == "Currently") ...[
              Text(
                data,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: isError ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              if (weatherIcon != null)
                Icon(
                  _getWeatherIcon(weatherIcon),
                  size: 50,
                  color: Colors.blueAccent,
                ),
              if (windSpeed != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.air, size: 24, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      "$windSpeed km/h",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orange,
        labelColor: Colors.orange,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(icon: Icon(Icons.wb_sunny), text: "Currently"),
          Tab(icon: Icon(Icons.today), text: "Today"),
          Tab(icon: Icon(Icons.calendar_view_week), text: "Weekly"),
        ],
      ),
    );
  }
}
