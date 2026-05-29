// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_dao.dart';

// ignore_for_file: type=lint
mixin _$ShowDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShowCueListsTable get showCueLists => attachedDatabase.showCueLists;
  $ShowCuesTable get showCues => attachedDatabase.showCues;
  ShowDaoManager get managers => ShowDaoManager(this);
}

class ShowDaoManager {
  final _$ShowDaoMixin _db;
  ShowDaoManager(this._db);
  $$ShowCueListsTableTableManager get showCueLists =>
      $$ShowCueListsTableTableManager(_db.attachedDatabase, _db.showCueLists);
  $$ShowCuesTableTableManager get showCues =>
      $$ShowCuesTableTableManager(_db.attachedDatabase, _db.showCues);
}
