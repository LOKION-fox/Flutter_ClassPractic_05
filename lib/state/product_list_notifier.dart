import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/product_repository.dart';
import 'load_status.dart';

class ProductListNotifier
    extends ChangeNotifier {
  final ProductRepository _repository;

  ProductListNotifier(
    this._repository,
  );

  ProductQuery _query =
      const ProductQuery();

  PageResult<Product> _result =
      PageResult<Product>.empty();

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  ProductQuery get query => _query;

  PageResult<Product> get result =>
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
    ProductQuery query,
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

  Future<Product?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<List<Product>> getAll() {
    return _repository.all();
  }

  Future<Product> create(
    Product product,
  ) async {
    final created =
        await _repository.create(
      product,
    );

    await load();

    return created;
  }

  Future<void> update(
    Product product,
  ) async {
    await _repository.update(
      product,
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