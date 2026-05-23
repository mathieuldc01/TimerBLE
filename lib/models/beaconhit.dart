class BeaconHit {
  final String beaconId;
  final int time; // timestamp estimé du passage
  final int uncertainty; // en millisecondes

  BeaconHit({
    required this.beaconId,
    required this.time,
    this.uncertainty = 1000,
  });
}
