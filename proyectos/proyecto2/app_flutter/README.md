# vivero_app

App Flutter del Proyecto 2 (Vivero): catálogo, recomendador de envío y chat con el asistente. Consume la API JSON del backend Django de `../backend`; los modelos y las reglas se quedan en el servidor.

Con el backend corriendo en `127.0.0.1:8000`:

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

Para otra URL base: `flutter run -d chrome --dart-define=API_BASE_URL=http://<host>:8000`.

Instrucciones completas, endpoints y limitaciones en [../README.md](../README.md).
