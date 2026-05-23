class Beacon {
  final String id;
  String position;

  Beacon({required this.id, this.position = "No Name"});

  // Fonction pour changer le nom
  void changePosition(String newPosition) {
    position = newPosition;
  }

  @override
  String toString() {
    return 'Beacon(id: $id, name: $position)';
  }
}
