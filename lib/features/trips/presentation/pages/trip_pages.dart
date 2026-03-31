import 'package:flutter/material.dart';

class TripRequestPage extends StatelessWidget {
  const TripRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande de course'),
      ),
      body: const Center(
        child: Text('Page de demande de course - À implémenter'),
      ),
    );
  }
}

class TripProgressPage extends StatelessWidget {
  final String tripId;

  const TripProgressPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course en cours'),
      ),
      body: Center(
        child: Text('Progression de la course: $tripId - À implémenter'),
      ),
    );
  }
}
