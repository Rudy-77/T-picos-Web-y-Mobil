import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class Colores {
  static const morado = Color(0xFF4F2BAB);
  static const dorado = Color(0xFFD4A24A);
  static const fondo = Color(0xFF121018);
  static const superficie = Color(0xFF1C1925);
  static const borde = Color(0xFF2E2A3A);
  static const texto = Color(0xFFF2F0F7);
  static const textoTenue = Color(0xFFA9A4B8);
  static const exito = Color(0xFF7FC99A);
  static const error = Color(0xFFF08A8A);
}

ThemeData temaVivero({bool fuentesWeb = true}) {
  TextStyle condensada(TextStyle estilo) =>
      fuentesWeb ? GoogleFonts.barlowCondensed(textStyle: estilo) : estilo;

  const esquema = ColorScheme(
    brightness: Brightness.dark,
    primary: Colores.dorado,
    onPrimary: Color(0xFF1B1206),
    primaryContainer: Colores.morado,
    onPrimaryContainer: Colores.texto,
    secondary: Colores.morado,
    onSecondary: Colores.texto,
    secondaryContainer: Colores.morado,
    onSecondaryContainer: Colores.texto,
    tertiaryContainer: Color(0xFF3A2F1A),
    onTertiaryContainer: Color(0xFFF1DDB4),
    error: Colores.error,
    onError: Color(0xFF2B0000),
    surface: Colores.fondo,
    onSurface: Colores.texto,
    onSurfaceVariant: Colores.textoTenue,
    surfaceContainerLow: Colores.superficie,
    surfaceContainer: Colores.superficie,
    surfaceContainerHigh: Colores.superficie,
    surfaceContainerHighest: Colores.borde,
    outline: Colores.borde,
    outlineVariant: Colores.borde,
  );

  final base = ThemeData(colorScheme: esquema, useMaterial3: true);
  final textoBase = fuentesWeb ? GoogleFonts.barlowTextTheme(base.textTheme) : base.textTheme;
  final texto = textoBase.apply(bodyColor: Colores.texto, displayColor: Colores.texto);
  TextStyle titulo(TextStyle? estilo) => condensada(estilo!.copyWith(fontWeight: FontWeight.w700));
  final redondeo = BorderRadius.circular(10);

  return base.copyWith(
    scaffoldBackgroundColor: Colores.fondo,
    textTheme: texto.copyWith(
      headlineMedium: titulo(texto.headlineMedium),
      headlineSmall: titulo(texto.headlineSmall),
      titleLarge: titulo(texto.titleLarge),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.texto,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: condensada(
        const TextStyle(color: Colores.texto, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: redondeo),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficie,
      border: OutlineInputBorder(borderRadius: redondeo, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: redondeo,
        borderSide: const BorderSide(color: Colores.dorado),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: redondeo),
        textStyle: texto.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colores.morado,
      foregroundColor: Colores.texto,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colores.superficie,
      selectedColor: Colores.morado,
      side: BorderSide.none,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    // Apagado, el switch usa el color del borde y casi no se ve; por eso lo cambio.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? Colores.fondo : Colores.textoTenue,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? Colores.dorado : Colores.textoTenue,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: Colores.dorado,
      // leading/trailing no heredan la fuente del textTheme; la indico aquí.
      leadingAndTrailingTextStyle: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: Colores.borde, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colores.dorado,
      linearTrackColor: Colores.borde,
    ),
  );
}
