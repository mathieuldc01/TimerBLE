import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/pilot.dart';

import '../widgets/app_drawer.dart';

class PilotListPage extends StatelessWidget {
  const PilotListPage({super.key});

  void showAddDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter pilote"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: "ID (obligatoire)",
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom (optionnel)"),
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
                    const SnackBar(content: Text("L'ID ne doit pas etre vide")),
                  );
                  return;
                }

                context.read<MapPiloteModel>().addPilot(
                  Pilot(
                    id: id,
                    name: nameController.text.isEmpty
                        ? "No Name"
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

  void showEditDialog(BuildContext context, Pilot pilot) {
    final controller = TextEditingController(text: pilot.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier pilote"),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapPiloteModel>().updatePilotName(
                  pilot.id,
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

  void showDeleteDialog(BuildContext context, Pilot pilot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer pilote"),
          content: Text("Voulez-vous vraiment supprimer '${pilot.name}' ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapPiloteModel>().removePilot(pilot.id);
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
    final model = context.watch<MapPiloteModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Pilotes")),
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
                    "Nom",
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

          // ---- Liste des pilotes ----
          Expanded(
            child: ListView.builder(
              itemCount: model.pilots.length,
              itemBuilder: (context, index) {
                final pilot = model.pilots[index];

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
                      Expanded(flex: 2, child: Text(pilot.id.toString())),
                      Expanded(flex: 4, child: Text(pilot.name)),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showEditDialog(context, pilot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDeleteDialog(context, pilot),
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
