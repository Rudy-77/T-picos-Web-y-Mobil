# vivero_app

App Flutter del Proyecto 1 (Vivero). Consume la API JSON del backend Django de `../backend`; el modelo y las reglas se quedan en el servidor.

Con el backend corriendo en `127.0.0.1:8000`:

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

Para otra URL base (por ejemplo, el emulador de Android): `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`.

Instrucciones completas, endpoints y limitaciones en [../README.md](../README.md).
