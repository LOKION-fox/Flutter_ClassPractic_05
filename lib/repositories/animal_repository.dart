import '../models/animal.dart';
import '../models/animal_query.dart';
import '../models/page_result.dart';

abstract interface class AnimalRepository {
  Future<PageResult<Animal>> find(
    AnimalQuery query,
  );

  Future<List<Animal>> all();

  Future<Animal?> findById(int id);

  Future<Animal> create(
    Animal animal,
  );

  Future<void> update(
    Animal animal,
  );

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(
    List<int> ids,
  );
}
