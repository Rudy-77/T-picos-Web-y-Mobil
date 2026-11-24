// Cambio la URL base al correr con --dart-define=API_BASE_URL=http://<host>:8000
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');
