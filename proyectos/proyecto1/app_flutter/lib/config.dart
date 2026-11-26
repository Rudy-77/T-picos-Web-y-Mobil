// URL base del backend; se cambia al correr:
//   Chrome:              flutter run -d chrome 
//   Emulador Android:    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
//   Celular en el WiFi:  flutter run --dart-define=API_BASE_URL=http://<IP-de-la-PC>:8000
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');
