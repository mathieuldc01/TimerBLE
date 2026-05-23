import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/pilot_page.dart';
import 'pages/beacon_page.dart';
import 'pages/heat_page.dart';
import 'pages/race_page.dart';
import 'pages/live_page.dart';
import 'pages/result_page.dart';
import 'pages/debug_page.dart';

import 'services/app_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapPiloteModel()),
        ChangeNotifierProvider(create: (_) => MapDeviceModel()),
        ChangeNotifierProvider(create: (_) => MapBeaconModel()),
        ChangeNotifierProvider(create: (_) => MapHeatModel()),
        ChangeNotifierProvider(create: (_) => MapPassageModel()),
        ChangeNotifierProvider(create: (_) => MapRaceModel()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔥 On attend que les providers soient prêts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;

      // On attache les modèles entre eux
      context.read<MapRaceModel>().attachModels(
        pilotes: context.read<MapPiloteModel>(),
        beacons: context.read<MapBeaconModel>(),
        heats: context.read<MapHeatModel>(),
        passages: context.read<MapPassageModel>(),
      );

      // On attache aussi dans MapDeviceModel si nécessaire
      context.read<MapDeviceModel>().attachModels(
        pilotes: context.read<MapPiloteModel>(),
        heats: context.read<MapHeatModel>(),
        passages: context.read<MapPassageModel>(),
        races: context.read<MapRaceModel>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/pilote',
      routes: {
        '/pilote': (context) => PilotListPage(),
        '/beacon': (context) => BeaconListPage(),
        '/heat': (context) => HeatListPage(),
        '/race': (context) => RaceListPage(),
        '/live': (context) => LivePage(),
        '/result': (context) => ResultPage(),
        '/debug': (context) => DebugPage(),
      },
    );
  }
}
