class Heat {
  final int id;
  String info; // nom
  String type; // ex: "time", "laps", "speed"
  List<String> beaconOrder; // liste d'ID de beacon
  bool includeInGeneral; // inclure dans classement général

  Heat({
    required this.id,
    required this.info,
    this.type = "line",
    this.beaconOrder = const [],
    this.includeInGeneral = true,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "info": info,
    "type": type,
    "beaconOrder": beaconOrder,
    "includeInGeneral": includeInGeneral,
  };

  factory Heat.fromJson(Map<String, dynamic> json) => Heat(
    id: json["id"],
    info: json["info"],
    type: json["type"] ?? "time",
    beaconOrder: List<String>.from(json["beaconOrder"] ?? []),
    includeInGeneral: json["includeInGeneral"] ?? true,
  );
}
