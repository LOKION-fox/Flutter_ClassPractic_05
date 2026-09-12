import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import '../repositories/user_admin_repository.dart';
import 'load_status.dart';

class UserAdminNotifier
    extends ChangeNotifier {
  final UserAdminRepository
      _repository;

  UserAdminNotifier(
    this._repository,
  );

  List<AppUser> _users = [];

  Map<String, int>
      _statistics = {};

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  List<AppUser> get users =>
      _users;

  Map<String, int>
      get statistics =>
          _statistics;

  LoadStatus get status =>
      _status;

  String? get error =>
      _error;

  Future<void> loadUsers() async {
    _status = LoadStatus.loading;
    _error = null;

    notifyListeners();

    try {
      _users =
          await _repository
              .findUsers();

      _status =
          LoadStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status =
          LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> changeRole(
    int userId,
    AppRole role,
  ) async {
    await _repository.changeRole(
      userId,
      role,
    );

    await loadUsers();
  }

  Future<void>
      loadStatistics() async {
    _status =
        LoadStatus.loading;

    _error = null;

    notifyListeners();

    try {
      _statistics =
          await _repository
              .getStatistics();

      _status =
          LoadStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status =
          LoadStatus.error;
    }

    notifyListeners();
  }
}