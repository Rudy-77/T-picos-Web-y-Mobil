import 'package:flutter/material.dart';

import 'ej01.dart' as ej01;
import 'ej02.dart' as ej02;
import 'ej03.dart' as ej03;
import 'ej04.dart' as ej04;
import 'ej05.dart' as ej05;
import 'ej05b.dart' as ej05b;
import 'ej06.dart' as ej06;
import 'ej07.dart' as ej07;
import 'ej08.dart' as ej08;
import 'ej09.dart' as ej09;
import 'ej10.dart' as ej10;
import 'ej11.dart' as ej11;
import 'ej12.dart' as ej12;
import 'ej13.dart' as ej13;
import 'ej14.dart' as ej14;
import 'ej15.dart' as ej15;
import 'ej16.dart' as ej16;
import 'ej17.dart' as ej17;
import 'ej18.dart' as ej18;
import 'ej19.dart' as ej19;
import 'ej20.dart' as ej20;
import 'ej21.dart' as ej21;
import 'ej22.dart' as ej22;
import 'ej23.dart' as ej23;
import 'ej24.dart' as ej24;
import 'ej25.dart' as ej25;
import 'ej26.dart' as ej26;
import 'ej27.dart' as ej27;

class _Ejemplo {
  const _Ejemplo(this.numero, this.titulo, this.construir);
  final String numero;
  final String titulo;
  final Widget Function() construir;
}

final _ejemplos = <_Ejemplo>[
  _Ejemplo('01', 'StatelessWidget (folio)', ej01.demo),
  _Ejemplo('02', 'StatefulWidget (contador)', ej02.demo),
  _Ejemplo('03', 'Esqueleto de pantalla', ej03.demo),
  _Ejemplo('04', 'ListView + ListTile', ej04.demo),
  _Ejemplo('05', 'Row + Expanded', ej05.demo),
  _Ejemplo('05b', 'Row SIN Expanded (desborda)', ej05b.demo),
  _Ejemplo('06', 'Switch', ej06.demo),
  _Ejemplo('07', 'DropdownButton', ej07.demo),
  _Ejemplo('08', 'AlertDialog', ej08.demo),
  _Ejemplo('09', 'Navigator (2 pantallas)', ej09.demo),
  _Ejemplo('10', 'CircularProgressIndicator', ej10.demo),
  _Ejemplo('11', 'TextEditingController', ej11.demo),
  _Ejemplo('12', 'Form + TextFormField', ej12.demo),
  _Ejemplo('13', 'SingleChildScrollView', ej13.demo),
  _Ejemplo('14', 'BottomNavigationBar', ej14.demo),
  _Ejemplo('15', 'Pestañas (TabBar)', ej15.demo),
  _Ejemplo('16', 'Drawer', ej16.demo),
  _Ejemplo('17', 'FloatingActionButton', ej17.demo),
  _Ejemplo('18', 'Card + ListTile', ej18.demo),
  _Ejemplo('19', 'RefreshIndicator', ej19.demo),
  _Ejemplo('20', 'FutureBuilder', ej20.demo),
  _Ejemplo('21', 'POST con package:http', ej21.demo),
  _Ejemplo('22', 'ThemeData', ej22.demo),
  _Ejemplo('23', 'GridView', ej23.demo),
  _Ejemplo('24', 'Image.network', ej24.demo),
  _Ejemplo('25', 'SafeArea', ej25.demo),
  _Ejemplo('26', 'Buscador con filtro', ej26.demo),
  _Ejemplo('27', 'Pantalla vacía', ej27.demo),
];

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Galeria(),
  ));
}

class Galeria extends StatelessWidget {
  const Galeria({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galería de ejemplos Flutter')),
      body: ListView.builder(
        itemCount: _ejemplos.length,
        itemBuilder: (context, i) {
          final e = _ejemplos[i];
          return ListTile(
            leading: CircleAvatar(child: Text(e.numero)),
            title: Text(e.titulo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _Visor(ejemplo: e)),
              );
            },
          );
        },
      ),
    );
  }
}

class _Visor extends StatelessWidget {
  const _Visor({required this.ejemplo});

  final _Ejemplo ejemplo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: ejemplo.construir()),
          Material(
            color: Colors.black87,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'Volver a la galería  ·  ${ejemplo.numero} ${ejemplo.titulo}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
