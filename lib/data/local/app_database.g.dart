// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DayPlansTable extends DayPlans with TableInfo<$DayPlansTable, DayPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateStrMeta =
      const VerificationMeta('dateStr');
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
      'date_str', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<String> dayOfWeek = GeneratedColumn<String>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _weekKeyMeta =
      const VerificationMeta('weekKey');
  @override
  late final GeneratedColumn<String> weekKey = GeneratedColumn<String>(
      'week_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, dateStr, dayOfWeek, date, weekKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_plans';
  @override
  VerificationContext validateIntegrity(Insertable<DayPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_str')) {
      context.handle(_dateStrMeta,
          dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta));
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('week_key')) {
      context.handle(_weekKeyMeta,
          weekKey.isAcceptableOrUnknown(data['week_key']!, _weekKeyMeta));
    } else if (isInserting) {
      context.missing(_weekKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      dateStr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_str'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_of_week'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      weekKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_key'])!,
    );
  }

  @override
  $DayPlansTable createAlias(String alias) {
    return $DayPlansTable(attachedDatabase, alias);
  }
}

class DayPlan extends DataClass implements Insertable<DayPlan> {
  final String id;
  final String dateStr;
  final String dayOfWeek;
  final DateTime date;
  final String weekKey;
  const DayPlan(
      {required this.id,
      required this.dateStr,
      required this.dayOfWeek,
      required this.date,
      required this.weekKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_str'] = Variable<String>(dateStr);
    map['day_of_week'] = Variable<String>(dayOfWeek);
    map['date'] = Variable<DateTime>(date);
    map['week_key'] = Variable<String>(weekKey);
    return map;
  }

  DayPlansCompanion toCompanion(bool nullToAbsent) {
    return DayPlansCompanion(
      id: Value(id),
      dateStr: Value(dateStr),
      dayOfWeek: Value(dayOfWeek),
      date: Value(date),
      weekKey: Value(weekKey),
    );
  }

  factory DayPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayPlan(
      id: serializer.fromJson<String>(json['id']),
      dateStr: serializer.fromJson<String>(json['dateStr']),
      dayOfWeek: serializer.fromJson<String>(json['dayOfWeek']),
      date: serializer.fromJson<DateTime>(json['date']),
      weekKey: serializer.fromJson<String>(json['weekKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateStr': serializer.toJson<String>(dateStr),
      'dayOfWeek': serializer.toJson<String>(dayOfWeek),
      'date': serializer.toJson<DateTime>(date),
      'weekKey': serializer.toJson<String>(weekKey),
    };
  }

  DayPlan copyWith(
          {String? id,
          String? dateStr,
          String? dayOfWeek,
          DateTime? date,
          String? weekKey}) =>
      DayPlan(
        id: id ?? this.id,
        dateStr: dateStr ?? this.dateStr,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        date: date ?? this.date,
        weekKey: weekKey ?? this.weekKey,
      );
  DayPlan copyWithCompanion(DayPlansCompanion data) {
    return DayPlan(
      id: data.id.present ? data.id.value : this.id,
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      date: data.date.present ? data.date.value : this.date,
      weekKey: data.weekKey.present ? data.weekKey.value : this.weekKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayPlan(')
          ..write('id: $id, ')
          ..write('dateStr: $dateStr, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('date: $date, ')
          ..write('weekKey: $weekKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateStr, dayOfWeek, date, weekKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayPlan &&
          other.id == this.id &&
          other.dateStr == this.dateStr &&
          other.dayOfWeek == this.dayOfWeek &&
          other.date == this.date &&
          other.weekKey == this.weekKey);
}

class DayPlansCompanion extends UpdateCompanion<DayPlan> {
  final Value<String> id;
  final Value<String> dateStr;
  final Value<String> dayOfWeek;
  final Value<DateTime> date;
  final Value<String> weekKey;
  final Value<int> rowid;
  const DayPlansCompanion({
    this.id = const Value.absent(),
    this.dateStr = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.date = const Value.absent(),
    this.weekKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayPlansCompanion.insert({
    required String id,
    required String dateStr,
    required String dayOfWeek,
    required DateTime date,
    required String weekKey,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        dateStr = Value(dateStr),
        dayOfWeek = Value(dayOfWeek),
        date = Value(date),
        weekKey = Value(weekKey);
  static Insertable<DayPlan> custom({
    Expression<String>? id,
    Expression<String>? dateStr,
    Expression<String>? dayOfWeek,
    Expression<DateTime>? date,
    Expression<String>? weekKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateStr != null) 'date_str': dateStr,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (date != null) 'date': date,
      if (weekKey != null) 'week_key': weekKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayPlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? dateStr,
      Value<String>? dayOfWeek,
      Value<DateTime>? date,
      Value<String>? weekKey,
      Value<int>? rowid}) {
    return DayPlansCompanion(
      id: id ?? this.id,
      dateStr: dateStr ?? this.dateStr,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      date: date ?? this.date,
      weekKey: weekKey ?? this.weekKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<String>(dayOfWeek.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (weekKey.present) {
      map['week_key'] = Variable<String>(weekKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayPlansCompanion(')
          ..write('id: $id, ')
          ..write('dateStr: $dateStr, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('date: $date, ')
          ..write('weekKey: $weekKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<String> energyLevel = GeneratedColumn<String>(
      'energy_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _estimatedCostMeta =
      const VerificationMeta('estimatedCost');
  @override
  late final GeneratedColumn<double> estimatedCost = GeneratedColumn<double>(
      'estimated_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _actualCostMeta =
      const VerificationMeta('actualCost');
  @override
  late final GeneratedColumn<double> actualCost = GeneratedColumn<double>(
      'actual_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dayPlanIdMeta =
      const VerificationMeta('dayPlanId');
  @override
  late final GeneratedColumn<String> dayPlanId = GeneratedColumn<String>(
      'day_plan_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES day_plans (id)'));
  static const VerificationMeta _sourceTemplateIdMeta =
      const VerificationMeta('sourceTemplateId');
  @override
  late final GeneratedColumn<String> sourceTemplateId = GeneratedColumn<String>(
      'source_template_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startTime,
        endTime,
        type,
        priority,
        energyLevel,
        estimatedCost,
        actualCost,
        completed,
        dayPlanId,
        sourceTemplateId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('estimated_cost')) {
      context.handle(
          _estimatedCostMeta,
          estimatedCost.isAcceptableOrUnknown(
              data['estimated_cost']!, _estimatedCostMeta));
    }
    if (data.containsKey('actual_cost')) {
      context.handle(
          _actualCostMeta,
          actualCost.isAcceptableOrUnknown(
              data['actual_cost']!, _actualCostMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('day_plan_id')) {
      context.handle(
          _dayPlanIdMeta,
          dayPlanId.isAcceptableOrUnknown(
              data['day_plan_id']!, _dayPlanIdMeta));
    } else if (isInserting) {
      context.missing(_dayPlanIdMeta);
    }
    if (data.containsKey('source_template_id')) {
      context.handle(
          _sourceTemplateIdMeta,
          sourceTemplateId.isAcceptableOrUnknown(
              data['source_template_id']!, _sourceTemplateIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}energy_level'])!,
      estimatedCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}estimated_cost'])!,
      actualCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_cost'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      dayPlanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_plan_id'])!,
      sourceTemplateId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_template_id'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final String type;
  final String priority;
  final String energyLevel;
  final double estimatedCost;
  final double actualCost;
  final bool completed;
  final String dayPlanId;
  final String sourceTemplateId;
  const Task(
      {required this.id,
      required this.title,
      required this.description,
      required this.startTime,
      required this.endTime,
      required this.type,
      required this.priority,
      required this.energyLevel,
      required this.estimatedCost,
      required this.actualCost,
      required this.completed,
      required this.dayPlanId,
      required this.sourceTemplateId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['type'] = Variable<String>(type);
    map['priority'] = Variable<String>(priority);
    map['energy_level'] = Variable<String>(energyLevel);
    map['estimated_cost'] = Variable<double>(estimatedCost);
    map['actual_cost'] = Variable<double>(actualCost);
    map['completed'] = Variable<bool>(completed);
    map['day_plan_id'] = Variable<String>(dayPlanId);
    map['source_template_id'] = Variable<String>(sourceTemplateId);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      type: Value(type),
      priority: Value(priority),
      energyLevel: Value(energyLevel),
      estimatedCost: Value(estimatedCost),
      actualCost: Value(actualCost),
      completed: Value(completed),
      dayPlanId: Value(dayPlanId),
      sourceTemplateId: Value(sourceTemplateId),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      type: serializer.fromJson<String>(json['type']),
      priority: serializer.fromJson<String>(json['priority']),
      energyLevel: serializer.fromJson<String>(json['energyLevel']),
      estimatedCost: serializer.fromJson<double>(json['estimatedCost']),
      actualCost: serializer.fromJson<double>(json['actualCost']),
      completed: serializer.fromJson<bool>(json['completed']),
      dayPlanId: serializer.fromJson<String>(json['dayPlanId']),
      sourceTemplateId: serializer.fromJson<String>(json['sourceTemplateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'type': serializer.toJson<String>(type),
      'priority': serializer.toJson<String>(priority),
      'energyLevel': serializer.toJson<String>(energyLevel),
      'estimatedCost': serializer.toJson<double>(estimatedCost),
      'actualCost': serializer.toJson<double>(actualCost),
      'completed': serializer.toJson<bool>(completed),
      'dayPlanId': serializer.toJson<String>(dayPlanId),
      'sourceTemplateId': serializer.toJson<String>(sourceTemplateId),
    };
  }

  Task copyWith(
          {String? id,
          String? title,
          String? description,
          String? startTime,
          String? endTime,
          String? type,
          String? priority,
          String? energyLevel,
          double? estimatedCost,
          double? actualCost,
          bool? completed,
          String? dayPlanId,
          String? sourceTemplateId}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        energyLevel: energyLevel ?? this.energyLevel,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        actualCost: actualCost ?? this.actualCost,
        completed: completed ?? this.completed,
        dayPlanId: dayPlanId ?? this.dayPlanId,
        sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      type: data.type.present ? data.type.value : this.type,
      priority: data.priority.present ? data.priority.value : this.priority,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      estimatedCost: data.estimatedCost.present
          ? data.estimatedCost.value
          : this.estimatedCost,
      actualCost:
          data.actualCost.present ? data.actualCost.value : this.actualCost,
      completed: data.completed.present ? data.completed.value : this.completed,
      dayPlanId: data.dayPlanId.present ? data.dayPlanId.value : this.dayPlanId,
      sourceTemplateId: data.sourceTemplateId.present
          ? data.sourceTemplateId.value
          : this.sourceTemplateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedCost: $estimatedCost, ')
          ..write('actualCost: $actualCost, ')
          ..write('completed: $completed, ')
          ..write('dayPlanId: $dayPlanId, ')
          ..write('sourceTemplateId: $sourceTemplateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      type,
      priority,
      energyLevel,
      estimatedCost,
      actualCost,
      completed,
      dayPlanId,
      sourceTemplateId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.type == this.type &&
          other.priority == this.priority &&
          other.energyLevel == this.energyLevel &&
          other.estimatedCost == this.estimatedCost &&
          other.actualCost == this.actualCost &&
          other.completed == this.completed &&
          other.dayPlanId == this.dayPlanId &&
          other.sourceTemplateId == this.sourceTemplateId);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> type;
  final Value<String> priority;
  final Value<String> energyLevel;
  final Value<double> estimatedCost;
  final Value<double> actualCost;
  final Value<bool> completed;
  final Value<String> dayPlanId;
  final Value<String> sourceTemplateId;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.type = const Value.absent(),
    this.priority = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.estimatedCost = const Value.absent(),
    this.actualCost = const Value.absent(),
    this.completed = const Value.absent(),
    this.dayPlanId = const Value.absent(),
    this.sourceTemplateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String startTime,
    required String endTime,
    required String type,
    this.priority = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.estimatedCost = const Value.absent(),
    this.actualCost = const Value.absent(),
    this.completed = const Value.absent(),
    required String dayPlanId,
    this.sourceTemplateId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime),
        type = Value(type),
        dayPlanId = Value(dayPlanId);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? type,
    Expression<String>? priority,
    Expression<String>? energyLevel,
    Expression<double>? estimatedCost,
    Expression<double>? actualCost,
    Expression<bool>? completed,
    Expression<String>? dayPlanId,
    Expression<String>? sourceTemplateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      if (actualCost != null) 'actual_cost': actualCost,
      if (completed != null) 'completed': completed,
      if (dayPlanId != null) 'day_plan_id': dayPlanId,
      if (sourceTemplateId != null) 'source_template_id': sourceTemplateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? description,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<String>? type,
      Value<String>? priority,
      Value<String>? energyLevel,
      Value<double>? estimatedCost,
      Value<double>? actualCost,
      Value<bool>? completed,
      Value<String>? dayPlanId,
      Value<String>? sourceTemplateId,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      energyLevel: energyLevel ?? this.energyLevel,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      completed: completed ?? this.completed,
      dayPlanId: dayPlanId ?? this.dayPlanId,
      sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<String>(energyLevel.value);
    }
    if (estimatedCost.present) {
      map['estimated_cost'] = Variable<double>(estimatedCost.value);
    }
    if (actualCost.present) {
      map['actual_cost'] = Variable<double>(actualCost.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (dayPlanId.present) {
      map['day_plan_id'] = Variable<String>(dayPlanId.value);
    }
    if (sourceTemplateId.present) {
      map['source_template_id'] = Variable<String>(sourceTemplateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedCost: $estimatedCost, ')
          ..write('actualCost: $actualCost, ')
          ..write('completed: $completed, ')
          ..write('dayPlanId: $dayPlanId, ')
          ..write('sourceTemplateId: $sourceTemplateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanTemplatesTable extends PlanTemplates
    with TableInfo<$PlanTemplatesTable, PlanTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _activeDaysMeta =
      const VerificationMeta('activeDays');
  @override
  late final GeneratedColumn<String> activeDays = GeneratedColumn<String>(
      'active_days', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [id, name, description, activeDays];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_templates';
  @override
  VerificationContext validateIntegrity(Insertable<PlanTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('active_days')) {
      context.handle(
          _activeDaysMeta,
          activeDays.isAcceptableOrUnknown(
              data['active_days']!, _activeDaysMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      activeDays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}active_days'])!,
    );
  }

  @override
  $PlanTemplatesTable createAlias(String alias) {
    return $PlanTemplatesTable(attachedDatabase, alias);
  }
}

class PlanTemplate extends DataClass implements Insertable<PlanTemplate> {
  final String id;
  final String name;
  final String description;
  final String activeDays;
  const PlanTemplate(
      {required this.id,
      required this.name,
      required this.description,
      required this.activeDays});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['active_days'] = Variable<String>(activeDays);
    return map;
  }

  PlanTemplatesCompanion toCompanion(bool nullToAbsent) {
    return PlanTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      activeDays: Value(activeDays),
    );
  }

  factory PlanTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      activeDays: serializer.fromJson<String>(json['activeDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'activeDays': serializer.toJson<String>(activeDays),
    };
  }

  PlanTemplate copyWith(
          {String? id,
          String? name,
          String? description,
          String? activeDays}) =>
      PlanTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        activeDays: activeDays ?? this.activeDays,
      );
  PlanTemplate copyWithCompanion(PlanTemplatesCompanion data) {
    return PlanTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      activeDays:
          data.activeDays.present ? data.activeDays.value : this.activeDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('activeDays: $activeDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, activeDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.activeDays == this.activeDays);
}

class PlanTemplatesCompanion extends UpdateCompanion<PlanTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> activeDays;
  final Value<int> rowid;
  const PlanTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.activeDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanTemplatesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.activeDays = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<PlanTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? activeDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (activeDays != null) 'active_days': activeDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String>? activeDays,
      Value<int>? rowid}) {
    return PlanTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      activeDays: activeDays ?? this.activeDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (activeDays.present) {
      map['active_days'] = Variable<String>(activeDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('activeDays: $activeDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateTasksTable extends TemplateTasks
    with TableInfo<$TemplateTasksTable, TemplateTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES plan_templates (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<String> energyLevel = GeneratedColumn<String>(
      'energy_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _estimatedCostMeta =
      const VerificationMeta('estimatedCost');
  @override
  late final GeneratedColumn<double> estimatedCost = GeneratedColumn<double>(
      'estimated_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        templateId,
        title,
        description,
        startTime,
        endTime,
        type,
        priority,
        energyLevel,
        estimatedCost
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<TemplateTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('estimated_cost')) {
      context.handle(
          _estimatedCostMeta,
          estimatedCost.isAcceptableOrUnknown(
              data['estimated_cost']!, _estimatedCostMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}energy_level'])!,
      estimatedCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}estimated_cost'])!,
    );
  }

  @override
  $TemplateTasksTable createAlias(String alias) {
    return $TemplateTasksTable(attachedDatabase, alias);
  }
}

class TemplateTask extends DataClass implements Insertable<TemplateTask> {
  final String id;
  final String templateId;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final String type;
  final String priority;
  final String energyLevel;
  final double estimatedCost;
  const TemplateTask(
      {required this.id,
      required this.templateId,
      required this.title,
      required this.description,
      required this.startTime,
      required this.endTime,
      required this.type,
      required this.priority,
      required this.energyLevel,
      required this.estimatedCost});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['type'] = Variable<String>(type);
    map['priority'] = Variable<String>(priority);
    map['energy_level'] = Variable<String>(energyLevel);
    map['estimated_cost'] = Variable<double>(estimatedCost);
    return map;
  }

  TemplateTasksCompanion toCompanion(bool nullToAbsent) {
    return TemplateTasksCompanion(
      id: Value(id),
      templateId: Value(templateId),
      title: Value(title),
      description: Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      type: Value(type),
      priority: Value(priority),
      energyLevel: Value(energyLevel),
      estimatedCost: Value(estimatedCost),
    );
  }

  factory TemplateTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateTask(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      type: serializer.fromJson<String>(json['type']),
      priority: serializer.fromJson<String>(json['priority']),
      energyLevel: serializer.fromJson<String>(json['energyLevel']),
      estimatedCost: serializer.fromJson<double>(json['estimatedCost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'type': serializer.toJson<String>(type),
      'priority': serializer.toJson<String>(priority),
      'energyLevel': serializer.toJson<String>(energyLevel),
      'estimatedCost': serializer.toJson<double>(estimatedCost),
    };
  }

  TemplateTask copyWith(
          {String? id,
          String? templateId,
          String? title,
          String? description,
          String? startTime,
          String? endTime,
          String? type,
          String? priority,
          String? energyLevel,
          double? estimatedCost}) =>
      TemplateTask(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        title: title ?? this.title,
        description: description ?? this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        energyLevel: energyLevel ?? this.energyLevel,
        estimatedCost: estimatedCost ?? this.estimatedCost,
      );
  TemplateTask copyWithCompanion(TemplateTasksCompanion data) {
    return TemplateTask(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      type: data.type.present ? data.type.value : this.type,
      priority: data.priority.present ? data.priority.value : this.priority,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      estimatedCost: data.estimatedCost.present
          ? data.estimatedCost.value
          : this.estimatedCost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateTask(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedCost: $estimatedCost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, title, description, startTime,
      endTime, type, priority, energyLevel, estimatedCost);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateTask &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.type == this.type &&
          other.priority == this.priority &&
          other.energyLevel == this.energyLevel &&
          other.estimatedCost == this.estimatedCost);
}

class TemplateTasksCompanion extends UpdateCompanion<TemplateTask> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> type;
  final Value<String> priority;
  final Value<String> energyLevel;
  final Value<double> estimatedCost;
  final Value<int> rowid;
  const TemplateTasksCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.type = const Value.absent(),
    this.priority = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.estimatedCost = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateTasksCompanion.insert({
    required String id,
    required String templateId,
    required String title,
    this.description = const Value.absent(),
    required String startTime,
    required String endTime,
    required String type,
    this.priority = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.estimatedCost = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        templateId = Value(templateId),
        title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime),
        type = Value(type);
  static Insertable<TemplateTask> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? type,
    Expression<String>? priority,
    Expression<String>? energyLevel,
    Expression<double>? estimatedCost,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? templateId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? startTime,
      Value<String>? endTime,
      Value<String>? type,
      Value<String>? priority,
      Value<String>? energyLevel,
      Value<double>? estimatedCost,
      Value<int>? rowid}) {
    return TemplateTasksCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      energyLevel: energyLevel ?? this.energyLevel,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<String>(energyLevel.value);
    }
    if (estimatedCost.present) {
      map['estimated_cost'] = Variable<double>(estimatedCost.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateTasksCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedCost: $estimatedCost, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(Insertable<Preference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Preference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) => Preference(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTable extends TodoItems
    with TableInfo<$TodoItemsTable, TodoItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('note'));
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _checklistJsonMeta =
      const VerificationMeta('checklistJson');
  @override
  late final GeneratedColumn<String> checklistJson = GeneratedColumn<String>(
      'checklist_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _audioFilePathMeta =
      const VerificationMeta('audioFilePath');
  @override
  late final GeneratedColumn<String> audioFilePath = GeneratedColumn<String>(
      'audio_file_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        completed,
        createdAt,
        itemType,
        durationMinutes,
        checklistJson,
        audioFilePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  VerificationContext validateIntegrity(Insertable<TodoItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('checklist_json')) {
      context.handle(
          _checklistJsonMeta,
          checklistJson.isAcceptableOrUnknown(
              data['checklist_json']!, _checklistJsonMeta));
    }
    if (data.containsKey('audio_file_path')) {
      context.handle(
          _audioFilePathMeta,
          audioFilePath.isAcceptableOrUnknown(
              data['audio_file_path']!, _audioFilePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      checklistJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checklist_json'])!,
      audioFilePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}audio_file_path'])!,
    );
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(attachedDatabase, alias);
  }
}

class TodoItem extends DataClass implements Insertable<TodoItem> {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;

  /// Discriminator: 'note', 'timer', or 'list'
  final String itemType;

  /// Timer-only: duration in minutes
  final int durationMinutes;

  /// List-only: JSON-encoded array of checklist items
  /// e.g. [{"text":"Buy milk","done":false},{"text":"Walk dog","done":true}]
  final String checklistJson;

  /// Timer-only: path to local audio file played on completion
  final String audioFilePath;
  const TodoItem(
      {required this.id,
      required this.title,
      required this.description,
      required this.completed,
      required this.createdAt,
      required this.itemType,
      required this.durationMinutes,
      required this.checklistJson,
      required this.audioFilePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['completed'] = Variable<bool>(completed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['item_type'] = Variable<String>(itemType);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['checklist_json'] = Variable<String>(checklistJson);
    map['audio_file_path'] = Variable<String>(audioFilePath);
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      completed: Value(completed),
      createdAt: Value(createdAt),
      itemType: Value(itemType),
      durationMinutes: Value(durationMinutes),
      checklistJson: Value(checklistJson),
      audioFilePath: Value(audioFilePath),
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      completed: serializer.fromJson<bool>(json['completed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      itemType: serializer.fromJson<String>(json['itemType']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      checklistJson: serializer.fromJson<String>(json['checklistJson']),
      audioFilePath: serializer.fromJson<String>(json['audioFilePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'completed': serializer.toJson<bool>(completed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'itemType': serializer.toJson<String>(itemType),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'checklistJson': serializer.toJson<String>(checklistJson),
      'audioFilePath': serializer.toJson<String>(audioFilePath),
    };
  }

  TodoItem copyWith(
          {String? id,
          String? title,
          String? description,
          bool? completed,
          DateTime? createdAt,
          String? itemType,
          int? durationMinutes,
          String? checklistJson,
          String? audioFilePath}) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
        itemType: itemType ?? this.itemType,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        checklistJson: checklistJson ?? this.checklistJson,
        audioFilePath: audioFilePath ?? this.audioFilePath,
      );
  TodoItem copyWithCompanion(TodoItemsCompanion data) {
    return TodoItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      completed: data.completed.present ? data.completed.value : this.completed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      checklistJson: data.checklistJson.present
          ? data.checklistJson.value
          : this.checklistJson,
      audioFilePath: data.audioFilePath.present
          ? data.audioFilePath.value
          : this.audioFilePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemType: $itemType, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('audioFilePath: $audioFilePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, completed, createdAt,
      itemType, durationMinutes, checklistJson, audioFilePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.completed == this.completed &&
          other.createdAt == this.createdAt &&
          other.itemType == this.itemType &&
          other.durationMinutes == this.durationMinutes &&
          other.checklistJson == this.checklistJson &&
          other.audioFilePath == this.audioFilePath);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItem> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<bool> completed;
  final Value<DateTime> createdAt;
  final Value<String> itemType;
  final Value<int> durationMinutes;
  final Value<String> checklistJson;
  final Value<String> audioFilePath;
  final Value<int> rowid;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.itemType = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.audioFilePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.itemType = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.audioFilePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title);
  static Insertable<TodoItem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? completed,
    Expression<DateTime>? createdAt,
    Expression<String>? itemType,
    Expression<int>? durationMinutes,
    Expression<String>? checklistJson,
    Expression<String>? audioFilePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (completed != null) 'completed': completed,
      if (createdAt != null) 'created_at': createdAt,
      if (itemType != null) 'item_type': itemType,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (checklistJson != null) 'checklist_json': checklistJson,
      if (audioFilePath != null) 'audio_file_path': audioFilePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? description,
      Value<bool>? completed,
      Value<DateTime>? createdAt,
      Value<String>? itemType,
      Value<int>? durationMinutes,
      Value<String>? checklistJson,
      Value<String>? audioFilePath,
      Value<int>? rowid}) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      itemType: itemType ?? this.itemType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      checklistJson: checklistJson ?? this.checklistJson,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (checklistJson.present) {
      map['checklist_json'] = Variable<String>(checklistJson.value);
    }
    if (audioFilePath.present) {
      map['audio_file_path'] = Variable<String>(audioFilePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemType: $itemType, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('audioFilePath: $audioFilePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DayPlansTable dayPlans = $DayPlansTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PlanTemplatesTable planTemplates = $PlanTemplatesTable(this);
  late final $TemplateTasksTable templateTasks = $TemplateTasksTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final DayPlanDao dayPlanDao = DayPlanDao(this as AppDatabase);
  late final TemplateDao templateDao = TemplateDao(this as AppDatabase);
  late final PreferenceDao preferenceDao = PreferenceDao(this as AppDatabase);
  late final TodoItemDao todoItemDao = TodoItemDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [dayPlans, tasks, planTemplates, templateTasks, preferences, todoItems];
}

typedef $$DayPlansTableCreateCompanionBuilder = DayPlansCompanion Function({
  required String id,
  required String dateStr,
  required String dayOfWeek,
  required DateTime date,
  required String weekKey,
  Value<int> rowid,
});
typedef $$DayPlansTableUpdateCompanionBuilder = DayPlansCompanion Function({
  Value<String> id,
  Value<String> dateStr,
  Value<String> dayOfWeek,
  Value<DateTime> date,
  Value<String> weekKey,
  Value<int> rowid,
});

final class $$DayPlansTableReferences
    extends BaseReferences<_$AppDatabase, $DayPlansTable, DayPlan> {
  $$DayPlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks,
          aliasName: $_aliasNameGenerator(db.dayPlans.id, db.tasks.dayPlanId));

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.dayPlanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DayPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DayPlansTable> {
  $$DayPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekKey => $composableBuilder(
      column: $table.weekKey, builder: (column) => ColumnFilters(column));

  Expression<bool> tasksRefs(
      Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.dayPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DayPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DayPlansTable> {
  $$DayPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekKey => $composableBuilder(
      column: $table.weekKey, builder: (column) => ColumnOrderings(column));
}

class $$DayPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayPlansTable> {
  $$DayPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<String> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get weekKey =>
      $composableBuilder(column: $table.weekKey, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
      Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.dayPlanId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DayPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DayPlansTable,
    DayPlan,
    $$DayPlansTableFilterComposer,
    $$DayPlansTableOrderingComposer,
    $$DayPlansTableAnnotationComposer,
    $$DayPlansTableCreateCompanionBuilder,
    $$DayPlansTableUpdateCompanionBuilder,
    (DayPlan, $$DayPlansTableReferences),
    DayPlan,
    PrefetchHooks Function({bool tasksRefs})> {
  $$DayPlansTableTableManager(_$AppDatabase db, $DayPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> dateStr = const Value.absent(),
            Value<String> dayOfWeek = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> weekKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DayPlansCompanion(
            id: id,
            dateStr: dateStr,
            dayOfWeek: dayOfWeek,
            date: date,
            weekKey: weekKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String dateStr,
            required String dayOfWeek,
            required DateTime date,
            required String weekKey,
            Value<int> rowid = const Value.absent(),
          }) =>
              DayPlansCompanion.insert(
            id: id,
            dateStr: dateStr,
            dayOfWeek: dayOfWeek,
            date: date,
            weekKey: weekKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DayPlansTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<DayPlan, $DayPlansTable, Task>(
                        currentTable: table,
                        referencedTable:
                            $$DayPlansTableReferences._tasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DayPlansTableReferences(db, table, p0).tasksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.dayPlanId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DayPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DayPlansTable,
    DayPlan,
    $$DayPlansTableFilterComposer,
    $$DayPlansTableOrderingComposer,
    $$DayPlansTableAnnotationComposer,
    $$DayPlansTableCreateCompanionBuilder,
    $$DayPlansTableUpdateCompanionBuilder,
    (DayPlan, $$DayPlansTableReferences),
    DayPlan,
    PrefetchHooks Function({bool tasksRefs})>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String> description,
  required String startTime,
  required String endTime,
  required String type,
  Value<String> priority,
  Value<String> energyLevel,
  Value<double> estimatedCost,
  Value<double> actualCost,
  Value<bool> completed,
  required String dayPlanId,
  Value<String> sourceTemplateId,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<String> startTime,
  Value<String> endTime,
  Value<String> type,
  Value<String> priority,
  Value<String> energyLevel,
  Value<double> estimatedCost,
  Value<double> actualCost,
  Value<bool> completed,
  Value<String> dayPlanId,
  Value<String> sourceTemplateId,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DayPlansTable _dayPlanIdTable(_$AppDatabase db) => db.dayPlans
      .createAlias($_aliasNameGenerator(db.tasks.dayPlanId, db.dayPlans.id));

  $$DayPlansTableProcessedTableManager get dayPlanId {
    final $_column = $_itemColumn<String>('day_plan_id')!;

    final manager = $$DayPlansTableTableManager($_db, $_db.dayPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayPlanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualCost => $composableBuilder(
      column: $table.actualCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceTemplateId => $composableBuilder(
      column: $table.sourceTemplateId,
      builder: (column) => ColumnFilters(column));

  $$DayPlansTableFilterComposer get dayPlanId {
    final $$DayPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayPlanId,
        referencedTable: $db.dayPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DayPlansTableFilterComposer(
              $db: $db,
              $table: $db.dayPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualCost => $composableBuilder(
      column: $table.actualCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceTemplateId => $composableBuilder(
      column: $table.sourceTemplateId,
      builder: (column) => ColumnOrderings(column));

  $$DayPlansTableOrderingComposer get dayPlanId {
    final $$DayPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayPlanId,
        referencedTable: $db.dayPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DayPlansTableOrderingComposer(
              $db: $db,
              $table: $db.dayPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => column);

  GeneratedColumn<double> get actualCost => $composableBuilder(
      column: $table.actualCost, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get sourceTemplateId => $composableBuilder(
      column: $table.sourceTemplateId, builder: (column) => column);

  $$DayPlansTableAnnotationComposer get dayPlanId {
    final $$DayPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayPlanId,
        referencedTable: $db.dayPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DayPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.dayPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool dayPlanId})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String> endTime = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> energyLevel = const Value.absent(),
            Value<double> estimatedCost = const Value.absent(),
            Value<double> actualCost = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<String> dayPlanId = const Value.absent(),
            Value<String> sourceTemplateId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: type,
            priority: priority,
            energyLevel: energyLevel,
            estimatedCost: estimatedCost,
            actualCost: actualCost,
            completed: completed,
            dayPlanId: dayPlanId,
            sourceTemplateId: sourceTemplateId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> description = const Value.absent(),
            required String startTime,
            required String endTime,
            required String type,
            Value<String> priority = const Value.absent(),
            Value<String> energyLevel = const Value.absent(),
            Value<double> estimatedCost = const Value.absent(),
            Value<double> actualCost = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            required String dayPlanId,
            Value<String> sourceTemplateId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: type,
            priority: priority,
            energyLevel: energyLevel,
            estimatedCost: estimatedCost,
            actualCost: actualCost,
            completed: completed,
            dayPlanId: dayPlanId,
            sourceTemplateId: sourceTemplateId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({dayPlanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayPlanId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayPlanId,
                    referencedTable: $$TasksTableReferences._dayPlanIdTable(db),
                    referencedColumn:
                        $$TasksTableReferences._dayPlanIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool dayPlanId})>;
typedef $$PlanTemplatesTableCreateCompanionBuilder = PlanTemplatesCompanion
    Function({
  required String id,
  required String name,
  Value<String> description,
  Value<String> activeDays,
  Value<int> rowid,
});
typedef $$PlanTemplatesTableUpdateCompanionBuilder = PlanTemplatesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<String> activeDays,
  Value<int> rowid,
});

final class $$PlanTemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $PlanTemplatesTable, PlanTemplate> {
  $$PlanTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateTasksTable, List<TemplateTask>>
      _templateTasksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.templateTasks,
              aliasName: $_aliasNameGenerator(
                  db.planTemplates.id, db.templateTasks.templateId));

  $$TemplateTasksTableProcessedTableManager get templateTasksRefs {
    final manager = $$TemplateTasksTableTableManager($_db, $_db.templateTasks)
        .filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateTasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlanTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanTemplatesTable> {
  $$PlanTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => ColumnFilters(column));

  Expression<bool> templateTasksRefs(
      Expression<bool> Function($$TemplateTasksTableFilterComposer f) f) {
    final $$TemplateTasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.templateTasks,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemplateTasksTableFilterComposer(
              $db: $db,
              $table: $db.templateTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanTemplatesTable> {
  $$PlanTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => ColumnOrderings(column));
}

class $$PlanTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanTemplatesTable> {
  $$PlanTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get activeDays => $composableBuilder(
      column: $table.activeDays, builder: (column) => column);

  Expression<T> templateTasksRefs<T extends Object>(
      Expression<T> Function($$TemplateTasksTableAnnotationComposer a) f) {
    final $$TemplateTasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.templateTasks,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TemplateTasksTableAnnotationComposer(
              $db: $db,
              $table: $db.templateTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlanTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlanTemplatesTable,
    PlanTemplate,
    $$PlanTemplatesTableFilterComposer,
    $$PlanTemplatesTableOrderingComposer,
    $$PlanTemplatesTableAnnotationComposer,
    $$PlanTemplatesTableCreateCompanionBuilder,
    $$PlanTemplatesTableUpdateCompanionBuilder,
    (PlanTemplate, $$PlanTemplatesTableReferences),
    PlanTemplate,
    PrefetchHooks Function({bool templateTasksRefs})> {
  $$PlanTemplatesTableTableManager(_$AppDatabase db, $PlanTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> activeDays = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanTemplatesCompanion(
            id: id,
            name: name,
            description: description,
            activeDays: activeDays,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> description = const Value.absent(),
            Value<String> activeDays = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanTemplatesCompanion.insert(
            id: id,
            name: name,
            description: description,
            activeDays: activeDays,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlanTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateTasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateTasksRefs) db.templateTasks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateTasksRefs)
                    await $_getPrefetchedData<PlanTemplate, $PlanTemplatesTable,
                            TemplateTask>(
                        currentTable: table,
                        referencedTable: $$PlanTemplatesTableReferences
                            ._templateTasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlanTemplatesTableReferences(db, table, p0)
                                .templateTasksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.templateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlanTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlanTemplatesTable,
    PlanTemplate,
    $$PlanTemplatesTableFilterComposer,
    $$PlanTemplatesTableOrderingComposer,
    $$PlanTemplatesTableAnnotationComposer,
    $$PlanTemplatesTableCreateCompanionBuilder,
    $$PlanTemplatesTableUpdateCompanionBuilder,
    (PlanTemplate, $$PlanTemplatesTableReferences),
    PlanTemplate,
    PrefetchHooks Function({bool templateTasksRefs})>;
typedef $$TemplateTasksTableCreateCompanionBuilder = TemplateTasksCompanion
    Function({
  required String id,
  required String templateId,
  required String title,
  Value<String> description,
  required String startTime,
  required String endTime,
  required String type,
  Value<String> priority,
  Value<String> energyLevel,
  Value<double> estimatedCost,
  Value<int> rowid,
});
typedef $$TemplateTasksTableUpdateCompanionBuilder = TemplateTasksCompanion
    Function({
  Value<String> id,
  Value<String> templateId,
  Value<String> title,
  Value<String> description,
  Value<String> startTime,
  Value<String> endTime,
  Value<String> type,
  Value<String> priority,
  Value<String> energyLevel,
  Value<double> estimatedCost,
  Value<int> rowid,
});

final class $$TemplateTasksTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateTasksTable, TemplateTask> {
  $$TemplateTasksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PlanTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.planTemplates.createAlias($_aliasNameGenerator(
          db.templateTasks.templateId, db.planTemplates.id));

  $$PlanTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$PlanTemplatesTableTableManager($_db, $_db.planTemplates)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TemplateTasksTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateTasksTable> {
  $$TemplateTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => ColumnFilters(column));

  $$PlanTemplatesTableFilterComposer get templateId {
    final $$PlanTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.planTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.planTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateTasksTable> {
  $$TemplateTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost,
      builder: (column) => ColumnOrderings(column));

  $$PlanTemplatesTableOrderingComposer get templateId {
    final $$PlanTemplatesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.planTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanTemplatesTableOrderingComposer(
              $db: $db,
              $table: $db.planTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateTasksTable> {
  $$TemplateTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => column);

  $$PlanTemplatesTableAnnotationComposer get templateId {
    final $$PlanTemplatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.planTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanTemplatesTableAnnotationComposer(
              $db: $db,
              $table: $db.planTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TemplateTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TemplateTasksTable,
    TemplateTask,
    $$TemplateTasksTableFilterComposer,
    $$TemplateTasksTableOrderingComposer,
    $$TemplateTasksTableAnnotationComposer,
    $$TemplateTasksTableCreateCompanionBuilder,
    $$TemplateTasksTableUpdateCompanionBuilder,
    (TemplateTask, $$TemplateTasksTableReferences),
    TemplateTask,
    PrefetchHooks Function({bool templateId})> {
  $$TemplateTasksTableTableManager(_$AppDatabase db, $TemplateTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> templateId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> startTime = const Value.absent(),
            Value<String> endTime = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> energyLevel = const Value.absent(),
            Value<double> estimatedCost = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplateTasksCompanion(
            id: id,
            templateId: templateId,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: type,
            priority: priority,
            energyLevel: energyLevel,
            estimatedCost: estimatedCost,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String templateId,
            required String title,
            Value<String> description = const Value.absent(),
            required String startTime,
            required String endTime,
            required String type,
            Value<String> priority = const Value.absent(),
            Value<String> energyLevel = const Value.absent(),
            Value<double> estimatedCost = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplateTasksCompanion.insert(
            id: id,
            templateId: templateId,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            type: type,
            priority: priority,
            energyLevel: energyLevel,
            estimatedCost: estimatedCost,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TemplateTasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (templateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.templateId,
                    referencedTable:
                        $$TemplateTasksTableReferences._templateIdTable(db),
                    referencedColumn:
                        $$TemplateTasksTableReferences._templateIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TemplateTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TemplateTasksTable,
    TemplateTask,
    $$TemplateTasksTableFilterComposer,
    $$TemplateTasksTableOrderingComposer,
    $$TemplateTasksTableAnnotationComposer,
    $$TemplateTasksTableCreateCompanionBuilder,
    $$TemplateTasksTableUpdateCompanionBuilder,
    (TemplateTask, $$TemplateTasksTableReferences),
    TemplateTask,
    PrefetchHooks Function({bool templateId})>;
typedef $$PreferencesTableCreateCompanionBuilder = PreferencesCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$PreferencesTableUpdateCompanionBuilder = PreferencesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PreferencesTable,
    Preference,
    $$PreferencesTableFilterComposer,
    $$PreferencesTableOrderingComposer,
    $$PreferencesTableAnnotationComposer,
    $$PreferencesTableCreateCompanionBuilder,
    $$PreferencesTableUpdateCompanionBuilder,
    (Preference, BaseReferences<_$AppDatabase, $PreferencesTable, Preference>),
    Preference,
    PrefetchHooks Function()> {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PreferencesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              PreferencesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PreferencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PreferencesTable,
    Preference,
    $$PreferencesTableFilterComposer,
    $$PreferencesTableOrderingComposer,
    $$PreferencesTableAnnotationComposer,
    $$PreferencesTableCreateCompanionBuilder,
    $$PreferencesTableUpdateCompanionBuilder,
    (Preference, BaseReferences<_$AppDatabase, $PreferencesTable, Preference>),
    Preference,
    PrefetchHooks Function()>;
typedef $$TodoItemsTableCreateCompanionBuilder = TodoItemsCompanion Function({
  required String id,
  required String title,
  Value<String> description,
  Value<bool> completed,
  Value<DateTime> createdAt,
  Value<String> itemType,
  Value<int> durationMinutes,
  Value<String> checklistJson,
  Value<String> audioFilePath,
  Value<int> rowid,
});
typedef $$TodoItemsTableUpdateCompanionBuilder = TodoItemsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<bool> completed,
  Value<DateTime> createdAt,
  Value<String> itemType,
  Value<int> durationMinutes,
  Value<String> checklistJson,
  Value<String> audioFilePath,
  Value<int> rowid,
});

class $$TodoItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioFilePath => $composableBuilder(
      column: $table.audioFilePath, builder: (column) => ColumnFilters(column));
}

class $$TodoItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioFilePath => $composableBuilder(
      column: $table.audioFilePath,
      builder: (column) => ColumnOrderings(column));
}

class $$TodoItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get checklistJson => $composableBuilder(
      column: $table.checklistJson, builder: (column) => column);

  GeneratedColumn<String> get audioFilePath => $composableBuilder(
      column: $table.audioFilePath, builder: (column) => column);
}

class $$TodoItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodoItemsTable,
    TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
    TodoItem,
    PrefetchHooks Function()> {
  $$TodoItemsTableTableManager(_$AppDatabase db, $TodoItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> checklistJson = const Value.absent(),
            Value<String> audioFilePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoItemsCompanion(
            id: id,
            title: title,
            description: description,
            completed: completed,
            createdAt: createdAt,
            itemType: itemType,
            durationMinutes: durationMinutes,
            checklistJson: checklistJson,
            audioFilePath: audioFilePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> description = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> checklistJson = const Value.absent(),
            Value<String> audioFilePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoItemsCompanion.insert(
            id: id,
            title: title,
            description: description,
            completed: completed,
            createdAt: createdAt,
            itemType: itemType,
            durationMinutes: durationMinutes,
            checklistJson: checklistJson,
            audioFilePath: audioFilePath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodoItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodoItemsTable,
    TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
    TodoItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DayPlansTableTableManager get dayPlans =>
      $$DayPlansTableTableManager(_db, _db.dayPlans);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$PlanTemplatesTableTableManager get planTemplates =>
      $$PlanTemplatesTableTableManager(_db, _db.planTemplates);
  $$TemplateTasksTableTableManager get templateTasks =>
      $$TemplateTasksTableTableManager(_db, _db.templateTasks);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
}
