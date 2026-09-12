import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/simple_query.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';
import 'load_status.dart';

class SupplierListNotifier
    extends ChangeNotifier {
  final SupplierRepository _repository;

  SupplierListNotifier(
    this._repository,
  );

  SimpleQuery _query =
      const SimpleQuery();

  PageResult<Supplier> _result =
      PageResult<Supplier>.empty();

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  SimpleQuery get query => _query;

  PageResult<Supplier> get result =>
      _result;

  LoadStatus get status => _status;

  String? get error => _error;

  Set<int> get selected =>
      Set.unmodifiable(_selected);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result =
          await _repository.find(
        _query,
      );

      _status = LoadStatus.success;
    } on RequestCancelledException {
      return;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    } catch (e) {
      _error =
          'Неизвестная ошибка: $e';

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

  Future<List<Supplier>> getAll() {
    return _repository.all();
  }

  Future<List<Supplier>>
      getAllActive() async {
    final values =
        await _repository.all();

    return values
        .where(
          (item) =>
              !item.isDeleted,
        )
        .toList();
  }

  Future<Supplier?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<Supplier> create(
    Supplier supplier,
  ) async {
    final created =
        await _repository.create(
      supplier,
    );

    await load();

    return created;
  }

  Future<void> update(
    Supplier supplier,
  ) async {
    await _repository.update(
      supplier,
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