import 'passage.dart';
import 'heat.dart';
import 'pilot.dart';
import 'beacon.dart';

class Race {
  final int id;
  String name;

  List<Passage> passages;
  List<Heat> heats;
  List<Pilot> pilots;
  List<Beacon> beacons;

  Race({
    int? id,
    required this.name,
    List<Passage>? passages,
    List<Heat>? heats,
    List<Pilot>? pilots,
    List<Beacon>? beacons,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch,
       passages = passages ?? [],
       heats = heats ?? [],
       pilots = pilots ?? [],
       beacons = beacons ?? [];

  int getHeatNumber(Race race) {
    return race.heats.length;
  }

  int getPassageNumber(Race race, int heatId) {
    return race.passages.where((p) => p.heatId == heatId).length;
  }

  // Ajouter un passage
  void addPassage(Passage p) {
    passages.add(p);
  }

  // Ajouter une manche
  void addHeat(Heat h) {
    heats.add(h);
  }

  // Ajouter un pilote
  void addPilot(Pilot p) {
    pilots.add(p);
  }

  // ---- JSON ----
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'passages': passages.map((p) => p.toJson()).toList(),
    'heats': heats.map((h) => h.toJson()).toList(),
    'pilots': pilots.map((p) => p.toJson()).toList(),
  };

  int get heatCount => heats.length;

  /// Nombre de passages pour un heat donné
  int passageCount(int heatId) {
    return passages.where((p) => p.heatId == heatId).length;
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      passages: (json['passages'] as List)
          .map((p) => Passage.fromJson(p))
          .toList(),
      heats: (json['heats'] as List).map((h) => Heat.fromJson(h)).toList(),
      pilots: (json['pilots'] as List).map((p) => Pilot.fromJson(p)).toList(),
    );
  }
}
