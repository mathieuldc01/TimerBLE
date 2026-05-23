import 'pilot.dart';
import 'beacon.dart';
import 'heat.dart';
import 'passage.dart';
import 'detection.dart';

class RaceDemo {
  // -------------------------------------------------------------
  // 1. Balises
  // -------------------------------------------------------------
  static List<Beacon> demoBeacons = [
    Beacon(id: "1", position: "Départ"),
    Beacon(id: "2", position: "Virage 1"),
    Beacon(id: "3", position: "Ligne droite"),
    Beacon(id: "4", position: "Arrivée"),
    Beacon(id: "ESP32_BEACON", position: "test"),
  ];

  static List<Pilot> demoPilots = [
    Pilot(id: "1", name: "Alice"),
    Pilot(id: "2", name: "Bob"),
    Pilot(id: "3", name: "Charlie"),
  ];

  // -------------------------------------------------------------
  // 2. Manches
  // -------------------------------------------------------------
  static List<Heat> demoHeats = [
    Heat(
      id: 1,
      info: "Manche 1",
      type: "line",
      includeInGeneral: true,
      beaconOrder: ["1", "2", "3", "4"],
    ),
    Heat(
      id: 2,
      info: "Manche 2",
      type: "laps",
      includeInGeneral: false,
      beaconOrder: ["1", "4"],
    ),
  ];

  // -------------------------------------------------------------
  // 3. Pilotes
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 4. Passages (avec détections réalistes)
  // -------------------------------------------------------------
  static List<Passage> demoPassages = [
    Passage(
      number: 1,
      heatId: 2,
      pilotId: "1",
      data: [
        // Manche 1
        Detection(baliseId: "1", timestamp: 9400, rssi: -62),
        Detection(baliseId: "1", timestamp: 10000, rssi: -54),
        Detection(baliseId: "1", timestamp: 10200, rssi: -55),
        Detection(baliseId: "1", timestamp: 10500, rssi: -62),
        Detection(baliseId: "2", timestamp: 175000, rssi: -70),
        Detection(baliseId: "1", timestamp: 150000, rssi: -70),
        Detection(baliseId: "2", timestamp: 155000, rssi: -70),
        Detection(baliseId: "1", timestamp: 160000, rssi: -65),
        Detection(baliseId: "2", timestamp: 175000, rssi: -70),
        Detection(baliseId: "1", timestamp: 200000, rssi: -72),
        Detection(baliseId: "2", timestamp: 225000, rssi: -70),
        Detection(baliseId: "1", timestamp: 250000, rssi: -68),
      ],
    ),

    Passage(
      number: 1,
      heatId: 1,
      pilotId: "1",
      data: [
        // Manche 1
        Detection(baliseId: "1", timestamp: 9400, rssi: -62),
        Detection(baliseId: "1", timestamp: 10000, rssi: -54),
        Detection(baliseId: "1", timestamp: 10200, rssi: -55),
        Detection(baliseId: "1", timestamp: 10500, rssi: -62),
        Detection(baliseId: "2", timestamp: 15000, rssi: -70),
        Detection(baliseId: "2", timestamp: 15200, rssi: -65),
        Detection(baliseId: "3", timestamp: 20000, rssi: -72),
        Detection(baliseId: "4", timestamp: 25000, rssi: -68),
      ],
    ),

    Passage(
      number: 1,
      heatId: 1,
      pilotId: "2",
      data: [
        Detection(baliseId: "1", timestamp: 11000, rssi: -62),
        Detection(baliseId: "1", timestamp: 11200, rssi: -58),
        Detection(baliseId: "2", timestamp: 16000, rssi: -71),
        Detection(baliseId: "3", timestamp: 21000, rssi: -73),
        Detection(baliseId: "4", timestamp: 26000, rssi: -69),
      ],
    ),

    Passage(
      number: 1,
      heatId: 1,
      pilotId: "3",
      data: [
        Detection(baliseId: "1", timestamp: 12000, rssi: -63),
        Detection(baliseId: "2", timestamp: 17000, rssi: -72),
        Detection(baliseId: "3", timestamp: 22000, rssi: -74),
        Detection(baliseId: "4", timestamp: 27000, rssi: -70),
      ],
    ),
    Passage(
      number: 2,
      heatId: 1,
      pilotId: "3",
      data: [
        Detection(baliseId: "1", timestamp: 13000, rssi: -63),
        Detection(baliseId: "2", timestamp: 17000, rssi: -72),
        Detection(baliseId: "3", timestamp: 22000, rssi: -74),
        Detection(baliseId: "4", timestamp: 27000, rssi: -70),
      ],
    ),
    Passage(
      number: 3,
      heatId: 1,
      pilotId: "3",
      data: [
        Detection(baliseId: "1", timestamp: 13000, rssi: -63),
        Detection(baliseId: "2", timestamp: 17000, rssi: -72),
        Detection(baliseId: "3", timestamp: 22000, rssi: -74),
        Detection(baliseId: "4", timestamp: 37000, rssi: -70),
      ],
    ),
  ];
}
