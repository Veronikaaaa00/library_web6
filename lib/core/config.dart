/// Адрес API только через --dart-define (в исходниках нет «боевого» URL).
/// Локально: --dart-define=API_BASE_URL=http://localhost:8080/api
/// Сборка: flutter build web --release --dart-define=API_BASE_URL=https://…
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
