import 'passage.dart';
import 'beaconhit.dart';
import 'detection.dart';
import 'heat.dart';

import 'dart:math';

class ComputeResult {
  // -------------------------------------------------------------
  // 1. Classement d'une manche
  // -------------------------------------------------------------
  static List<ResultEntry> computeHeatResult({
    required Heat heat,
    required List<Passage> passages,
  }) {
    // 1. Filtrer les passages appartenant à cette manche
    final filtered = passages.where((p) => p.heatId == heat.id).toList();

    if (filtered.isEmpty) return [];

    // 2. Calcul selon le type
    switch (heat.type) {
      case "line":
        return _computeLineResult(heat, filtered);

      case "laps":
        return _computeLapResult(heat, filtered);

      default:
        return [];
    }
  }

  // -------------------------------------------------------------
  // 2. Solveur 3x3 (Cramer)
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // 1. Solveur 3x3 (Cramer)
  // -------------------------------------------------------------
  List<double> _solve3x3(List<List<double>> A, List<double> B) {
    double det(List<List<double>> m) {
      return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
          m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
          m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
    }

    final d = det(A);
    if (d == 0) return [0, 0, B[2] / 3];

    List<List<double>> replaceColumn(int col) {
      final M = [
        [...A[0]],
        [...A[1]],
        [...A[2]],
      ];
      for (int i = 0; i < 3; i++) {
        M[i][col] = B[i];
      }
      return M;
    }

    final da = det(replaceColumn(0));
    final db = det(replaceColumn(1));
    final dc = det(replaceColumn(2));

    return [da / d, db / d, dc / d];
  }

  // -------------------------------------------------------------
  // 2. Découpage en paquets
  // -------------------------------------------------------------
  List<List<Detection>> sliceDetection(Passage passage) {
    final data = passage.data;
    if (data.isEmpty) return [];

    List<List<Detection>> slices = [];
    List<Detection> temp = [];

    int lastTimestamp = data.first.timestamp;
    String lastBeacon = data.first.baliseId;

    for (var detection in data) {
      final sameBeacon = detection.baliseId == lastBeacon;
      final closeInTime = (detection.timestamp - lastTimestamp) < 2000;

      if (sameBeacon && closeInTime) {
        temp.add(detection);
      } else {
        if (temp.isNotEmpty) slices.add(List.from(temp));
        temp.clear();
        temp.add(detection);
        lastBeacon = detection.baliseId;
      }

      lastTimestamp = detection.timestamp;
    }

    if (temp.isNotEmpty) slices.add(temp);

    return slices;
  }

  // -------------------------------------------------------------
  // 3. Traitement d’un paquet (fit quadratique + incertitude réelle)
  // -------------------------------------------------------------
  BeaconHit processPacket(List<Detection> packet) {
    if (packet.isEmpty) throw Exception("Packet vide");

    final beaconId = packet.first.baliseId;

    // ---- CAS 1 : 1 point ----
    if (packet.length == 1) {
      return BeaconHit(
        beaconId: beaconId,
        time: packet.first.timestamp,
        uncertainty: 1000,
      );
    }

    // ---- CAS 2 : 2 points ----
    if (packet.length == 2) {
      final d1 = packet[0];
      final d2 = packet[1];

      final t1 = d1.timestamp;
      final t2 = d2.timestamp;

      final tMid = ((t1 + t2) / 2).round();
      final uncertainty = ((t2 - t1).abs() / 2).round();

      return BeaconHit(
        beaconId: beaconId,
        time: tMid,
        uncertainty: uncertainty,
      );
    }

    // ---- CAS 3 : 3+ points → fit quadratique ----
    final xs = packet.map((d) => d.timestamp.toDouble()).toList();
    final ys = packet.map((d) => d.rssi).toList(); // inversion pour max

    double Sx = 0, Sx2 = 0, Sx3 = 0, Sx4 = 0;
    double Sy = 0, Sxy = 0, Sx2y = 0;

    for (int i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];

      Sx += x;
      Sx2 += x * x;
      Sx3 += x * x * x;
      Sx4 += x * x * x * x;

      Sy += y;
      Sxy += x * y;
      Sx2y += x * x * y;
    }

    final n = xs.length.toDouble();

    final A = [
      [Sx4, Sx3, Sx2],
      [Sx3, Sx2, Sx],
      [Sx2, Sx, n],
    ];

    final B = [Sx2y, Sxy, Sy];

    final coeffs = _solve3x3(A, B);
    final a = coeffs[0];
    final b = coeffs[1];
    final c = coeffs[2];

    // ---- Parabole ouverte vers le haut → pas de maximum ----
    if (a >= 0) {
      final best = packet.reduce((a, b) => a.rssi > b.rssi ? a : b);

      final times = packet.map((d) => d.timestamp).toList();
      final tMin = times.reduce((a, b) => a < b ? a : b);
      final tMax = times.reduce((a, b) => a > b ? a : b);

      final uncertainty = ((tMax - tMin) / 2).round();

      return BeaconHit(
        beaconId: beaconId,
        time: best.timestamp,
        uncertainty: uncertainty,
      );
    }

    // ---- Sommet de la parabole ----
    final tPeak = -b / (2 * a);

    // -------------------------------------------------------------
    // 4. Calcul de l’incertitude réelle
    // -------------------------------------------------------------

    // Résidus du fit
    double rss = 0;
    for (int i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];
      final yFit = a * x * x + b * x + c;
      rss += (y - yFit) * (y - yFit);
    }

    final dof = xs.length - 3;
    final sigmaY = dof > 0 ? sqrt(rss / dof) : 1.0;

    // Courbure
    final curvature = (2 * a).abs();

    double sigmaT;
    if (curvature < 1e-9) {
      sigmaT = 1e6; // parabole trop plate
    } else {
      sigmaT = sigmaY / curvature;
    }

    // Borne raisonnable
    final times = packet.map((d) => d.timestamp.toDouble()).toList();
    final tMin = times.reduce((a, b) => a < b ? a : b);
    final tMax = times.reduce((a, b) => a > b ? a : b);
    final span = tMax - tMin;

    final uncertainty = sigmaT.clamp(1.0, span / 2).round();

    return BeaconHit(
      beaconId: beaconId,
      time: tPeak.round(),
      uncertainty: uncertainty,
    );
  }

  // -------------------------------------------------------------
  // 5. Traitement de tous les paquets
  // -------------------------------------------------------------
  List<BeaconHit> processAllPackets(List<List<Detection>> packets) {
    return packets.map((p) => processPacket(p)).toList();
  }

  // -------------------------------------------------------------
  // 6. Classement général
  // -------------------------------------------------------------
  static List<ResultEntryGeneral> computeGeneral({
    required List<Heat> heats,
    required List<Passage> passages,
    required String mode, // "sum_all", "sum_best", "best"
  }) {
    // 1. Calculer les résultats par manche
    Map<String, List<PilotHeatTime>> perPilot = {};

    for (var heat in heats) {
      final results = computeHeatResult(heat: heat, passages: passages);

      for (var entry in results) {
        final totalTime = entry.result.last.time.toDouble();

        perPilot.putIfAbsent(entry.pilotId, () => []);
        perPilot[entry.pilotId]!.add(PilotHeatTime(heat.id, totalTime));
      }
    }

    Map<String, double> finalScores = {};

    perPilot.forEach((pilot, list) {
      switch (mode) {
        case "sum_all":
          // Somme de tous les temps de toutes les manches
          finalScores[pilot] = list.map((e) => e.time).reduce((a, b) => a + b);
          break;

        case "sum_best":
          // Regrouper par manche
          Map<int, List<double>> perHeat = {};

          for (var e in list) {
            perHeat.putIfAbsent(e.heatId, () => []);
            perHeat[e.heatId]!.add(e.time);
          }

          // Pour chaque manche → meilleur temps
          double sum = 0;
          perHeat.forEach((heatId, times) {
            final best = times.reduce((a, b) => a < b ? a : b);
            sum += best;
          });

          finalScores[pilot] = sum;
          break;

        case "best":
          // Meilleur temps global toutes manches confondues
          finalScores[pilot] = list
              .map((e) => e.time)
              .reduce((a, b) => a < b ? a : b);
          break;
      }
    });

    return finalScores.entries
        .map((e) => ResultEntryGeneral(pilotId: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  // -------------------------------------------------------------
  // 7. Calculs placeholder
  // -------------------------------------------------------------
  static List<ResultEntry> _computeLineResult(
    Heat heat,
    List<Passage> passages,
  ) {
    passages = passages.where((p) => p.heatId == heat.id).toList();

    List<ResultEntry> results = [];

    for (var passage in passages) {
      // 1. Découper en paquets
      final packets = ComputeResult().sliceDetection(passage);

      // 2. Fit parabolique → BeaconHit
      final hits = ComputeResult().processAllPackets(packets);

      // 3. Garder seulement les balises de la manche
      final orderedHits = <BeaconHit>[];
      for (var b in heat.beaconOrder) {
        final hit = hits.where((h) => h.beaconId == b).toList();
        if (hit.isNotEmpty) orderedHits.add(hit.first);
      }

      if (orderedHits.isEmpty) continue;

      // 4. Temps de référence = première balise
      final t0 = orderedHits.first.time;

      // 5. Construire les ResultHit
      final resultHits = orderedHits.map((h) {
        return ResultHit(
          baliseName: h.beaconId,
          time: h.time - t0,
          inLapTime: 0, // toujours 0 en mode LINE
          incertitude: h.uncertainty,
        );
      }).toList();

      results.add(
        ResultEntry(
          pilotId: passage.pilotId,
          result: resultHits,
          passage: passage.number,
          heat: passage.heatId,
        ),
      );
    }

    return results;
  }

  static List<ResultEntry> _computeLapResult(
    Heat heat,
    List<Passage> passages,
  ) {
    passages = passages.where((p) => p.heatId == heat.id).toList();

    List<ResultEntry> results = [];
    for (var passage in passages) {
      final packets = ComputeResult().sliceDetection(passage);
      final hits = ComputeResult().processAllPackets(packets);

      // Garder seulement les balises de la manche

      // Temps absolu de référence
      final t0 = hits.first.time;

      // Temps de début de tour
      int lapStart = t0;

      List<ResultHit> resultHits = [];
      print("ici4");
      for (var h in hits) {
        int absolute = h.time - t0;

        int inLap;
        if (h.beaconId == heat.beaconOrder.first) {
          // Nouvelle boucle
          inLap = 0;
          lapStart = h.time;
        } else {
          inLap = h.time - lapStart;
        }

        resultHits.add(
          ResultHit(
            baliseName: h.beaconId,
            time: absolute,
            inLapTime: inLap,
            incertitude: h.uncertainty,
          ),
        );
      }

      results.add(
        ResultEntry(
          pilotId: passage.pilotId,
          result: resultHits,
          passage: passage.number,
          heat: passage.heatId,
        ),
      );
    }

    return results;
  }
}

class ResultHit {
  final String baliseName;
  final int time;
  final int inLapTime;
  final int incertitude;

  ResultHit({
    required this.baliseName,
    required this.time,
    required this.inLapTime,
    required this.incertitude,
  });
}

class ResultEntry {
  final String pilotId;
  final int heat;
  final List<ResultHit> result;
  final int passage;

  ResultEntry({
    required this.pilotId,
    required this.heat,
    required this.result,
    required this.passage,
  });
}

class ResultEntryGeneral {
  final String pilotId;
  final double value;

  ResultEntryGeneral({required this.pilotId, required this.value});
}

class PilotHeatTime {
  final int heatId;
  final double time;

  PilotHeatTime(this.heatId, this.time);
}
