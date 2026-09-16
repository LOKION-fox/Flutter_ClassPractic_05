import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/customer.dart';
import '../models/page_result.dart';
import '../models/simple_query.dart';
import '../repositories/customer_repository.dart';
import 'load_status.dart';

class CustomerListNotifier extends ChangeNotifier {
  final CustomerRepository _repository;

  CustomerListNotifier(
    this._repository,
  );

  SimpleQuery _query = const SimpleQuery(
    sortField: 'lastName',
  );

  PageResult<Customer> _result = PageResult<Customer>.empty();

  LoadStatus _status = LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  SimpleQuery get query => _query;

  PageResult<Customer> get result => _result;

  LoadStatus get status => _status;

  String? get error => _error;

  Set<int> get selected => Set.unmodifiable(_selected);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;

    notifyListeners();

    try {
      _result = await _repository.find(
        _query,
      );

      _status = LoadStatus.success;
    } on RequestCancelledException {
      return;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Неизвестная ошибка: $e';

      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> applyQuery(
    SimpleQuery query,
  ) async {
    _query = query;
    _selected.clear();

    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }

    notifyListeners();
  }

  Future<Customer?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<Customer> create(
    Customer customer,
  ) async {
    final created = await _repository.create(
      customer,
    );

    await load();

    return created;
  }

  Future<void> update(
    Customer customer,
  ) async {
    await _repository.update(
      customer,
    );

    await load();
  }

  Future<void> softDelete(
    int id,
  ) async {
    await _repository.softDelete(id);

    _selected.remove(id);

    await load();
  }

  Future<void> hardDelete(
    int id,
  ) async {
    await _repository.hardDelete(id);

    _selected.remove(id);

    await load();
  }

  Future<void> restore(
    int id,
  ) async {
    await _repository.restore(id);

    await load();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(
      _selected.toList(),
    );

    _selected.clear();

    await load();
  }
}
