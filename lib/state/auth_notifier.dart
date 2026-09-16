import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../core/auth_session.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import '../models/auth_result.dart';

class AuthNotifier extends ChangeNotifier {
  static const _accessKey = 'auth_access_token';

  static const _refreshKey = 'auth_refresh_token';

  static const _userKey = 'auth_user';

  // Это значение используется ТОЛЬКО
  // для отображения интерфейса.
  //
  // Сервер ему не доверяет.
  //
  // Оно специально оставлено в localStorage,
  // чтобы выполнить пункт 17 практической.
  static const _uiRoleKey = 'auth_ui_role';

  static const _sessionStartedKey = 'auth_session_started';

  static const _lastActivityKey = 'auth_last_activity';

  final SharedPreferences _prefs;
  final AuthService _api;
  final AuthSession _session;

  AppUser? _user;
  AppRole? _uiRole;

  DateTime? _sessionStartedAt;
  DateTime? _lastActivityAt;

  String? _notice;

  Future<bool>? _refreshFuture;

  DateTime? _lastActivitySavedAt;

  AuthNotifier(
    this._prefs,
    this._api,
    this._session,
  );

  AppUser? get user => _user;

  AppRole? get uiRole => _uiRole;

  String? get accessToken => _session.accessToken;

  String? get notice => _notice;

  DateTime? get sessionStartedAt => _sessionStartedAt;

  DateTime? get lastActivityAt => _lastActivityAt;

  bool get isAuthenticated => _user != null && _session.isAuthorized;

  bool isUiRole(
    AppRole role,
  ) {
    return _uiRole == role;
  }

  bool can(
    AppPermission permission,
  ) {
    final role = _uiRole;

    if (role == null) {
      return false;
    }

    return roleHasPermission(
      role,
      permission,
    );
  }

  void clearNotice() {
    _notice = null;
  }

  Future<void> restore() async {
    final access = _prefs.getString(
      _accessKey,
    );

    final refresh = _prefs.getString(
      _refreshKey,
    );

    if (access == null) {
      return;
    }

    _session.accessToken = access;
    _session.refreshToken = refresh;

    final cachedUser = _prefs.getString(
      _userKey,
    );

    if (cachedUser != null) {
      try {
        _user = AppUser.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              cachedUser,
            ) as Map,
          ),
        );
      } catch (_) {
        _user = null;
      }
    }

    _uiRole = tryParseRole(
          _prefs.getString(
            _uiRoleKey,
          ),
        ) ??
        _user?.role;

    final startedMs = _prefs.getInt(
      _sessionStartedKey,
    );

    final activityMs = _prefs.getInt(
      _lastActivityKey,
    );

    if (startedMs != null) {
      _sessionStartedAt = DateTime.fromMillisecondsSinceEpoch(
        startedMs,
      );
    }

    if (activityMs != null) {
      _lastActivityAt = DateTime.fromMillisecondsSinceEpoch(
        activityMs,
      );
    }

    final now = DateTime.now();

    if (_sessionStartedAt != null) {
      final total = now.difference(
        _sessionStartedAt!,
      );

      if (total >=
          const Duration(
            seconds: ApiConfig.maxSessionSeconds,
          )) {
        await forceLogout(
          'Максимальное время сессии истекло.',
        );

        return;
      }
    }

    if (_lastActivityAt != null) {
      final inactive = now.difference(
        _lastActivityAt!,
      );

      if (inactive >=
          const Duration(
            seconds: ApiConfig.inactivitySeconds,
          )) {
        await forceLogout(
          'Сессия завершена из-за неактивности.',
        );

        return;
      }
    }

    try {
      // Настоящая роль приходит
      // с сервера.
      //
      // _uiRole намеренно не заменяем:
      // она является лишь состоянием UI.
      _user = await _api.me();

      await _saveUser();
    } on UnauthorizedException {
      final success = await refreshTokens();

      if (!success) {
        return;
      }
    } on ApiException {
      // Сервер временно недоступен.
      // Локальную сессию не уничтожаем.
    }

    if (_sessionStartedAt == null) {
      _sessionStartedAt = DateTime.now();

      await _prefs.setInt(
        _sessionStartedKey,
        _sessionStartedAt!.millisecondsSinceEpoch,
      );
    }

    if (_lastActivityAt == null) {
      _lastActivityAt = DateTime.now();

      await _prefs.setInt(
        _lastActivityKey,
        _lastActivityAt!.millisecondsSinceEpoch,
      );
    }

    notifyListeners();
  }

  Future<void> login(
    String username,
    String password,
  ) async {
    final result = await _api.login(
      username,
      password,
    );

    await _applyNewLogin(
      result,
    );
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String password,
  }) async {
    await _api.register(
      username: username,
      fullName: fullName,
      password: password,
    );

    await login(
      username,
      password,
    );
  }

  Future<void> _applyNewLogin(
    AuthResult result,
  ) async {
    _session.accessToken = result.accessToken;

    _session.refreshToken = result.refreshToken;

    _user = result.user;

    // При настоящем входе UI-роль
    // всегда возвращается к роли,
    // полученной от сервера.
    _uiRole = result.user.role;

    _sessionStartedAt = DateTime.now();

    _lastActivityAt = DateTime.now();

    _notice = null;

    await _prefs.setString(
      _accessKey,
      result.accessToken,
    );

    await _prefs.setString(
      _refreshKey,
      result.refreshToken,
    );

    await _prefs.setString(
      _uiRoleKey,
      result.user.role.value,
    );

    await _saveUser();

    await _prefs.setInt(
      _sessionStartedKey,
      _sessionStartedAt!.millisecondsSinceEpoch,
    );

    await _prefs.setInt(
      _lastActivityKey,
      _lastActivityAt!.millisecondsSinceEpoch,
    );

    notifyListeners();
  }

  Future<bool> refreshTokens() {
    final running = _refreshFuture;

    if (running != null) {
      return running;
    }

    final future = _refreshTokensInternal();

    _refreshFuture = future;

    future.whenComplete(
      () {
        _refreshFuture = null;
      },
    );

    return future;
  }

  Future<bool> _refreshTokensInternal() async {
    final refresh = _session.refreshToken;

    if (refresh == null || refresh.isEmpty) {
      await forceLogout(
        'Сессия истекла. Войдите снова.',
      );

      return false;
    }

    try {
      final result = await _api.refresh(
        refresh,
      );

      _session.accessToken = result.accessToken;

      _session.refreshToken = result.refreshToken;

      _user = result.user;

      await _prefs.setString(
        _accessKey,
        result.accessToken,
      );

      await _prefs.setString(
        _refreshKey,
        result.refreshToken,
      );

      await _saveUser();

      notifyListeners();

      return true;
    } catch (_) {
      await forceLogout(
        'Сессия истекла. Войдите снова.',
      );

      return false;
    }
  }

  Future<void> logout() async {
    final refresh = _session.refreshToken;

    try {
      await _api.logout(
        refresh,
      );
    } catch (_) {
      // Даже если сервер недоступен,
      // локальный выход всё равно
      // должен выполниться.
    }

    await _clearSession();

    notifyListeners();
  }

  Future<void> forceLogout(
    String message,
  ) async {
    _notice = message;

    await _clearSession();

    notifyListeners();
  }

  Future<void> _clearSession() async {
    _session.clear();

    _user = null;
    _uiRole = null;

    _sessionStartedAt = null;
    _lastActivityAt = null;

    await _prefs.remove(
      _accessKey,
    );

    await _prefs.remove(
      _refreshKey,
    );

    await _prefs.remove(
      _userKey,
    );

    await _prefs.remove(
      _uiRoleKey,
    );

    await _prefs.remove(
      _sessionStartedKey,
    );

    await _prefs.remove(
      _lastActivityKey,
    );
  }

  Future<void> _saveUser() async {
    final value = _user;

    if (value == null) {
      return;
    }

    await _prefs.setString(
      _userKey,
      jsonEncode(
        value.toJson(),
      ),
    );
  }

  void recordActivity() {
    if (!isAuthenticated) {
      return;
    }

    final now = DateTime.now();

    _lastActivityAt = now;

    final previous = _lastActivitySavedAt;

    if (previous == null ||
        now.difference(previous) >=
            const Duration(
              seconds: 5,
            )) {
      _lastActivitySavedAt = now;

      _prefs.setInt(
        _lastActivityKey,
        now.millisecondsSinceEpoch,
      );
    }
  }
}
