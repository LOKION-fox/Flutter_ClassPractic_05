import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../models/animal.dart';
import '../models/animal_query.dart';
import '../models/page_result.dart';
import '../repositories/animal_repository.dart';
import 'load_status.dart';

class AnimalListNotifier extends ChangeNotifier {
  final AnimalRepository _repository;

  AnimalListNotifier(
    this._repository,
  );

  AnimalQuery _query = const AnimalQuery();

  PageResult<Animal> _result = PageResult<Animal>.empty();

  LoadStatus _status = LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  AnimalQuery get query => _query;

  PageResult<Animal> get result => _result;

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
    AnimalQuery query,
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

  Future<Animal?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<Animal> create(
    Animal animal,
  ) async {
    final created = await _repository.create(
      animal,
    );

    await load();

    return created;
  }

  Future<void> update(
    Animal animal,
  ) async {
    await _repository.update(animal);

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
