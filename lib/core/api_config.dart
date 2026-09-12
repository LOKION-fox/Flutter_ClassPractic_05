class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'http://localhost:8080/api',
  );

  static const int apiDelayMs =
      int.fromEnvironment(
    'API_DELAY_MS',
    defaultValue: 0,
  );

  static const int apiFailCode =
      int.fromEnvironment(
    'API_FAIL_CODE',
    defaultValue: 0,
  );

  // По заданию:
  // выход через 3 минуты бездействия.
  static const int inactivitySeconds =
      int.fromEnvironment(
    'SESSION_INACTIVITY_SECONDS',
    defaultValue: 180,
  );

  // Предупреждение за 30 секунд.
  static const int warningSeconds =
      int.fromEnvironment(
    'SESSION_WARNING_SECONDS',
    defaultValue: 30,
  );

  // Максимальная длительность сессии.
  // Выбрано 30 минут.
  static const int maxSessionSeconds =
      int.fromEnvironment(
    'SESSION_MAX_SECONDS',
    defaultValue: 1800,
  );
}