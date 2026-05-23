import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Chrono App",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Paramètres Pilote"),
            onTap: () => Navigator.pushNamed(context, '/pilote'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Paramètres Balise"),
            onTap: () => Navigator.pushNamed(context, '/beacon'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Paramètres Manche"),
            onTap: () => Navigator.pushNamed(context, '/heat'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Historique"),
            onTap: () => Navigator.pushNamed(context, '/race'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Live Timing"),
            onTap: () => Navigator.pushNamed(context, '/live'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Resultat"),
            onTap: () => Navigator.pushNamed(context, '/result'),
          ),
          ListTile(
            leading: const Icon(Icons.lens),
            title: const Text("Debug"),
            onTap: () => Navigator.pushNamed(context, '/debug'),
          ),
        ],
      ),
    );
  }
}
