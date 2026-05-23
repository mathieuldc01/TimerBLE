import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/race.dart';

import '../widgets/app_drawer.dart';

class RaceListPage extends StatelessWidget {
  const RaceListPage({super.key});

  void showAddDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter race"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nom (obligatoire)",
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Le nom est obligatoire")),
                  );
                  return;
                }

                context.read<MapRaceModel>().addRace(
                  Race(name: nameController.text),
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

  void showEditDialog(BuildContext context, Race race) {
    final controller = TextEditingController(text: race.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier race"),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapRaceModel>().updateRaceName(
                  race.id,
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

  void showDeleteDialog(BuildContext context, Race race) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer race"),
          content: Text("Voulez-vous vraiment supprimer '${race.name}' ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MapRaceModel>().removeRace(race.id);
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
    final manager = context.watch<MapRaceModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Courses")),
      drawer: AppDrawer(),
      body: ListView.builder(
        itemCount: manager.races.length,
        itemBuilder: (context, index) {
          final race = manager.races[index];

          return ListTile(
            title: Text(race.name),
            subtitle: Text("Passages : ${race.passages.length}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => showEditDialog(context, race),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => showDeleteDialog(context, race),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () {
                    context.read<MapRaceModel>().setCurrentCourse(race.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Course '${race.name}' reprise")),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
