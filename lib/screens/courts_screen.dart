import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/app_drawer.dart';

class CourtsScreen extends StatelessWidget {
  static const String routeName = '/courts';

  const CourtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courts = [
      {'id': 'c1', 'name': 'Cancha de Fútbol 1', 'location': 'Sector A'},
      {'id': 'c2', 'name': 'Cancha de Tenis 2', 'location': 'Sector B'},
      {'id': 'c3', 'name': 'Cancha de Baloncesto', 'location': 'Sector C'},
      {'id': 'c4', 'name': 'Cancha de Voleibol', 'location': 'Sector D'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canchas'),
        leading: Builder(
          builder: (ctx) {
            final bool isDark = theme.brightness == Brightness.dark;
            final Color iconColor = isDark
                ? Colors.white
                : AppColors.neutral700;
            return IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNavBar(),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: courts.length,
        itemBuilder: (context, i) {
          final c = courts[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary500,
                child: Text(
                  c['name']![0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(c['name']!),
              subtitle: Text(c['location']!),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // For now show details in a dialog; could push to a detail screen
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(c['name']!),
                    content: Text(
                      'Ubicación: ${c['location']}\nDescripción breve de la cancha.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
