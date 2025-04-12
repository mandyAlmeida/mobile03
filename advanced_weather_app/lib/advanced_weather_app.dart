import 'dart:convert';
import './app_body.dart';
import './app_bottom_bar.dart';
import './geolocation.dart';
import './app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> with TickerProviderStateMixin {
  final Color _iconColor = Colors.white;
  final Color _backgroundColor = const Color.fromARGB(255, 10, 10, 10);
  late TabController _tabController;
  bool _locationAllowed = true;
  bool _isBusy = true;
  dynamic _listOfCities;
  final Map<String, String> _location = {
    'cityName': '',
    'region': '',
    'country': '',
    'lat': '',
    'long': '',
  };
  final Map<String, String> _weatherMap = {
    '0': 'Clear sky',
    '1': 'Mainly clear',
    '2': 'Partly cloudy',
    '3': 'Overcast',
    '45': 'Fog and depositing rime fog',
    '48': 'Fog and depositing rime fog',
    '51': 'Drizzle: Light intensity',
    '53': 'Drizzle: Moderate intensity',
    '55': 'Drizzle: Dense intensity',
    '56': 'Freezing Drizzle: Light intensity',
    '57': 'Freezing Drizzle: Dense intensity',
    '61': 'Rain: Slight intensity',
    '63': 'Rain: Moderate intensity',
    '65': 'Rain: Heavy intensity',
    '66': 'Freezing Rain: Light intensity',
    '67': 'Freezing Rain: Heavy intensity',
    '71': 'Snow fall: Slight intensity',
    '73': 'Snow fall: Moderate intensity',
    '75': 'Snow fall: Heavy intensity',
    '77': 'Snow grains',
    '80': 'Rain showers: Slight intensity',
    '81': 'Rain showers: Moderate intensity',
    '82': 'Rain showers: Violent intensity',
    '85': 'Snow showers: Slight intensity',
    '86': 'Snow showers: Heavy intensity',
    '95': 'Thunderstorm: Slight or moderate',
    '96': 'Thunderstorm with slight hail',
    '99': 'Thunderstorm with heavy hail',
  };

  final _current = {'temp': '', 'weather': '', 'wind': ''};
  final Map<String, Map<String, String>> _today = {};
  final Map<String, Map<String, String>> _week = {};

  String _text = "";
  String _errorText = "";
  final String errorAPI = "No Connexion\nPlease check your Internet connexion";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 0, length: 3, vsync: this);
    _initializeLocation();
  }

  void _initializeLocation() async {
    setState(() {
      _isBusy = true;
    });

    final locationService = LocationService();
    final permissionGranted = await locationService.requestPermission();
    if (!permissionGranted) {
      setState(() {
        _locationAllowed = false;
        _isBusy = false;
      });
      return;
    }

    try {
      final locationData = await locationService.getCurrentLocation();
      final lat = locationData.latitude!;
      final long = locationData.longitude!;
      changeLatAndLong(lat, long); // Removido 'await'
      setState(() {
        _locationAllowed = true;
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _locationAllowed = false;
        _isBusy = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void changeErrorText(String error) {
    setState(() {
      _errorText = error;
    });
  }

  void changeText(String newText) {
    setState(() {
      _text = newText;
    });
  }

  void changeLatAndLong(double lat, double long) async {
    setState(() {
      _isBusy = true;
      _location['lat'] = lat.toString();
      _location['long'] = long.toString();
    });

    if (_location['lat']!.isNotEmpty && _location['long']!.isNotEmpty) {
      await getCurrentInfo(_location['lat']!, _location['long']!);
      await getTodayInfo(_location['lat']!, _location['long']!);
      await getWeeklyInfo(_location['lat']!, _location['long']!);
    }

    setState(() {
      _isBusy = false;
    });
  }

  void changeLocation(String name, String region, String country) {
    setState(() {
      _location['cityName'] = name;
      _location['region'] = region;
      _location['country'] = country;
    });
  }

  Future<void> getCityInfo(String cityName) async {
    cityName = _text;
    final url =
        'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=10&language=en&format=json';

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      setState(() {
        _listOfCities = responseData["results"];
      });
      changeErrorText('');
    } catch (e) {
      changeErrorText(errorAPI);
      throw Exception("$e");
    }
  }

  Future<void> getCurrentInfo(String lat, String long) async {
    var url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long&current_weather=true&weather_code';

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (responseData != null) {
        setState(() {
          _current['temp'] =
              "${responseData['current_weather']['temperature']}°C";
          var code = responseData['current_weather']['weathercode'];
          _current['weather'] = _weatherMap[code.toString()]!;
          _current['wind'] =
              "${responseData['current_weather']['windspeed']} km/h";
        });
        changeErrorText('');
      }
    } catch (e) {
      changeErrorText(errorAPI);

      throw Exception("$e");
    }
  }

  Future<void> getTodayInfo(String lat, String long) async {
    var url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long&hourly=temperature_2m,weather_code,wind_speed_10m';
    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);

      if (responseData != null) {
        setState(() {
          int i = 0;
          while (i < 24) {
            String hourAndDay = responseData["hourly"]['time'][i].toString();
            String hour = hourAndDay.substring(11);
            String temp =
                responseData["hourly"]['temperature_2m'][i].toString();
            String wcode = responseData["hourly"]['weather_code'][i].toString();
            String weather = _weatherMap[wcode] ?? '';
            String wind =
                responseData["hourly"]['wind_speed_10m'][i].toString();
            String index = i.toString();
            _today[index] = {
              'hour': hour,
              'temp': "$temp°C",
              'weather': weather,
              'wind': "$wind km/h",
            };
            i++;
          }
        });
        changeErrorText('');
      }
    } catch (e) {
      changeErrorText(errorAPI);
      throw Exception("$e");
    }
  }

  Future<void> getWeeklyInfo(String lat, String long) async {
    DateTime now = DateTime.now();
    String startDate = now.toIso8601String().substring(0, 10);
    String endDate = now
        .add(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);

    var url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        "&timezone=GMT&start_date=$startDate&end_date=$endDate";

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = json.decode(response.body);
      if (responseData != null) {
        setState(() {
          _week.clear(); // Garante que não acumule dados antigos
          int i = 0;
          while (i < 7) {
            String date = responseData['daily']['time'][i].toString();
            String max =
                responseData['daily']['temperature_2m_max'][i].toString();
            String min =
                responseData['daily']['temperature_2m_min'][i].toString();
            String wcode = responseData['daily']['weather_code'][i].toString();
            String weather = _weatherMap[wcode] ?? '';
            _week[i.toString()] = {
              'date': date.replaceAll("-", "/"),
              'tempMin': "$min°C",
              'tempMax': "$max°C",
              'weather': weather,
            };
            i++;
          }
        });
        changeErrorText('');
      }
    } catch (e) {
      changeErrorText(errorAPI);
      throw Exception("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyTopBar(
        changeText: changeText,
        changeErrorText: changeErrorText,
        text: _text,
        backgroundColor: _backgroundColor,
        getCityInfo: getCityInfo,
        changeLatAndLong: changeLatAndLong,
        changeLocation: changeLocation,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background1.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child:
            _isBusy
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : !_locationAllowed
                ? const Center(
                  child: Text(
                    'Location permission denied.\nPlease enable location access in settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                )
                : _errorText.isEmpty
                ? _location['cityName']!.isNotEmpty || _text.isNotEmpty
                    ? BodyOfApp(
                      current: _current,
                      location: _location,
                      today: _today,
                      week: _week,
                      listOfCities: _listOfCities,
                      text: _text,
                      controller: _tabController,
                      changeText: changeText,
                      changeLatAndLong: changeLatAndLong,
                      changeLocation: changeLocation,
                      errorText: _errorText,
                    )
                    : const Center(
                      child: Text(
                        'Please search a location\nor\nuse the geolocation button',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                : ErrorMessage(errorMessage: _errorText),
      ),
      bottomNavigationBar: BottomBar(
        backgroundColor: _backgroundColor,
        iconColor: _iconColor,
        tabController: _tabController,
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String errorMessage;

  const ErrorMessage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        errorMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red, fontSize: 18),
      ),
    );
  }
}
