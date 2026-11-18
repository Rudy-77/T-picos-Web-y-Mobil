import 'package:flutter/material.dart';

Widget demo() {
  late Widget w;
  void runApp(Widget x) {
    w = x;
  }

  runApp(const MaterialApp(home: ListaPedidos()));
  return w;
}

class ListaPedidos extends StatelessWidget {
  const ListaPedidos({super.key});

  static const folios = ['D2757CBE', 'A1B2C3D4', 'F00D1234'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: ListView.builder(
        itemCount: folios.length,
        itemBuilder: (context, i) {
          return ListTile(
            leading: const Icon(Icons.local_shipping),
            title: Text(folios[i]),
            subtitle: const Text('tocar para ver detalle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Elegiste ${folios[i]}')),
              );
            },
          );
        },
      ),
    );
  }
}
