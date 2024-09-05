import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:weather/weather.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import "package:provider/provider.dart";
import 'package:intl/intl.dart';
import '../widgets/navigation.dart';
import '../consts.dart';
import '../widgets/fun.dart';

DateTime now = DateTime.now();
String city = 'Hanoi';

class DashboardHome extends StatefulWidget {
  final User user;

  const DashboardHome({Key? key, required this.user}) : super(key: key);
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<DashboardHome> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  late Future<List<FlSpot>> _spotsFuture = Future.value([]);

  List<dynamic> dataThingSpeak = [];

  Weather? _weather;

  @override
  void initState() {
    super.initState();
    // Fetch current weather and update state
    _fetchWeather();
    // Fetch data asynchronously
    _spotsFuture = _grabData();

    // _spotsFuture = _fetchDataFromThingSpeak(dataThingSpeak);
  }

  Future<void> _getCity() async {
    await getCity;
  }

  Future<void> getCity() async {
    var email = widget.user.email;
    final response = await http.post(
      Uri.parse('http://192.168.1.20:3000/getCity'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
      }),
    );
    if (response.statusCode == 200) {
      String data = jsonDecode(response.body);

      setState(() {
        city = data;
      });
    } else if (response.statusCode == 404) {
      print('Email not found');
    } else {
      throw Exception('Failed to send email');
    }
  }

  Future<Weather> _fetchWeather() async {
    Weather weather; // Declare the variable without initializing it

    try {
      weather = await _wf.currentWeatherByCityName(
          city); // Try to get weather for the provided city
    } catch (e) {
      print(
          'City not found or error occurred, fetching data for Hanoi instead.');
      try {
        weather = await _wf
            .currentWeatherByCityName('Hanoi'); // Try to get weather for Hanoi
      } catch (e) {
        print('Failed to fetch weather data for Hanoi as well.');
        rethrow; // If we can't fetch weather even for Hanoi, rethrow the error
      }
    }

    setState(() {
      _weather = weather;
    });

    return weather;
  }

// Define the async method
  Future<List<FlSpot>> _fetchData() async {
    List<dynamic> data = [];
    try {
      data = await fetchData();
      setState(() {
        dataThingSpeak = data;
      });

      return await fetchDataFromThingSpeak(data);
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<List<FlSpot>> _grabData() async {
    try {
      List<FlSpot> spots = await _fetchData();
      setState(() {
        _spotsFuture = Future.value(spots);
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
    return _spotsFuture;
  }

  Widget build(BuildContext) {
    return Scaffold(
      drawer: NavigationPanel(user: FirebaseAuth.instance.currentUser!),
      appBar: AppBar(
        title: Text(
          'Home Smart',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1E2026),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildUI(),
    );
  }

  @override
  Widget _buildUI() {
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;

    return Scrollbar(
      child: Row(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12 / 2),
              child: Column(
                children: [
                  Container(
                    width: WidthScreen - 12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            WeatherInfo(
                              title: 'Weather',
                              date: now,
                              content:
                                  ('${_weather?.weatherDescription ?? "N/A"}'),
                              weatherState: _getWeather(
                                  '${_weather?.weatherDescription ?? "N/A"}'),
                              size: 2,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          children: [
                            HumidityInfo(
                              title: 'Humidity',
                              content:
                                  '${_weather?.humidity?.toStringAsFixed(0) ?? "N/A"}%',
                              size: 1,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            TemperatureInfo(
                              title: 'Temperature',
                              data: '${_weather?.temperature?.celsius ?? 0}',
                              size: 1,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          children: [
                            TemperatureInfo(
                              title:
                                  '${widget.user.email ?? 'No display name'}',
                              data: dataThingSpeak.isNotEmpty
                                  ? dataThingSpeak[0]['field1'] ?? '0'
                                  : '0',
                              size: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FutureBuilder<List<FlSpot>>(
                              future: _spotsFuture,
                              builder: (context, snapshot) {
                                print(snapshot.data);
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text('No data available'));
                                } else {
                                  return GraphTemp(
                                    size: 2,
                                    thingdata: snapshot.data! ?? [],
                                  );
                                }
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // TODO: implement widget
  DashboardHome get widget => super.widget;

  bool isDaytime() {
    int dateTime = _weather?.date?.hour ?? 0;
    int sunset = _weather?.sunset?.hour ?? 0;
    int sunrise = _weather?.sunrise?.hour ?? 0;

    if (dateTime == 0 && sunset == 0 && sunrise == 0) return false;
    return dateTime <= sunset && dateTime > sunrise;
  }

  String _getWeather(String? description) {
    List<String> words = [
      'clear sky',
      'snow',
      'rain',
      'clouds',
      'thunderstorm'
    ];
    String input = description.toString().toLowerCase();
    for (String word in words) {
      if (input.contains(word.toLowerCase())) {
        if (word == 'clear sky') {
          bool isSun = isDaytime();
          if (isSun) {
            return 'assets/weather/sun.png';
          } else {
            return 'assets/weather/mon.png';
          }
        }
        return 'assets/weather/${word}.png';
      }
    }
    return 'assets/weather/weather.png';
  }

  Future<List<dynamic>> fetchData() async {
    List<dynamic> data = [];
    final url =
        'https://api.thingspeak.com/channels/2622135/fields/1.json?api_key=W2KRZHJZJ0K8CTXC&results=10';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        data = jsonData['feeds'] ?? [];
      });
    } else {
      throw Exception('Failed to load data');
    }
    return data;
  }

  Future<List<FlSpot>> fetchDataFromThingSpeak(data) async {
    List<FlSpot> spots = [];
    print('1+$data');

    for (var i = 0; i < 10; i++) {
      // Trục X theo giờ (hoặc thời gian), tính từ dữ liệu nhận được
      String createdAt = data[i]['created_at'];
      DateTime time = DateTime.parse(createdAt);

      double x = (time.hour * 60 + time.minute).toDouble();

      double y = (double.parse(data[i]['field1'] ?? '0') * 100).round() / 100;
      if (!x.isInfinite && !x.isNaN && !y.isInfinite && !y.isNaN) {
        spots.add(FlSpot(x, y));
      }
    }

    return spots;
  }
}

class GraphTemp extends StatelessWidget {
  final int size;
  final List<FlSpot> thingdata;

  GraphTemp({
    required this.size,
    required this.thingdata,
  });

  @override
  Widget build(BuildContext context) {
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;

    // Lấy minX và maxX từ các điểm có y > 0
    final validData = thingdata.where((point) => point.y > 0).toList();
    final double minX = validData.isNotEmpty ? validData.first.x : 0;
    final double maxX = validData.isNotEmpty ? validData.last.x : 1;

    final numberOfPoints = 3; // Số điểm bạn muốn chia đều
    final step = (maxX - minX) / (numberOfPoints - 1);

    return Container(
      width: WidthScreen * 0.5 * size - 12,
      padding: const EdgeInsets.only(top: 12, right: 12, bottom: 0, left: 0),
      decoration: BoxDecoration(
        color: Color(0xFF252F52),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Color(0xFF252F52), width: 2),
      ),
      height: HeightScreen * 0.25,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots:
                  thingdata.map((point) => FlSpot(point.x, point.y)).toList(),
              isCurved: false,
              dotData: FlDotData(
                show: false,
              ),
            ),
          ],
          borderData: FlBorderData(
            border: const Border(bottom: BorderSide(), left: BorderSide()),
          ),
          gridData: FlGridData(show: true),
          minX: minX,
          maxX: maxX,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final correspondingPoint = thingdata.firstWhere(
                      (point) => point.x == value,
                      orElse: () => FlSpot(value, -1));

                  if (correspondingPoint.y > 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        minuToHouse(value),
                        style: TextStyle(fontSize: 11),
                      ),
                    );
                  }

                  return SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value.isNaN || value.isInfinite) {
                    return SizedBox();
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}

class TemperatureInfo extends StatelessWidget {
  final String title;
  final String data;
  final double size;

  TemperatureInfo({
    required this.title,
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    double value = double.tryParse(data) ?? 0.0;
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;
    return Container(
      width: WidthScreen * 0.5 * size - 12,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Color(0xFF252F52),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Color(0xFF252F52), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SleekCircularSlider(
                    min: 0,
                    max: 50,
                    initialValue: value,
                    appearance: CircularSliderAppearance(
                      infoProperties: InfoProperties(
                        // Ẩn số phần trăm
                        modifier: (percentage) => '',
                      ),
                      customColors: CustomSliderColors(
                        progressBarColor:
                            value > 32.0 ? Colors.red : Color(0xFFff9800),
                        trackColor: Color(0xFF354375),
                        dotColor: Colors.transparent.withOpacity(0),
                        dynamicGradient: true,
                      ),
                      size: 70.0,
                      startAngle: 270.0,
                      angleRange: 360.0,
                      customWidths: CustomSliderWidths(
                        trackWidth: 10.0,
                        progressBarWidth: 10.0,
                        handlerSize: 8.0,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/temp.png',
                    width: 45, // Kích thước của biểu tượng
                    height: 45,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Text('${value.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class WeatherInfo extends StatelessWidget {
  final String title;
  final String content;
  final String weatherState;
  final double size;
  final DateTime date;

  WeatherInfo(
      {required this.title,
      required this.content,
      required this.size,
      required this.date,
      required this.weatherState});

  @override
  Widget build(BuildContext context) {
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;
    return Container(
      width: WidthScreen * 0.5 * size - 12,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Color(0xFF252F52),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Color(0xFF252F52), width: 2),
      ),
      child: Column(
        children: [
          Text(
              title +
                  "-" +
                  date.day.toString() +
                  "/" +
                  date.month.toString() +
                  "/" +
                  date.year.toString(),
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(weatherState,
                  width: 80, // Kích thước của biểu tượng
                  height: 80),
              const SizedBox(width: 12),
              Text(content,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class HumidityInfo extends StatelessWidget {
  final String title;
  final String content;
  final double size;

  HumidityInfo(
      {required this.title, required this.content, required this.size});

  @override
  Widget build(BuildContext context) {
    final HeightScreen = MediaQuery.of(context).size.height;
    final WidthScreen = MediaQuery.of(context).size.width;
    return Container(
      width: WidthScreen * 0.5 * size - 12,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Color(0xFF252F52),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Color(0xFF252F52), width: 2),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/humidity.png',
                width: 70, // Kích thước của biểu tượng
                height: 70,
              ),
              const SizedBox(width: 12),
              Text(content,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class HourlyWeatherChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 200,
      child: const Center(child: Text('Hourly Weather Chart Placeholder')),
    );
  }
}

class WeatherForecastItem extends StatelessWidget {
  final String date;
  final String maxTemp;
  final String minTemp;
  final String humidity;

  WeatherForecastItem(
      {required this.date,
      required this.maxTemp,
      required this.minTemp,
      required this.humidity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(date,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(maxTemp, style: const TextStyle(fontSize: 16)),
          Text(minTemp, style: const TextStyle(fontSize: 16)),
          Text(humidity, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

String minuToHouse(double value) {
  final hour = (value ~/ 60).toInt();
  final minute = (value % 60).toInt();
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
