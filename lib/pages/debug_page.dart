import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/heat.dart';
import '../models/passage.dart';
import '../models/pilot.dart';
import '../services/app_state.dart';
import '../widgets/app_drawer.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Heat? selectedHeat;
  Pilot? selectedPilot;
  Passage? selectedPassage;

  @override
  Widget build(BuildContext context) {
    final heats = context.watch<MapHeatModel>().heats;
    final passages = context.watch<MapPassageModel>().passages;
    final pilots = context.watch<MapPiloteModel>().pilots;

    // 🔍 Pilotes ayant participé à la manche
    final activePilots = selectedHeat == null
        ? []
        : pilots.where((pilot) {
            return passages.any(
              (p) => p.heatId == selectedHeat!.id && p.pilotId == pilot.id,
            );
          }).toList();

    // 🔍 Passages filtrés
    final filteredPassages = selectedHeat == null || selectedPilot == null
        ? []
        : passages
              .where(
                (p) =>
                    p.heatId == selectedHeat!.id &&
                    p.pilotId == selectedPilot!.id,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Debug RSSI")),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- HEAT ----------------
            DropdownButton<Heat>(
              hint: const Text("Choisir une manche"),
              value: selectedHeat,
              items: heats.map((h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text("Manche ${h.id}"),
                );
              }).toList(),
              onChanged: (h) {
                setState(() {
                  selectedHeat = h;
                  selectedPilot = null;
                  selectedPassage = null;
                });
              },
            ),

            // ---------------- PILOT ----------------
            DropdownButton<Pilot>(
              hint: const Text("Choisir un pilote"),
              value: selectedPilot,
              items: activePilots.map((p) {
                return DropdownMenuItem<Pilot>(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) {
                setState(() {
                  selectedPilot = p;
                  selectedPassage = null;
                });
              },
            ),

            // ---------------- PASSAGE ----------------
            DropdownButton<Passage>(
              hint: const Text("Choisir un passage"),
              value: selectedPassage,
              items: filteredPassages.map((p) {
                final index = filteredPassages.indexOf(p) + 1;
                return DropdownMenuItem<Passage>(
                  value: p,
                  child: Text("Passage $index"),
                );
              }).toList(),
              onChanged: (p) {
                setState(() {
                  selectedPassage = p;
                });
              },
            ),

            const SizedBox(height: 20),

            // ---------------- GRAPH ----------------
            Expanded(
              child: selectedPassage == null
                  ? const Center(child: Text("Sélectionne un passage"))
                  : _buildGraph(selectedPassage!),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // GRAPH MULTI-CURVES (one per beacon)
  // -------------------------------------------------------------
  Widget _buildGraph(Passage passage) {
    // Group hits by beacon
    final Map<String, List<FlSpot>> curves = {};

    for (var hit in passage.data) {
      curves.putIfAbsent(hit.baliseId, () => []);
      curves[hit.baliseId]!.add(
        FlSpot(hit.timestamp.toDouble(), hit.rssi.toDouble()),
      );
    }

    // Colors for curves
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];

    int colorIndex = 0;

    final lineBars = curves.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return LineChartBarData(
        spots: entry.value,
        isCurved: false,
        color: color,
        barWidth: 2,
        dotData: FlDotData(show: true),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Légende visible
          ...curves.entries.map((entry) {
            final idx = curves.keys.toList().indexOf(entry.key);
            final color = colors[idx % colors.length];
            final count = entry.value.length;

            return Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text("Balise ${entry.key} — $count points"),
              ],
            );
          }),

          const SizedBox(height: 10),

          // 🔥 Graphique interactif
          SizedBox(
            height: 400, // important pour éviter que ça prenne tout l’écran
            child: LineChart(
              LineChartData(
                minY: -100,
                maxY: 0,
                lineBarsData: lineBars,

                // Interaction
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          "t=${spot.x.toInt()}ms\nrssi=${spot.y.toInt()}",
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),

                borderData: FlBorderData(show: true),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
