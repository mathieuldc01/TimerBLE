import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/heat.dart';
import '../models/passage.dart';
import '../models/computeResult.dart';
import '../models/pilot.dart';

import '../widgets/app_drawer.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final heats = context.watch<MapHeatModel>().heats;
    final passages = context.watch<MapPassageModel>().passages;
    final generalMode = context.watch<MapHeatModel>().generalMode;

    final tabs = [
      ...heats.map((h) => Tab(text: "Manche ${h.id}")),
      const Tab(text: "Général"),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Résultats"),
          bottom: TabBar(tabs: tabs),
        ),
        drawer: AppDrawer(),
        body: TabBarView(
          children: [
            for (var heat in heats) _buildHeatResult(context, heat, passages),

            _buildGeneralResult(context, heats, passages, generalMode),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Résultat d'une manche
  // -------------------------------------------------------------
  Widget _buildHeatResult(
    BuildContext context,
    Heat heat,
    List<Passage> passages,
  ) {
    final pilots = context.watch<MapPiloteModel>();

    final results = ComputeResult.computeHeatResult(
      heat: heat,
      passages: passages,
    );

    if (results.isEmpty) {
      return const Center(child: Text("Aucune donnée"));
    }

    // TRI
    if (heat.type == "laps") {
      results.sort((a, b) {
        final lapsA = computeLapCount(a, heat);
        final lapsB = computeLapCount(b, heat);
        if (lapsA != lapsB) return lapsB.compareTo(lapsA);

        final tA = computeTotalTime(a);
        final tB = computeTotalTime(b);
        return tA.compareTo(tB);
      });
    } else {
      results.sort((a, b) {
        final tA = computeTotalTime(a);
        final tB = computeTotalTime(b);
        return tA.compareTo(tB);
      });
    }

    return ListView(
      children: [
        for (var entry in results)
          Builder(
            builder: (_) {
              final totalTime = computeTotalTime(entry);
              final lapCount = computeLapCount(entry, heat);

              // 👉 Récupération du pilote
              final pilot = pilots.pilots.firstWhere(
                (p) => p.id.toString() == entry.pilotId.toString(),
                orElse: () => Pilot(id: entry.pilotId, name: "Unknown"),
              );

              return Card(
                child: ExpansionTile(
                  title: Text(
                    heat.type == "laps"
                        ? "${pilot.name} — Passage ${entry.passage} — ${lapCount} tours — ${formatTime(totalTime)}"
                        : "${pilot.name} — Passage ${entry.passage} — ${formatTime(totalTime)}",
                  ),
                  children: _buildTourDetails(entry, heat),
                ),
              );
            },
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 2. Détails des tours
  // -------------------------------------------------------------
  List<Widget> _buildTourDetails(ResultEntry entry, Heat heat) {
    final startBeacon = heat.beaconOrder.first.toString();

    List<List<dynamic>> tours = [];
    List<dynamic> currentTour = [];

    for (var hit in entry.result) {
      if (hit.baliseName == startBeacon) {
        if (currentTour.isNotEmpty) {
          tours.add(List.from(currentTour));
          currentTour.clear();
        }
      }
      currentTour.add(hit);
    }

    if (currentTour.isNotEmpty) {
      tours.add(currentTour);
    }

    List<Widget> widgets = [];

    for (int t = 0; t < tours.length; t++) {
      final tour = tours[t];
      final lapTime = tour.last.time - tour.first.time;

      widgets.add(
        ListTile(
          title: Text(
            heat.type == "laps"
                ? "Tour ${t + 1}   (${formatTime(lapTime)})"
                : "Intermédiaire",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

      for (int i = 1; i < tour.length; i++) {
        final hit = tour[i];

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: ListTile(
              title: Text("Balise ${hit.baliseName}"),
              subtitle: Text(
                "Temps: ${formatTime(hit.time)}\n"
                "In-lap: ${formatTime(hit.inLapTime)}\n"
                "Incertitude: ±${hit.incertitude} ms",
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // -------------------------------------------------------------
  // 3. Résultat général
  // -------------------------------------------------------------
  Widget _buildGeneralResult(
    BuildContext context,
    List<Heat> heats,
    List<Passage> passages,
    String mode,
  ) {
    final results = ComputeResult.computeGeneral(
      heats: heats,
      passages: passages,
      mode: mode,
    );

    final pilots = context.watch<MapPiloteModel>();

    if (results.isEmpty) {
      return const Center(child: Text("Aucun classement général possible"));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            "Mode général : $mode",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (var entry in results)
                Builder(
                  builder: (_) {
                    final pilot = pilots.pilots.firstWhere(
                      (p) => p.id.toString() == entry.pilotId.toString(),
                      orElse: () => Pilot(id: entry.pilotId, name: "Unknown"),
                    );

                    return ListTile(
                      title: Text(pilot.name),
                      trailing: Text(entry.value.toStringAsFixed(2)),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// OUTILS
// -------------------------------------------------------------
String formatTime(int ms) {
  if (ms < 0) ms = 0;

  int minutes = ms ~/ 60000;
  int seconds = (ms % 60000) ~/ 1000;
  int centiseconds = ((ms % 1000) / 10).round();

  return "${minutes.toString().padLeft(2, '0')}:"
      "${seconds.toString().padLeft(2, '0')}:"
      "${centiseconds.toString().padLeft(2, '0')}";
}

int computeTotalTime(ResultEntry entry) {
  if (entry.result.isEmpty) return 0;
  return entry.result.last.time;
}

int computeLapCount(ResultEntry entry, Heat heat) {
  final startBeacon = heat.beaconOrder.first;
  return entry.result.where((h) => h.baliseName == startBeacon).length - 1;
}
