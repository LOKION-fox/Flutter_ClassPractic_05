import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_config.dart';
import '../state/auth_notifier.dart';

class SessionWatcher extends StatefulWidget {
  final AuthNotifier auth;
  final Widget child;

  const SessionWatcher({
    super.key,
    required this.auth,
    required this.child,
  });

  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  Timer? _absoluteTimer;

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(_onKey);

    widget.auth.addListener(
      _onAuthChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncTimers(),
    );
  }

  bool _onKey(
    KeyEvent event,
  ) {
    _activity();

    return false;
  }

  void _onAuthChanged() {
    _syncTimers();
  }

  void _activity() {
    if (!widget.auth.isAuthenticated) {
      return;
    }

    widget.auth.recordActivity();

    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

    _scheduleInactivity();
  }

  void _syncTimers() {
    if (!widget.auth.isAuthenticated) {
      _cancelTimers();

      return;
    }

    _scheduleInactivity();
    _scheduleAbsolute();
  }

  void _scheduleInactivity() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();

    const timeout = Duration(
      seconds: ApiConfig.inactivitySeconds,
    );

    const warning = Duration(
      seconds: ApiConfig.warningSeconds,
    );

    final last = widget.auth.lastActivityAt ?? DateTime.now();

    final elapsed = DateTime.now().difference(last);

    var remaining = timeout - elapsed;

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    var warningDelay = remaining - warning;

    if (warningDelay.isNegative) {
      warningDelay = Duration.zero;
    }

    _warningTimer = Timer(
      warningDelay,
      _showWarning,
    );

    _logoutTimer = Timer(
      remaining,
      _logoutInactive,
    );
  }

  void _scheduleAbsolute() {
    _absoluteTimer?.cancel();

    final started = widget.auth.sessionStartedAt;

    if (started == null) {
      return;
    }

    const maxDuration = Duration(
      seconds: ApiConfig.maxSessionSeconds,
    );

    var remaining = maxDuration -
        DateTime.now().difference(
          started,
        );

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    _absoluteTimer = Timer(
      remaining,
      _logoutAbsolute,
    );
  }

  void _showWarning() {
    if (!mounted || !widget.auth.isAuthenticated) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        duration: Duration(
          seconds: ApiConfig.warningSeconds,
        ),
        content: Text(
          'Сессия завершится через 30 секунд '
          'из-за отсутствия активности.',
        ),
      ),
    );
  }

  Future<void> _logoutInactive() async {
    await widget.auth.forceLogout(
      'Сессия завершена после 3 минут бездействия.',
    );
  }

  Future<void> _logoutAbsolute() async {
    await widget.auth.forceLogout(
      'Завершено максимальное время сессии.',
    );
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _absoluteTimer?.cancel();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);

    widget.auth.removeListener(
      _onAuthChanged,
    );

    _cancelTimers();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _activity();
      },
      onPointerMove: (_) {
        _activity();
      },
      onPointerSignal: (_) {
        _activity();
      },
      child: widget.child,
    );
  }
}
