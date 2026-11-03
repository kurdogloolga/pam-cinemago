import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cinema_model.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final activeReservations = context
        .watch<CinemaModel>()
        .activeReservationCount;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_movies_outlined),
            selectedIcon: Icon(Icons.local_movies),
            label: 'Афиша',
          ),
          NavigationDestination(
            icon: Badge(
              key: ValueKey('tickets-badge'),
              label: Text('$activeReservations'),
              isLabelVisible: activeReservations > 0,
              child: Icon(Icons.confirmation_number_outlined),
            ),
            selectedIcon: Badge(
              key: const ValueKey('tickets-selected-badge'),
              label: Text('$activeReservations'),
              isLabelVisible: activeReservations > 0,
              child: Icon(Icons.confirmation_number),
            ),
            label: 'Мои билеты',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
