import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/heat.dart';
import '../models/beacon.dart';
import '../widgets/app_drawer.dart';

class HeatListPage extends StatelessWidget {
  const HeatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final heats = context.watch<MapHeatModel>().heats;
    final beacons = context.watch<MapBeaconModel>().beacons;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Paramétrage des manches"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Manches"),
              Tab(text: "Général"),
            ],
          ),
        ),
        drawer: AppDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            // Onglet 1 : liste des manches
            heats.isEmpty
                ? const Center(child: Text("Aucune manche enregistrée"))
                : ListView(
                    children: [
                      for (var heat in heats)
                        _buildHeatCard(context, heat, beacons),
                    ],
                  ),

            // Onglet 2 : paramètres généraux
            _buildGeneralSettings(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    final model = context.watch<MapHeatModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mode de classement général",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          RadioListTile(
            title: const Text("Somme des temps (tous)"),
            value: "sum_all",
            groupValue: model.generalMode,
            onChanged: (v) => model.setGeneralMode(v!),
          ),

          RadioListTile(
            title: const Text("Somme des temps (Meilleur par Manche)"),
            value: "sum_best",
            groupValue: model.generalMode,
            onChanged: (v) => model.setGeneralMode(v!),
          ),

          RadioListTile(
            title: const Text("Meilleure temps (toute manche confondu)"),
            value: "best",
            groupValue: model.generalMode,
            onChanged: (v) => model.setGeneralMode(v!),
          ),

          const SizedBox(height: 20),
          Text(
            "Mode actuel : ${model.generalMode}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Carte d'une manche
  // -------------------------------------------------------------
  Widget _buildHeatCard(BuildContext context, Heat heat, List<Beacon> beacons) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text("Manche ${heat.id} — ${heat.info}"),
        children: [
          // Nom
          ListTile(
            title: const Text("Nom de la manche"),
            subtitle: Text(heat.info),
            trailing: const Icon(Icons.edit),
            onTap: () => _showEditNameDialog(context, heat),
          ),

          // Type
          ListTile(
            title: const Text("Type de course"),
            subtitle: Text(heat.type),
            trailing: DropdownButton<String>(
              value: heat.type,
              items: const [
                DropdownMenuItem(value: "line", child: Text("Simple")),
                DropdownMenuItem(value: "laps", child: Text("Tours")),
              ],
              onChanged: (v) {
                context.read<MapHeatModel>().updateHeatType(heat.id, v!);
              },
            ),
          ),

          // Bouton pour modifier les balises impliquées
          ListTile(
            title: const Text("Modifier les balises impliquées"),
            trailing: const Icon(Icons.edit),
            onTap: () => _showBeaconSelector(context, heat, beacons),
          ),

          // Liste réordonnable des balises sélectionnées
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Balises impliquées",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          if (heat.beaconOrder.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Aucune balise sélectionnée"),
            ),

          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              final order = [...heat.beaconOrder];
              final item = order.removeAt(oldIndex);
              order.insert(newIndex, item);
              context.read<MapHeatModel>().updateBeaconOrder(heat.id, order);
            },
            children: [
              for (var bId in heat.beaconOrder)
                ListTile(key: ValueKey(bId), title: Text("Beacon $bId")),
            ],
          ),

          // Inclure dans classement général
          SwitchListTile(
            title: const Text("Inclure dans classement général"),
            value: heat.includeInGeneral,
            onChanged: (_) {
              context.read<MapHeatModel>().toggleIncludeInGeneral(heat.id);
            },
          ),

          // Supprimer
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "Supprimer la manche",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => _showDeleteDialog(context, heat),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Sélecteur de balises impliquées
  // -------------------------------------------------------------
  void _showBeaconSelector(
    BuildContext context,
    Heat heat,
    List<Beacon> beacons,
  ) {
    List<String> selected = [...heat.beaconOrder];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Sélectionner les balises"),
            content: SizedBox(
              width: 300,
              height: 400,
              child: ListView(
                children: [
                  for (var b in beacons)
                    CheckboxListTile(
                      title: Text("Beacon ${b.id} — ${b.position}"),
                      value: selected.contains(b.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(b.id);
                          } else {
                            selected.remove(b.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<MapHeatModel>().updateBeaconOrder(
                    heat.id,
                    selected,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Valider"),
              ),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. Ajouter une manche
  // -------------------------------------------------------------
  void _showAddDialog(BuildContext context) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter une manche"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "ID"),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nom"),
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
              final id = int.tryParse(idCtrl.text);
              if (id == null) return;

              context.read<MapHeatModel>().addHeat(
                Heat(id: id, info: nameCtrl.text),
              );

              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. Modifier nom
  // -------------------------------------------------------------
  void _showEditNameDialog(BuildContext context, Heat heat) {
    final ctrl = TextEditingController(text: heat.info);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le nom"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MapHeatModel>().updateHeatName(heat.id, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. Supprimer
  // -------------------------------------------------------------
  void _showDeleteDialog(BuildContext context, Heat heat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer la manche"),
        content: Text("Supprimer la manche ${heat.id} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MapHeatModel>().removeHeat(heat.id);
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
