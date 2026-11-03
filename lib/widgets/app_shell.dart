import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cinema_model.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
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
            icon: Consumer<CinemaModel>(
              builder: (context, model, child) => Badge(
                key: const ValueKey('tickets-badge'),
                label: Text('${model.activeReservationCount}'),
                isLabelVisible: model.activeReservationCount > 0,
                child: child!,
              ),
              child: const Icon(Icons.confirmation_number_outlined),
            ),
            selectedIcon: Consumer<CinemaModel>(
              builder: (context, model, child) => Badge(
                key: const ValueKey('tickets-selected-badge'),
                label: Text('${model.activeReservationCount}'),
                isLabelVisible: model.activeReservationCount > 0,
                child: child!,
              ),
              child: const Icon(Icons.confirmation_number),
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
