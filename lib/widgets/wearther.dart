import 'package:weather/weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../consts.dart';
import 'dart:async';

final WeatherFactory wf = new WeatherFactory(OPENWEATHER_API_KEY);
final cityName = 'Ha Noi';
Weather? _weather;

class DataProvider with ChangeNotifier {
  Future<void> getInfoWeather() async {
    Weather w = await wf.currentWeatherByCityName(cityName);
    notifyListeners();
  }
}
