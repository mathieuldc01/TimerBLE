import "detection.dart";

class Passage {
  final int heatId;
  final String pilotId;
  final int number;
  final List<Detection> data;

  Passage({
    required this.heatId,
    required this.pilotId,
    required this.number,
    required this.data,
  });

  // ---- JSON ----
  Map<String, dynamic> toJson() => {
    'heatId': heatId,
    'pilotId': pilotId,
    'number': number,
    'data': data.map((d) => d.toJson()).toList(),
  };

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      heatId: json['heatId'],
      pilotId: json['pilotId'],
      number: json['number'],
      data: (json['data'] as List).map((d) => Detection.fromJson(d)).toList(),
    );
  }

  factory Passage.fromRaw(
    String raw, {
    required String pilotId,
    required int heatId,
    required int number,
  }) {
    final data = raw.split("\n").where((l) => l.trim().isNotEmpty).map((line) {
      final parts = line.split(",");
      return Detection(
        timestamp: int.parse(parts[0].split("=")[1]),
        baliseId: parts[1].split("=")[1],
        rssi: int.parse(parts[2].split("=")[1]),
      );
    }).toList();

    return Passage(
      pilotId: pilotId,
      heatId: heatId,
      number: number,
      data: data,
    );
  }

  @override
  String toString() {
    return 'Passage(heat: $heatId, number: $number)';
  }
}
