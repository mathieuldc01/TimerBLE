class Detection {
  final String baliseId;
  final int rssi;
  final int timestamp;

  Detection({
    required this.baliseId,
    required this.rssi,
    required this.timestamp,
  });

  // ---- JSON ----
  Map<String, dynamic> toJson() => {
    'baliseId': baliseId,
    'rssi': rssi,
    'timestamp': timestamp,
  };

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      baliseId: json['baliseId'],
      rssi: json['rssi'],
      timestamp: json['timestamp'],
    );
  }

  @override
  String toString() {
    return 'Detection(balise id : $baliseId, rssi : $rssi, timestamp : $timestamp)';
  }
}
