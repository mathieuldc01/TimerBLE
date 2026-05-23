import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/app_drawer.dart';
import '../models/pilot.dart';

class LivePage extends StatelessWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<MapDeviceModel>();
    final passages = context.watch<MapPassageModel>();
    final pilots = context.watch<MapPiloteModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Live Timing")),

      drawer: AppDrawer(),

      body: Column(
        children: [
          // ================= DEVICES =================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Devices détectés",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // SCAN BUTTON
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<MapDeviceModel>().scanDevices();
                  },

                  icon: const Icon(Icons.search),

                  label: const Text("Scanner"),
                ),

                const SizedBox(height: 10),

                // ================= DEVICE LIST =================
                if (bt.devices.isEmpty)
                  const Text("Aucun device détecté")
                else
                  SizedBox(
                    height: 300,

                    child: ListView.builder(
                      itemCount: bt.devices.length,

                      itemBuilder: (context, index) {
                        final d = bt.devices[index];

                        // Nom advertising
                        final advName = d.bleDevice.platformName.isNotEmpty
                            ? d.bleDevice.platformName
                            : d.bleDevice.advName;

                        // ESP32_<id>
                        final deviceId = advName.replaceFirst("ESP32_", "");

                        // 👉 Chercher le pilote
                        Pilot pilot;
                        try {
                          pilot = pilots.pilots.firstWhere(
                            (p) => p.id.toString() == deviceId,
                          );
                        } catch (_) {
                          // 👉 Pilote inconnu → on le crée
                          pilot = Pilot(id: deviceId, name: "Unknown");

                          // 👉 On l’ajoute dans la liste des pilotes
                          pilots.addPilot(pilot);
                        }

                        return Card(
                          child: ExpansionTile(
                            title: Text(
                              "${pilot.name} ($deviceId)",

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text("État : ${d.state}"),

                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                ),

                                child: SizedBox(
                                  width: double.infinity,

                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.read<MapDeviceModel>().nextState(
                                        d.id,
                                      );
                                    },

                                    child: Text(
                                      d.state == "detected"
                                          ? "Connecter"
                                          : d.state == "connected"
                                          ? "Get Data"
                                          : "Supprimer",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 20),

          // ================= PASSAGES =================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Padding(
                  padding: EdgeInsets.all(12),

                  child: Text(
                    "10 derniers passages",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: passages.last10.length,

                    itemBuilder: (context, index) {
                      final p = passages.last10[index];
                      final name = pilots.pilots
                          .firstWhere(
                            (pilot) => pilot.id == p.pilotId,
                            orElse: () => Pilot(id: "null", name: "unknown"),
                          )
                          .name;

                      return ListTile(
                        title: Text("Pilote : ${name}"),

                        subtitle: Text(
                          "Heat : ${p.heatId} | Passage : ${p.number}",
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
