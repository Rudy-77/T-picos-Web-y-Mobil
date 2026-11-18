import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: ConPestanas()));
}

class ConPestanas extends StatelessWidget {
  const ConPestanas({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seguimiento'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Pedidos en camino')),
            Center(child: Text('Pedidos entregados')),
          ],
        ),
      ),
    );
  }
}
