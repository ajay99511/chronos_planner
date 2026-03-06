import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'todo_item_dao.g.dart';

@DriftAccessor(tables: [TodoItems])
class TodoItemDao extends DatabaseAccessor<AppDatabase>
    with _$TodoItemDaoMixin {
  TodoItemDao(super.db);

  Future<List<TodoItem>> getAllTodos() => select(todoItems).get();

  Stream<List<TodoItem>> watchAllTodos() => (select(todoItems)
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
        ]))
      .watch();

  Future<int> insertTodo(Insertable<TodoItem> todo) =>
      into(todoItems).insert(todo);

  Future<bool> updateTodo(Insertable<TodoItem> todo) =>
      update(todoItems).replace(todo);

  Future<int> deleteTodoById(String id) =>
      (delete(todoItems)..where((t) => t.id.equals(id))).go();
}
