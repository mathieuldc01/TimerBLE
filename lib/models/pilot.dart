class Pilot {
  final String id;
  String name;

  Pilot({required this.id, this.name = "No Name"});

  void changeName(String newName) {
    name = newName;
  }

  // ---- JSON ----
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Pilot.fromJson(Map<String, dynamic> json) {
    return Pilot(id: json['id'], name: json['name'] ?? "No Name");
  }

  @override
  String toString() {
    return 'Pilot(id: $id, name: $name)';
  }
}
