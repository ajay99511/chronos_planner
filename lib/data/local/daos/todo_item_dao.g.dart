// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_item_dao.dart';

// ignore_for_file: type=lint
mixin _$TodoItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $TodoItemsTable get todoItems => attachedDatabase.todoItems;
  TodoItemDaoManager get managers => TodoItemDaoManager(this);
}

class TodoItemDaoManager {
  final _$TodoItemDaoMixin _db;
  TodoItemDaoManager(this._db);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db.attachedDatabase, _db.todoItems);
}
