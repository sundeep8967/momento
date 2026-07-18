// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDayLogCollection on Isar {
  IsarCollection<IsarDayLog> get isarDayLogs => this.collection();
}

const IsarDayLogSchema = CollectionSchema(
  name: r'IsarDayLog',
  id: 818865659035741746,
  properties: {
    r'clipCount': PropertySchema(
      id: 0,
      name: r'clipCount',
      type: IsarType.long,
    ),
    r'closedAt': PropertySchema(
      id: 1,
      name: r'closedAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.string,
    ),
    r'isClosed': PropertySchema(
      id: 3,
      name: r'isClosed',
      type: IsarType.bool,
    ),
    r'logId': PropertySchema(
      id: 4,
      name: r'logId',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 5,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarDayLogEstimateSize,
  serialize: _isarDayLogSerialize,
  deserialize: _isarDayLogDeserialize,
  deserializeProp: _isarDayLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'logId': IndexSchema(
      id: 3089637606214822530,
      name: r'logId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'logId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarDayLogGetId,
  getLinks: _isarDayLogGetLinks,
  attach: _isarDayLogAttach,
  version: '3.1.0+1',
);

int _isarDayLogEstimateSize(
  IsarDayLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.logId.length * 3;
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarDayLogSerialize(
  IsarDayLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.clipCount);
  writer.writeDateTime(offsets[1], object.closedAt);
  writer.writeString(offsets[2], object.date);
  writer.writeBool(offsets[3], object.isClosed);
  writer.writeString(offsets[4], object.logId);
  writer.writeString(offsets[5], object.thumbnailUrl);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

IsarDayLog _isarDayLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDayLog();
  object.clipCount = reader.readLong(offsets[0]);
  object.closedAt = reader.readDateTimeOrNull(offsets[1]);
  object.date = reader.readString(offsets[2]);
  object.id = id;
  object.isClosed = reader.readBool(offsets[3]);
  object.logId = reader.readString(offsets[4]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _isarDayLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDayLogGetId(IsarDayLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDayLogGetLinks(IsarDayLog object) {
  return [];
}

void _isarDayLogAttach(IsarCollection<dynamic> col, Id id, IsarDayLog object) {
  object.id = id;
}

extension IsarDayLogByIndex on IsarCollection<IsarDayLog> {
  Future<IsarDayLog?> getByLogId(String logId) {
    return getByIndex(r'logId', [logId]);
  }

  IsarDayLog? getByLogIdSync(String logId) {
    return getByIndexSync(r'logId', [logId]);
  }

  Future<bool> deleteByLogId(String logId) {
    return deleteByIndex(r'logId', [logId]);
  }

  bool deleteByLogIdSync(String logId) {
    return deleteByIndexSync(r'logId', [logId]);
  }

  Future<List<IsarDayLog?>> getAllByLogId(List<String> logIdValues) {
    final values = logIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'logId', values);
  }

  List<IsarDayLog?> getAllByLogIdSync(List<String> logIdValues) {
    final values = logIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'logId', values);
  }

  Future<int> deleteAllByLogId(List<String> logIdValues) {
    final values = logIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'logId', values);
  }

  int deleteAllByLogIdSync(List<String> logIdValues) {
    final values = logIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'logId', values);
  }

  Future<Id> putByLogId(IsarDayLog object) {
    return putByIndex(r'logId', object);
  }

  Id putByLogIdSync(IsarDayLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'logId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLogId(List<IsarDayLog> objects) {
    return putAllByIndex(r'logId', objects);
  }

  List<Id> putAllByLogIdSync(List<IsarDayLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'logId', objects, saveLinks: saveLinks);
  }
}

extension IsarDayLogQueryWhereSort
    on QueryBuilder<IsarDayLog, IsarDayLog, QWhere> {
  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarDayLogQueryWhere
    on QueryBuilder<IsarDayLog, IsarDayLog, QWhereClause> {
  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> logIdEqualTo(
      String logId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'logId',
        value: [logId],
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterWhereClause> logIdNotEqualTo(
      String logId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'logId',
              lower: [],
              upper: [logId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'logId',
              lower: [logId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'logId',
              lower: [logId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'logId',
              lower: [],
              upper: [logId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarDayLogQueryFilter
    on QueryBuilder<IsarDayLog, IsarDayLog, QFilterCondition> {
  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> clipCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clipCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      clipCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clipCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> clipCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clipCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> clipCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clipCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> closedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      closedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> closedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      closedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> closedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> closedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> isClosedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isClosed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> logIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      logIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarDayLogQueryObject
    on QueryBuilder<IsarDayLog, IsarDayLog, QFilterCondition> {}

extension IsarDayLogQueryLinks
    on QueryBuilder<IsarDayLog, IsarDayLog, QFilterCondition> {}

extension IsarDayLogQuerySortBy
    on QueryBuilder<IsarDayLog, IsarDayLog, QSortBy> {
  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByClipCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipCount', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByClipCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipCount', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByIsClosed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClosed', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByIsClosedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClosed', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByLogId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logId', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByLogIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logId', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarDayLogQuerySortThenBy
    on QueryBuilder<IsarDayLog, IsarDayLog, QSortThenBy> {
  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByClipCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipCount', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByClipCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipCount', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByIsClosed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClosed', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByIsClosedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isClosed', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByLogId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logId', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByLogIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logId', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarDayLogQueryWhereDistinct
    on QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> {
  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByClipCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clipCount');
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedAt');
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByIsClosed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isClosed');
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByLogId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByThumbnailUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDayLog, IsarDayLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarDayLogQueryProperty
    on QueryBuilder<IsarDayLog, IsarDayLog, QQueryProperty> {
  QueryBuilder<IsarDayLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDayLog, int, QQueryOperations> clipCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clipCount');
    });
  }

  QueryBuilder<IsarDayLog, DateTime?, QQueryOperations> closedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedAt');
    });
  }

  QueryBuilder<IsarDayLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<IsarDayLog, bool, QQueryOperations> isClosedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isClosed');
    });
  }

  QueryBuilder<IsarDayLog, String, QQueryOperations> logIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logId');
    });
  }

  QueryBuilder<IsarDayLog, String?, QQueryOperations> thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<IsarDayLog, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSharedLogCollection on Isar {
  IsarCollection<IsarSharedLog> get isarSharedLogs => this.collection();
}

const IsarSharedLogSchema = CollectionSchema(
  name: r'IsarSharedLog',
  id: -8003783616561881012,
  properties: {
    r'clipsJson': PropertySchema(
      id: 0,
      name: r'clipsJson',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.string,
    ),
    r'expiresAt': PropertySchema(
      id: 2,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'isViewedByMe': PropertySchema(
      id: 3,
      name: r'isViewedByMe',
      type: IsarType.bool,
    ),
    r'ownerUid': PropertySchema(
      id: 4,
      name: r'ownerUid',
      type: IsarType.string,
    ),
    r'ownerUsername': PropertySchema(
      id: 5,
      name: r'ownerUsername',
      type: IsarType.string,
    ),
    r'reactionsJson': PropertySchema(
      id: 6,
      name: r'reactionsJson',
      type: IsarType.string,
    ),
    r'shareId': PropertySchema(
      id: 7,
      name: r'shareId',
      type: IsarType.string,
    ),
    r'viewersJson': PropertySchema(
      id: 8,
      name: r'viewersJson',
      type: IsarType.string,
    )
  },
  estimateSize: _isarSharedLogEstimateSize,
  serialize: _isarSharedLogSerialize,
  deserialize: _isarSharedLogDeserialize,
  deserializeProp: _isarSharedLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'shareId': IndexSchema(
      id: 3531953376692712996,
      name: r'shareId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'shareId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarSharedLogGetId,
  getLinks: _isarSharedLogGetLinks,
  attach: _isarSharedLogAttach,
  version: '3.1.0+1',
);

int _isarSharedLogEstimateSize(
  IsarSharedLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clipsJson.length * 3;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.ownerUid.length * 3;
  bytesCount += 3 + object.ownerUsername.length * 3;
  bytesCount += 3 + object.reactionsJson.length * 3;
  bytesCount += 3 + object.shareId.length * 3;
  bytesCount += 3 + object.viewersJson.length * 3;
  return bytesCount;
}

void _isarSharedLogSerialize(
  IsarSharedLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.clipsJson);
  writer.writeString(offsets[1], object.date);
  writer.writeDateTime(offsets[2], object.expiresAt);
  writer.writeBool(offsets[3], object.isViewedByMe);
  writer.writeString(offsets[4], object.ownerUid);
  writer.writeString(offsets[5], object.ownerUsername);
  writer.writeString(offsets[6], object.reactionsJson);
  writer.writeString(offsets[7], object.shareId);
  writer.writeString(offsets[8], object.viewersJson);
}

IsarSharedLog _isarSharedLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSharedLog();
  object.clipsJson = reader.readString(offsets[0]);
  object.date = reader.readString(offsets[1]);
  object.expiresAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isViewedByMe = reader.readBool(offsets[3]);
  object.ownerUid = reader.readString(offsets[4]);
  object.ownerUsername = reader.readString(offsets[5]);
  object.reactionsJson = reader.readString(offsets[6]);
  object.shareId = reader.readString(offsets[7]);
  object.viewersJson = reader.readString(offsets[8]);
  return object;
}

P _isarSharedLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSharedLogGetId(IsarSharedLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSharedLogGetLinks(IsarSharedLog object) {
  return [];
}

void _isarSharedLogAttach(
    IsarCollection<dynamic> col, Id id, IsarSharedLog object) {
  object.id = id;
}

extension IsarSharedLogByIndex on IsarCollection<IsarSharedLog> {
  Future<IsarSharedLog?> getByShareId(String shareId) {
    return getByIndex(r'shareId', [shareId]);
  }

  IsarSharedLog? getByShareIdSync(String shareId) {
    return getByIndexSync(r'shareId', [shareId]);
  }

  Future<bool> deleteByShareId(String shareId) {
    return deleteByIndex(r'shareId', [shareId]);
  }

  bool deleteByShareIdSync(String shareId) {
    return deleteByIndexSync(r'shareId', [shareId]);
  }

  Future<List<IsarSharedLog?>> getAllByShareId(List<String> shareIdValues) {
    final values = shareIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'shareId', values);
  }

  List<IsarSharedLog?> getAllByShareIdSync(List<String> shareIdValues) {
    final values = shareIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'shareId', values);
  }

  Future<int> deleteAllByShareId(List<String> shareIdValues) {
    final values = shareIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'shareId', values);
  }

  int deleteAllByShareIdSync(List<String> shareIdValues) {
    final values = shareIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'shareId', values);
  }

  Future<Id> putByShareId(IsarSharedLog object) {
    return putByIndex(r'shareId', object);
  }

  Id putByShareIdSync(IsarSharedLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'shareId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByShareId(List<IsarSharedLog> objects) {
    return putAllByIndex(r'shareId', objects);
  }

  List<Id> putAllByShareIdSync(List<IsarSharedLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'shareId', objects, saveLinks: saveLinks);
  }
}

extension IsarSharedLogQueryWhereSort
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QWhere> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSharedLogQueryWhere
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QWhereClause> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause> shareIdEqualTo(
      String shareId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'shareId',
        value: [shareId],
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterWhereClause>
      shareIdNotEqualTo(String shareId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [],
              upper: [shareId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [shareId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [shareId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [],
              upper: [shareId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSharedLogQueryFilter
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QFilterCondition> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clipsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clipsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clipsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      clipsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clipsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      expiresAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      expiresAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      expiresAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      expiresAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      isViewedByMeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isViewedByMe',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      ownerUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reactionsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reactionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reactionsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reactionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      reactionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reactionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shareId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shareId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shareId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      shareIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shareId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'viewersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'viewersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'viewersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterFilterCondition>
      viewersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'viewersJson',
        value: '',
      ));
    });
  }
}

extension IsarSharedLogQueryObject
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QFilterCondition> {}

extension IsarSharedLogQueryLinks
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QFilterCondition> {}

extension IsarSharedLogQuerySortBy
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QSortBy> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByClipsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByClipsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByIsViewedByMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isViewedByMe', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByIsViewedByMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isViewedByMe', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByOwnerUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUsername', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByOwnerUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUsername', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByReactionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByReactionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByShareId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByShareIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> sortByViewersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      sortByViewersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewersJson', Sort.desc);
    });
  }
}

extension IsarSharedLogQuerySortThenBy
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QSortThenBy> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByClipsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByClipsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clipsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByIsViewedByMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isViewedByMe', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByIsViewedByMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isViewedByMe', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByOwnerUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByOwnerUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUid', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByOwnerUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUsername', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByOwnerUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUsername', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByReactionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByReactionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reactionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByShareId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByShareIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.desc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy> thenByViewersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewersJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QAfterSortBy>
      thenByViewersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewersJson', Sort.desc);
    });
  }
}

extension IsarSharedLogQueryWhereDistinct
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> {
  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByClipsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clipsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct>
      distinctByIsViewedByMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isViewedByMe');
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByOwnerUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByOwnerUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUsername',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByReactionsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reactionsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByShareId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shareId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSharedLog, IsarSharedLog, QDistinct> distinctByViewersJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewersJson', caseSensitive: caseSensitive);
    });
  }
}

extension IsarSharedLogQueryProperty
    on QueryBuilder<IsarSharedLog, IsarSharedLog, QQueryProperty> {
  QueryBuilder<IsarSharedLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations> clipsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clipsJson');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<IsarSharedLog, DateTime, QQueryOperations> expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<IsarSharedLog, bool, QQueryOperations> isViewedByMeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isViewedByMe');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations> ownerUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUid');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations>
      ownerUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUsername');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations>
      reactionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reactionsJson');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations> shareIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shareId');
    });
  }

  QueryBuilder<IsarSharedLog, String, QQueryOperations> viewersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewersJson');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarUserProfileCollection on Isar {
  IsarCollection<IsarUserProfile> get isarUserProfiles => this.collection();
}

const IsarUserProfileSchema = CollectionSchema(
  name: r'IsarUserProfile',
  id: 8546962976391985935,
  properties: {
    r'currentStreak': PropertySchema(
      id: 0,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'displayName': PropertySchema(
      id: 1,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'lastLogDate': PropertySchema(
      id: 2,
      name: r'lastLogDate',
      type: IsarType.string,
    ),
    r'longestStreak': PropertySchema(
      id: 3,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'photoUrl': PropertySchema(
      id: 4,
      name: r'photoUrl',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 5,
      name: r'uid',
      type: IsarType.string,
    ),
    r'username': PropertySchema(
      id: 6,
      name: r'username',
      type: IsarType.string,
    )
  },
  estimateSize: _isarUserProfileEstimateSize,
  serialize: _isarUserProfileSerialize,
  deserialize: _isarUserProfileDeserialize,
  deserializeProp: _isarUserProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarUserProfileGetId,
  getLinks: _isarUserProfileGetLinks,
  attach: _isarUserProfileAttach,
  version: '3.1.0+1',
);

int _isarUserProfileEstimateSize(
  IsarUserProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.displayName.length * 3;
  {
    final value = object.lastLogDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.photoUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uid.length * 3;
  bytesCount += 3 + object.username.length * 3;
  return bytesCount;
}

void _isarUserProfileSerialize(
  IsarUserProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentStreak);
  writer.writeString(offsets[1], object.displayName);
  writer.writeString(offsets[2], object.lastLogDate);
  writer.writeLong(offsets[3], object.longestStreak);
  writer.writeString(offsets[4], object.photoUrl);
  writer.writeString(offsets[5], object.uid);
  writer.writeString(offsets[6], object.username);
}

IsarUserProfile _isarUserProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarUserProfile();
  object.currentStreak = reader.readLong(offsets[0]);
  object.displayName = reader.readString(offsets[1]);
  object.id = id;
  object.lastLogDate = reader.readStringOrNull(offsets[2]);
  object.longestStreak = reader.readLong(offsets[3]);
  object.photoUrl = reader.readStringOrNull(offsets[4]);
  object.uid = reader.readString(offsets[5]);
  object.username = reader.readString(offsets[6]);
  return object;
}

P _isarUserProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarUserProfileGetId(IsarUserProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarUserProfileGetLinks(IsarUserProfile object) {
  return [];
}

void _isarUserProfileAttach(
    IsarCollection<dynamic> col, Id id, IsarUserProfile object) {
  object.id = id;
}

extension IsarUserProfileByIndex on IsarCollection<IsarUserProfile> {
  Future<IsarUserProfile?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  IsarUserProfile? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<IsarUserProfile?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<IsarUserProfile?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(IsarUserProfile object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(IsarUserProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<IsarUserProfile> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<IsarUserProfile> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension IsarUserProfileQueryWhereSort
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QWhere> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarUserProfileQueryWhere
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QWhereClause> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause> uidEqualTo(
      String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterWhereClause>
      uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarUserProfileQueryFilter
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QFilterCondition> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastLogDate',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastLogDate',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastLogDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastLogDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastLogDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastLogDate',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      lastLogDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastLogDate',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoUrl',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoUrl',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      photoUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }
}

extension IsarUserProfileQueryObject
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QFilterCondition> {}

extension IsarUserProfileQueryLinks
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QFilterCondition> {}

extension IsarUserProfileQuerySortBy
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QSortBy> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByLastLogDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByLastLogDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByPhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByPhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension IsarUserProfileQuerySortThenBy
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QSortThenBy> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByLastLogDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByLastLogDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByPhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByPhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoUrl', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QAfterSortBy>
      thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension IsarUserProfileQueryWhereDistinct
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct> {
  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct>
      distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct>
      distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct>
      distinctByLastLogDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastLogDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct>
      distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct> distinctByPhotoUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserProfile, IsarUserProfile, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension IsarUserProfileQueryProperty
    on QueryBuilder<IsarUserProfile, IsarUserProfile, QQueryProperty> {
  QueryBuilder<IsarUserProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarUserProfile, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<IsarUserProfile, String, QQueryOperations>
      displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<IsarUserProfile, String?, QQueryOperations>
      lastLogDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastLogDate');
    });
  }

  QueryBuilder<IsarUserProfile, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<IsarUserProfile, String?, QQueryOperations> photoUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoUrl');
    });
  }

  QueryBuilder<IsarUserProfile, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<IsarUserProfile, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}
