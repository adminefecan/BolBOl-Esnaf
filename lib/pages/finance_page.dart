import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  Map<String, List<Map<String, dynamic>>> _gruplar = {"Altın": [], "Döviz": []};
  String _guncelleme = "";
  bool _loading = true;
  String _filter = "Hepsi";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchVeri();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchVeri());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVeri() async {
    const apiUrl = 'https://bolbolesnaf.efecand.com.tr/api/apis/altin.php';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final veriler = Map<String, dynamic>.from(data['veri']);
        _guncelleme = veriler["Update_Date"] ?? "-";

        final List<Map<String, dynamic>> altinlar = [];
        final List<Map<String, dynamic>> dovizler = [];

        veriler.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final entry = {
              'isim': key.toString().replaceAll('-', ' ').toUpperCase(),
              'alis': value['Alış'] ?? '-',
              'satis': value['Satış'] ?? '-',
              'degisim': value['Değişim'] ?? '-',
              'tur': value['Tür'] ?? '-',
            };
            if (value['Tür'] == "Altın") {
              altinlar.add(entry);
            } else if (value['Tür'] == "Döviz") {
              dovizler.add(entry);
            }
          }
        });

        setState(() {
          _gruplar = {"Altın": altinlar, "Döviz": dovizler};
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Widget _buildFilterButtons() {
    final filters = ["Hepsi", "Altın", "Döviz"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(f),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.orange.shade800),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const SizedBox();
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title == "Altın"
                      ? Icons.currency_bitcoin
                      : Icons.monetization_on,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(thickness: 1),
            ...list.take(10).map((v) {
              final degisim = v['degisim'] ?? '-';
              final isPositive = degisim.contains('+');
              final isNegative = degisim.contains('-');
              Color renk = Colors.grey;
              if (isPositive) renk = Colors.green;
              if (isNegative) renk = Colors.red;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.orange.shade100],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(v['isim'],
                            style:
                            const TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text("Alış: ${v['alis']}",
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text("Satış: ${v['satis']}",
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(v['degisim'],
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: renk, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(String title, List<double> values, Color color) {
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(values.length,
                                (i) => FlSpot(i.toDouble(), values[i])),
                        isCurved: true,
                        gradient: LinearGradient(colors: [color, Colors.orange]),
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true, color: color.withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final altin = _gruplar["Altın"] ?? [];
    final doviz = _gruplar["Döviz"] ?? [];

    List<Map<String, dynamic>> data = [];
    if (_filter == "Altın") {
      data = altin;
    } else if (_filter == "Döviz") {
      data = doviz;
    } else {
      data = [...altin, ...doviz];
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Altın & Döviz Fiyatları")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchVeri,
        child: ListView(
          children: [
            if (_guncelleme.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text("📅 Güncelleme: $_guncelleme",
                    textAlign: TextAlign.center,
                    style:
                    const TextStyle(fontWeight: FontWeight.w600)),
              ),
            _buildFilterButtons(),
            _buildGraph("Gram Altın", [5500, 5520, 5560, 5580, 5610, 5630],
                Colors.amber),
            _buildGraph("Dolar (USD)", [41.9, 42.0, 41.95, 42.1, 41.97],
                Colors.green),
            if (_filter == "Hepsi" || _filter == "Altın")
              _buildSection("Altın", altin),
            if (_filter == "Hepsi" || _filter == "Döviz")
              _buildSection("Döviz", doviz),
          ],
        ),
      ),
    );
  }
}
