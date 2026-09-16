class ApiConfig {
  // В ПР6 адрес API задаётся только через --dart-define.
  // Пустое значение означает текущий origin и не содержит
  // зашитого адреса сервера в исходном коде.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const int apiDelayMs = int.fromEnvironment(
    'API_DELAY_MS',
    defaultValue: 0,
  );

  static const int apiFailCode = int.fromEnvironment(
    'API_FAIL_CODE',
    defaultValue: 0,
  );

  // По заданию ПР5:
  // выход через 3 минуты бездействия.
  static const int inactivitySeconds = int.fromEnvironment(
    'SESSION_INACTIVITY_SECONDS',
    defaultValue: 180,
  );

  // Предупреждение за 30 секунд.
  static const int warningSeconds = int.fromEnvironment(
    'SESSION_WARNING_SECONDS',
    defaultValue: 30,
  );

  // Максимальная длительность сессии — 30 минут.
  static const int maxSessionSeconds = int.fromEnvironment(
    'SESSION_MAX_SECONDS',
    defaultValue: 1800,
  );
}
