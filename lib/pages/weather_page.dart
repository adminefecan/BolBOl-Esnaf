import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  String city = "Istanbul";
  bool loading = false;

  double? temp;
  String? desc;
  String? icon;
  String? sunrise;
  String? sunset;
  List<dynamic> forecast = [];

  late AnimationController _controller;

  final Map<String, String> trDesc = {
    "Sunny": "Güneşli",
    "Clear": "Açık",
    "Partly cloudy": "Parçalı bulutlu",
    "Cloudy": "Bulutlu",
    "Overcast": "Kapalı",
    "Mist": "Sisli",
    "Fog": "Yoğun sis",
    "Rain": "Yağmurlu",
    "Light rain": "Hafif yağmurlu",
    "Moderate rain": "Orta yağmur",
    "Heavy rain": "Kuvvetli yağmur",
    "Thunderstorm": "Gök gürültülü",
    "Snow": "Karlı",
    "Light snow": "Hafif kar",
    "Moderate snow": "Orta kar",
    "Heavy snow": "Yoğun kar",
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    fetchWeather();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    setState(() => loading = true);
    try {
      // anlık hava durumu
      final nowUrl = Uri.parse(
          "https://bolbolesnaf.efecand.com.tr/api/apis/weathers.php?city=$city");
      final nowRes = await http.get(nowUrl);
      final nowData = json.decode(nowRes.body);

      // haftalık tahmin
      final forecastUrl = Uri.parse(
          "https://weatherapi-com.p.rapidapi.com/forecast.json?q=$city&days=7");
      final forecastRes = await http.get(forecastUrl, headers: {
        "x-rapidapi-host": "weatherapi-com.p.rapidapi.com",
        "x-rapidapi-key": "2123e3dd53mshbd1eb79c8751335p1687a5jsne4518b947968"
      });
      final forecastData = json.decode(forecastRes.body);

      setState(() {
        temp = nowData["temp"];
        desc = trDesc[nowData["desc"]] ?? nowData["desc"];
        icon = nowData["icon"].toString().startsWith("http")
            ? nowData["icon"]
            : "https:${nowData["icon"]}";
        sunrise = forecastData["forecast"]["forecastday"][0]["astro"]["sunrise"];
        sunset = forecastData["forecast"]["forecastday"][0]["astro"]["sunset"];
        forecast = forecastData["forecast"]["forecastday"];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bağlantı hatası: ${e.toString()}")));
    }
    setState(() => loading = false);
  }

  LinearGradient _getWeatherGradient() {
    if (desc == null) {
      return const LinearGradient(colors: [Colors.grey, Colors.blueGrey]);
    }

    if (desc!.contains("Yağmur")) {
      return const LinearGradient(
        colors: [Color(0xFF2c3e50), Color(0xFF3498db)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (desc!.contains("Karlı")) {
      return const LinearGradient(
        colors: [Color(0xFFe0f7fa), Color(0xFFb2ebf2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (desc!.contains("Bulut")) {
      return const LinearGradient(
        colors: [Color(0xFF90CAF9), Color(0xFFBBDEFB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
    DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hava Durumu"),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(gradient: _getWeatherGradient()),
            child: CustomPaint(
              painter: WeatherAnimationPainter(_controller.value, desc),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Şehir Gir",
                        hintText: city,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (val) {
                        if (val.isNotEmpty) {
                          city = val;
                          fetchWeather();
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        child: Column(
                          children: [
                            Image.network(icon ?? "", width: 100),
                            Text(city,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              "${temp?.toStringAsFixed(1)}°C",
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(desc ?? "",
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 10),
                            Text(formattedTime,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54)),
                            if (sunrise != null && sunset != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                child: Text(
                                  "🌅 $sunrise   🌇 $sunset",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            const Divider(height: 25),
                            const Text("📆 7 Günlük Tahmin",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Column(
                              children: forecast.map((day) {
                                final date =
                                DateFormat('E dd/MM', 'tr_TR')
                                    .format(DateTime.parse(
                                    day["date"]));
                                final avg = day["day"]["avgtemp_c"];
                                final cond =
                                day["day"]["condition"]["text"];
                                final condTr =
                                    trDesc[cond] ?? cond;
                                final iconUrl =
                                    "https:${day["day"]["condition"]["icon"]}";
                                return Card(
                                  color: Colors.white70,
                                  child: ListTile(
                                    leading:
                                    Image.network(iconUrl, width: 40),
                                    title: Text(
                                        "$date  -  ${avg.toStringAsFixed(1)}°C"),
                                    subtitle: Text(condTr),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WeatherAnimationPainter extends CustomPainter {
  final double progress;
  final String? desc;
  final Random _rand = Random();

  WeatherAnimationPainter(this.progress, this.desc);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    if (desc == null) return;

    if (desc!.contains("Yağmur")) {
      paint.color = Colors.blueAccent.withOpacity(0.4);
      for (int i = 0; i < 80; i++) {
        double x = _rand.nextDouble() * size.width;
        double y = (_rand.nextDouble() * size.height + progress * 50) %
            size.height;
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 8), paint);
      }
    } else if (desc!.contains("Karlı")) {
      paint.color = Colors.white.withOpacity(0.9);
      for (int i = 0; i < 60; i++) {
        double x = _rand.nextDouble() * size.width;
        double y = (_rand.nextDouble() * size.height + progress * 40) %
            size.height;
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    } else if (desc!.contains("Güneşli") || desc!.contains("Açık")) {
      paint.color = Colors.yellowAccent.withOpacity(0.7);
      double sunX = size.width / 2;
      double sunY = 100 + sin(progress * pi) * 20;
      canvas.drawCircle(Offset(sunX, sunY), 50, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
