import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/pilot.dart';
import '../models/beacon.dart';
import '../models/heat.dart';
import '../models/race.dart';
import '../models/passage.dart';

import '../models/demoRace.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'ble_service.dart';

class MapDeviceModel extends ChangeNotifier {
  final BleService ble = BleService();

  final List<Device> _devices = [];
  List<Device> get devices => _devices;

  late MapHeatModel heatModel;
  late MapPassageModel passageModel;
  late MapPiloteModel piloteModel;
  late Race race;

  void attachModels({
    required MapHeatModel heats,
    required MapPassageModel passages,
    required MapPiloteModel pilotes,
    required MapRaceModel races,
  }) {
    heatModel = heats;
    passageModel = passages;
    piloteModel = pilotes;
    race = races.currentRace;
  }

  Future<void> scanDevices() async {
    final results = await ble.scan(3);

    _devices.clear();

    for (final d in results) {
      final name = d.platformName;

      final id = name.replaceFirst("ESP32_", "");

      _devices.add(Device(id: id, state: "detected", bleDevice: d));
    }

    notifyListeners();
  }

  Future<void> connectToDevice(String id) async {
    final d = _devices.firstWhere((e) => e.id == id);

    await ble.connect(d.bleDevice);

    d.state = "connected";
    notifyListeners();
  }

  Future<void> readData(String id) async {
    final raw = await ble.fetchData();
    print(raw);

    final d = _devices.firstWhere((e) => e.id == id);
    d.state = "data";

    final heatId = race.heatCount;
    final number = race.passageCount(heatId);

    // 👉 On parse raw et on ajoute un passage
    final passage = Passage.fromRaw(
      raw,
      pilotId: id,
      heatId: heatId,
      number: number,
    );
    passageModel.addPassage(passage);

    notifyListeners();
  }

  Future<void> nextState(String id) async {
    final d = _devices.firstWhere((e) => e.id == id);

    switch (d.state) {
      case "detected":
        await connectToDevice(id);
        break;

      case "connected":
        await readData(id);
        break;

      case "data":
        await ble.disconnect();
        _devices.removeWhere((e) => e.id == id);
        break;
    }

    notifyListeners();
  }
}

class MapPiloteModel extends ChangeNotifier {
  final List<Pilot> _pilots = RaceDemo.demoPilots;
  List<Pilot> get pilots => _pilots;
  void addPilot(Pilot p) {
    _pilots.add(p);
    notifyListeners();
  }

  Pilot getById(String id) {
    return _pilots.firstWhere((p) => p.id == id, orElse: () => Pilot(id: id));
  }

  bool exists(String id) {
    return _pilots.any((p) => p.id == id);
  }

  void removePilot(String id) {
    _pilots.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updatePilotName(String id, String newName) {
    final pilot = _pilots.firstWhere((p) => p.id == id);
    pilot.name = newName;
    notifyListeners();
  }
}

class MapBeaconModel extends ChangeNotifier {
  final List<Beacon> _beacons = RaceDemo.demoBeacons;

  List<Beacon> get beacons => _beacons;

  void addBeacon(Beacon beacon) {
    _beacons.add(beacon);
    notifyListeners();
  }

  void updateBeaconName(String id, String newPosition) {
    final beacon = _beacons.firstWhere((p) => p.id == id);
    beacon.position = newPosition;
    notifyListeners();
  }

  void removeBeacon(String id) {
    _beacons.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

class MapHeatModel extends ChangeNotifier {
  final List<Heat> _heats = RaceDemo.demoHeats;

  List<Heat> get heats => _heats;

  int get heatCount => heats.length;

  String generalMode = "sum_all"; // "sum_all", "sum_best", "best"

  void setGeneralMode(String mode) {
    generalMode = mode;
    notifyListeners();
  }

  void addHeat(Heat heat) {
    _heats.add(heat);
    notifyListeners();
  }

  void updateHeatType(int id, String newType) {
    final heat = _heats.firstWhere((h) => h.id == id);
    heat.type = newType;
    notifyListeners();
  }

  void updateBeaconOrder(int id, List<String> newOrder) {
    final heat = _heats.firstWhere((h) => h.id == id);
    heat.beaconOrder = newOrder;
    notifyListeners();
  }

  void toggleIncludeInGeneral(int id) {
    final heat = _heats.firstWhere((h) => h.id == id);
    heat.includeInGeneral = !heat.includeInGeneral;
    notifyListeners();
  }

  void updateHeatName(int id, String newName) {
    final heat = _heats.firstWhere((p) => p.id == id);
    heat.info = newName;
    notifyListeners();
  }

  void removeHeat(int id) {
    _heats.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

class MapPassageModel extends ChangeNotifier {
  List<Passage> _passages = RaceDemo.demoPassages;

  List<Passage> get passages => _passages;

  List<Passage> get last10 => _passages.reversed.take(10).toList();

  // ---- Chargement depuis SharedPreferences ----
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('passages');

    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      _passages = decoded.map((p) => Passage.fromJson(p)).toList();
    }

    notifyListeners();
  }

  // ---- Sauvegarde ----
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_passages.map((p) => p.toJson()).toList());
    await prefs.setString('passages', jsonString);
  }

  // ---- Ajouter un passage ----
  void addPassage(Passage passage) {
    _passages.add(passage);
    save();
    notifyListeners();
  }
}

class MapRaceModel extends ChangeNotifier {
  List<Race> races = [];
  int? currentCourseId;

  Race get currentRace {
    if (currentCourseId == null) return Race(name: 'null');
    return races.firstWhere(
      (r) => r.id == currentCourseId,
      orElse: () => Race(name: 'null'),
    );
  }

  // Références vers les autres modèles
  late MapPiloteModel piloteModel;
  late MapBeaconModel beaconModel;
  late MapHeatModel heatModel;
  late MapPassageModel passageModel;

  Timer? _autoSaveTimer;

  // ------------------------------------------------------------
  // ATTACH MODELS
  // ------------------------------------------------------------
  void attachModels({
    required MapPiloteModel pilotes,
    required MapBeaconModel beacons,
    required MapHeatModel heats,
    required MapPassageModel passages,
  }) {
    piloteModel = pilotes;
    beaconModel = beacons;
    heatModel = heats;
    passageModel = passages;

    startAutoSave(); // autosave toutes les 30 sec
  }

  // ------------------------------------------------------------
  // AUTO-SAVE
  // ------------------------------------------------------------
  void startAutoSave() {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncCurrentRace(),
    );
  }

  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  // ------------------------------------------------------------
  // SYNC COURSE → met à jour la course active
  // ------------------------------------------------------------
  void syncCurrentRace() {
    if (currentCourseId == null) return;

    final race = races.firstWhere((r) => r.id == currentCourseId);

    race.passages = List.from(passageModel.passages);
    race.heats = List.from(heatModel.heats);
    race.pilots = List.from(piloteModel.pilots);
    race.beacons = List.from(beaconModel.beacons);

    save();
  }

  // ------------------------------------------------------------
  // RESET GLOBAL STATE (nouvelle course)
  // ------------------------------------------------------------
  void resetGlobalState() {
    piloteModel.pilots.clear();
    beaconModel.beacons.clear();
    heatModel.heats.clear();
    passageModel.passages.clear();
    passageModel.save();

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD RACE STATE (charger une course)
  // ------------------------------------------------------------
  void loadRaceState(Race race) {
    piloteModel.pilots
      ..clear()
      ..addAll(race.pilots);

    beaconModel.beacons
      ..clear()
      ..addAll(race.beacons);

    heatModel.heats
      ..clear()
      ..addAll(race.heats);

    passageModel.passages
      ..clear()
      ..addAll(race.passages);

    passageModel.save();

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD FROM STORAGE
  // ------------------------------------------------------------
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString('races');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      races = decoded.map((r) => Race.fromJson(r)).toList();
    }

    currentCourseId = prefs.getInt('current_course_id');

    notifyListeners();
  }

  // ------------------------------------------------------------
  // SAVE TO STORAGE
  // ------------------------------------------------------------
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(races.map((r) => r.toJson()).toList());
    await prefs.setString('races', jsonString);

    if (currentCourseId != null) {
      await prefs.setInt('current_course_id', currentCourseId!);
    }
  }

  // ------------------------------------------------------------
  // SET CURRENT COURSE
  // ------------------------------------------------------------
  void setCurrentCourse(int id) {
    currentCourseId = id;

    final race = races.firstWhere((r) => r.id == id);

    loadRaceState(race);
    save();

    notifyListeners();
  }

  // ------------------------------------------------------------
  // ADD COURSE
  // ------------------------------------------------------------
  void addRace(Race race) {
    races.add(race);
    currentCourseId = race.id;

    resetGlobalState();
    save();

    notifyListeners();
  }

  // ------------------------------------------------------------
  // UPDATE NAME
  // ------------------------------------------------------------
  void updateRaceName(int id, String newName) {
    final race = races.firstWhere((r) => r.id == id);
    race.name = newName;
    save();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // REMOVE COURSE
  // ------------------------------------------------------------
  void removeRace(int id) async {
    races.removeWhere((r) => r.id == id);

    final prefs = await SharedPreferences.getInstance();

    if (currentCourseId == id) {
      currentCourseId = null;
      await prefs.remove('current_course_id');
    }

    save();
    notifyListeners();
  }
}
