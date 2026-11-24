import 'package:flutter/material.dart';

import '../modelos/caracteristicas.dart';
import '../modelos/producto.dart';
import '../servicios/api_vivero.dart';
import '../widgets/estilo.dart';
import 'resultado.dart';

// Solo valido lo básico; los rangos y las reglas los valida el servidor.
class PantallaFormularioEnvio extends StatefulWidget {
  final ApiVivero api;
  final Caracteristicas inicial;
  final Producto? producto;

  const PantallaFormularioEnvio({
    super.key,
    required this.api,
    required this.inicial,
    this.producto,
  });

  @override
  State<PantallaFormularioEnvio> createState() => _PantallaFormularioEnvioState();
}

class _PantallaFormularioEnvioState extends State<PantallaFormularioEnvio> {
  final _formulario = GlobalKey<FormState>();
  late final Caracteristicas _c = widget.inicial;
  late final _diametro = TextEditingController(
    text: _c.raizDesnuda ? '0' : _formatear(_c.diametroMacetaCm),
  );
  String _diametroAnterior = '';

  @override
  void dispose() {
    _diametro.dispose();
    super.dispose();
  }

  // Sin maceta pongo el diámetro en 0 y bloqueo el campo; al desmarcar recupero el valor.
  void _cambiarRaizDesnuda(bool valor) {
    setState(() {
      _c.raizDesnuda = valor;
      if (valor) {
        _diametroAnterior = _diametro.text;
        _diametro.text = '0';
        _c.diametroMacetaCm = 0;
      } else if (_diametroAnterior.isNotEmpty && _diametroAnterior != '0') {
        _diametro.text = _diametroAnterior;
      }
    });
  }

  void _recomendar() {
    if (!_formulario.currentState!.validate()) return;
    _formulario.currentState!.save();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PantallaResultado(api: widget.api, caracteristicas: _c, producto: widget.producto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo envío' : 'Envío: ${widget.producto!.nombre}'),
      ),
      body: AnchoMaximo(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _seccion('La planta'),
              _opciones('Tipo de planta', tiposPlanta, _c.tipoPlanta, (v) => _c.tipoPlanta = v),
              _numero('Altura (cm)', _c.alturaCm, (v) => _c.alturaCm = v),
              _campoDiametro(),
              _entero('Cantidad de plantas', _c.cantidadPlantas, (v) => _c.cantidadPlantas = v),
              _numero('Peso total (kg)', _c.pesoKg, (v) => _c.pesoKg = v),
              _numero(
                'Valor declarado (MXN)',
                _c.valorDeclaradoMxn,
                (v) => _c.valorDeclaradoMxn = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Frágil'),
                value: _c.fragil,
                onChanged: (v) => setState(() => _c.fragil = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Raíz desnuda (sin maceta ni tierra)'),
                subtitle: const Text('Al activarlo, el diámetro de maceta queda en 0'),
                value: _c.raizDesnuda,
                onChanged: _cambiarRaizDesnuda,
              ),
              _seccion('El trayecto'),
              _numero('Distancia (km)', _c.distanciaKm, (v) => _c.distanciaKm = v),
              _entero('Días en tránsito', _c.diasEnTransito, (v) => _c.diasEnTransito = v),
              _numero(
                'Temperatura en el destino (°C)',
                _c.temperaturaDestinoC,
                (v) => _c.temperaturaDestinoC = v,
                permiteNegativo: true,
              ),
              _opciones('Época del año', epocas, _c.epoca, (v) => _c.epoca = v),
              _opciones('Zona de destino', zonasDestino, _c.zonaDestino, (v) => _c.zonaDestino = v),
              _opciones('Prioridad', prioridades, _c.prioridad, (v) => _c.prioridad = v),
              const SizedBox(height: 20),
              Presionable(
                child: FilledButton.icon(
                  onPressed: _recomendar,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Recomendar envío'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => TituloSeccion(titulo);

  Widget _numero(
    String etiqueta,
    double inicial,
    void Function(double) guardar, {
    bool permiteNegativo = false,
  }) {
    return _campo(etiqueta, _formatear(inicial), (texto) {
      final valor = double.tryParse(texto.replaceAll(',', '.'));
      if (valor == null) return 'Escribe un número';
      if (!permiteNegativo && valor < 0) return 'No puede ser negativo';
      return null;
    }, (texto) => guardar(double.parse(texto.replaceAll(',', '.'))));
  }

  Widget _campoDiametro() {
    final bloqueado = _c.raizDesnuda;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: const Key('campo_diametro'),
        controller: _diametro,
        enabled: !bloqueado,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Diámetro de maceta (cm)',
          helperText: bloqueado ? 'Va sin maceta: el diámetro es 0' : null,
          suffixIcon: bloqueado ? const Icon(Icons.lock_outline) : null,
        ),
        validator: (texto) {
          if (bloqueado) return null;
          final valor = double.tryParse((texto ?? '').trim().replaceAll(',', '.'));
          if (valor == null) return 'Escribe un número';
          if (valor < 0) return 'No puede ser negativo';
          return null;
        },
        onSaved: (texto) => _c.diametroMacetaCm = bloqueado
            ? 0
            : double.parse((texto ?? '').trim().replaceAll(',', '.')),
      ),
    );
  }

  Widget _entero(String etiqueta, int inicial, void Function(int) guardar) {
    return _campo(etiqueta, '$inicial', (texto) {
      final valor = int.tryParse(texto);
      if (valor == null || valor < 1) return 'Escribe un entero mayor o igual a 1';
      return null;
    }, (texto) => guardar(int.parse(texto)));
  }

  Widget _campo(
    String etiqueta,
    String inicial,
    String? Function(String) validar,
    void Function(String) guardar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: inicial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(labelText: etiqueta),
        validator: (texto) => validar((texto ?? '').trim()),
        onSaved: (texto) => guardar((texto ?? '').trim()),
      ),
    );
  }

  Widget _opciones(
    String etiqueta,
    Map<String, String> opciones,
    String inicial,
    void Function(String) guardar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: inicial,
        decoration: InputDecoration(labelText: etiqueta),
        items: [
          for (final opcion in opciones.entries)
            DropdownMenuItem(value: opcion.key, child: Text(opcion.value)),
        ],
        onChanged: (v) => guardar(v!),
      ),
    );
  }
}

String _formatear(double valor) =>
    valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : '$valor';
