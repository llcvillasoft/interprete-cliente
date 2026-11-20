/// Valores de compilación. La batería los fija con --dart-define al compilar la web de prueba.
const String urlApi = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

/// Supuesto AD-16: en la primera entrega, el dispositivo y su secreto llegan por compilación.
const String dispositivoApi = String.fromEnvironment('API_DISPOSITIVO', defaultValue: 'dispositivo-local');
const String secretoApi = String.fromEnvironment('API_SECRETO', defaultValue: 'secreto-local');
