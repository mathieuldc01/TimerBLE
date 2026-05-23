import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/beacon.dart';

import '../widgets/app_drawer.dart';

class BeaconListPage extends StatelessWidget {
  const BeaconListPage({super.key});

  void showAddDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter Balise"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "ID (obligatoire)",
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Position (0,1,...)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (idController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("L'ID est obligatoire")),
                  );
                  return;
                }

                final id = idController.text;
                if (id == "") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("L'ID ne peut pas etre vide")),
                  );
                  return;
                }

                context.read<MapBeaconModel>().addBeacon(
                  Beacon(
                    id: id,
                    position: nameController.text.isEmpty
                        ? "No Position"
                        : nameController.text,
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  void showEditDialog(BuildContext context, Beacon beacon) {
    final controller = TextEditingController(text: beacon.position);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier Balise"),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapBeaconModel>().updateBeaconName(
                  beacon.id,
                  controller.text,
                );
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(BuildContext context, Beacon beacon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer Balise"),
          content: Text(
            "Voulez-vous vraiment supprimer balise '${beacon.id}' ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapBeaconModel>().removeBeacon(beacon.id);
                Navigator.pop(context);
              },
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MapBeaconModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Balises")),
      drawer: AppDrawer(),
      body: Column(
        children: [
          // ---- En-tête des colonnes ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade300,
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "ID",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Position",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Actions",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ---- Liste des Balises ----
          Expanded(
            child: ListView.builder(
              itemCount: model.beacons.length,
              itemBuilder: (context, index) {
                final beacon = model.beacons[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(beacon.id.toString())),
                      Expanded(flex: 4, child: Text(beacon.position)),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showEditDialog(context, beacon),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  showDeleteDialog(context, beacon),
                            ),
                          ],
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
