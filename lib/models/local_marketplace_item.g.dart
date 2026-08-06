// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_marketplace_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalMarketplaceItemCollection on Isar {
  IsarCollection<LocalMarketplaceItem> get localMarketplaceItems =>
      this.collection();
}

const LocalMarketplaceItemSchema = CollectionSchema(
  name: r'LocalMarketplaceItem',
  id: 7657160219699882697,
  properties: {
    r'broadcasted': PropertySchema(
      id: 0,
      name: r'broadcasted',
      type: IsarType.bool,
    ),
    r'broadcastedAt': PropertySchema(
      id: 1,
      name: r'broadcastedAt',
      type: IsarType.dateTime,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'condition': PropertySchema(
      id: 3,
      name: r'condition',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'favorites': PropertySchema(
      id: 6,
      name: r'favorites',
      type: IsarType.long,
    ),
    r'firestoreId': PropertySchema(
      id: 7,
      name: r'firestoreId',
      type: IsarType.string,
    ),
    r'image': PropertySchema(
      id: 8,
      name: r'image',
      type: IsarType.string,
    ),
    r'images': PropertySchema(
      id: 9,
      name: r'images',
      type: IsarType.stringList,
    ),
    r'isSold': PropertySchema(
      id: 10,
      name: r'isSold',
      type: IsarType.bool,
    ),
    r'location': PropertySchema(
      id: 11,
      name: r'location',
      type: IsarType.string,
    ),
    r'mobileNumber': PropertySchema(
      id: 12,
      name: r'mobileNumber',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 13,
      name: r'price',
      type: IsarType.double,
    ),
    r'priceUnit': PropertySchema(
      id: 14,
      name: r'priceUnit',
      type: IsarType.string,
    ),
    r'sellerAvatar': PropertySchema(
      id: 15,
      name: r'sellerAvatar',
      type: IsarType.string,
    ),
    r'sellerId': PropertySchema(
      id: 16,
      name: r'sellerId',
      type: IsarType.string,
    ),
    r'sellerName': PropertySchema(
      id: 17,
      name: r'sellerName',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
    ),
    r'statusUpdatedAt': PropertySchema(
      id: 19,
      name: r'statusUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'timeAgo': PropertySchema(
      id: 20,
      name: r'timeAgo',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 21,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _localMarketplaceItemEstimateSize,
  serialize: _localMarketplaceItemSerialize,
  deserialize: _localMarketplaceItemDeserialize,
  deserializeProp: _localMarketplaceItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'firestoreId': IndexSchema(
      id: 1863077355534729001,
      name: r'firestoreId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'firestoreId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localMarketplaceItemGetId,
  getLinks: _localMarketplaceItemGetLinks,
  attach: _localMarketplaceItemAttach,
  version: '3.1.0+1',
);

int _localMarketplaceItemEstimateSize(
  LocalMarketplaceItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.condition.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.firestoreId.length * 3;
  bytesCount += 3 + object.image.length * 3;
  bytesCount += 3 + object.images.length * 3;
  {
    for (var i = 0; i < object.images.length; i++) {
      final value = object.images[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.location.length * 3;
  bytesCount += 3 + object.mobileNumber.length * 3;
  bytesCount += 3 + object.priceUnit.length * 3;
  {
    final value = object.sellerAvatar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sellerId.length * 3;
  bytesCount += 3 + object.sellerName.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.timeAgo.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _localMarketplaceItemSerialize(
  LocalMarketplaceItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.broadcasted);
  writer.writeDateTime(offsets[1], object.broadcastedAt);
  writer.writeString(offsets[2], object.category);
  writer.writeString(offsets[3], object.condition);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.description);
  writer.writeLong(offsets[6], object.favorites);
  writer.writeString(offsets[7], object.firestoreId);
  writer.writeString(offsets[8], object.image);
  writer.writeStringList(offsets[9], object.images);
  writer.writeBool(offsets[10], object.isSold);
  writer.writeString(offsets[11], object.location);
  writer.writeString(offsets[12], object.mobileNumber);
  writer.writeDouble(offsets[13], object.price);
  writer.writeString(offsets[14], object.priceUnit);
  writer.writeString(offsets[15], object.sellerAvatar);
  writer.writeString(offsets[16], object.sellerId);
  writer.writeString(offsets[17], object.sellerName);
  writer.writeString(offsets[18], object.status);
  writer.writeDateTime(offsets[19], object.statusUpdatedAt);
  writer.writeString(offsets[20], object.timeAgo);
  writer.writeString(offsets[21], object.title);
}

LocalMarketplaceItem _localMarketplaceItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalMarketplaceItem();
  object.broadcasted = reader.readBool(offsets[0]);
  object.broadcastedAt = reader.readDateTimeOrNull(offsets[1]);
  object.category = reader.readString(offsets[2]);
  object.condition = reader.readString(offsets[3]);
  object.createdAt = reader.readDateTime(offsets[4]);
  object.description = reader.readString(offsets[5]);
  object.favorites = reader.readLong(offsets[6]);
  object.firestoreId = reader.readString(offsets[7]);
  object.id = id;
  object.image = reader.readString(offsets[8]);
  object.images = reader.readStringList(offsets[9]) ?? [];
  object.isSold = reader.readBool(offsets[10]);
  object.location = reader.readString(offsets[11]);
  object.mobileNumber = reader.readString(offsets[12]);
  object.price = reader.readDouble(offsets[13]);
  object.priceUnit = reader.readString(offsets[14]);
  object.sellerAvatar = reader.readStringOrNull(offsets[15]);
  object.sellerId = reader.readString(offsets[16]);
  object.sellerName = reader.readString(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.statusUpdatedAt = reader.readDateTimeOrNull(offsets[19]);
  object.timeAgo = reader.readString(offsets[20]);
  object.title = reader.readString(offsets[21]);
  return object;
}

P _localMarketplaceItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localMarketplaceItemGetId(LocalMarketplaceItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localMarketplaceItemGetLinks(
    LocalMarketplaceItem object) {
  return [];
}

void _localMarketplaceItemAttach(
    IsarCollection<dynamic> col, Id id, LocalMarketplaceItem object) {
  object.id = id;
}

extension LocalMarketplaceItemByIndex on IsarCollection<LocalMarketplaceItem> {
  Future<LocalMarketplaceItem?> getByFirestoreId(String firestoreId) {
    return getByIndex(r'firestoreId', [firestoreId]);
  }

  LocalMarketplaceItem? getByFirestoreIdSync(String firestoreId) {
    return getByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<bool> deleteByFirestoreId(String firestoreId) {
    return deleteByIndex(r'firestoreId', [firestoreId]);
  }

  bool deleteByFirestoreIdSync(String firestoreId) {
    return deleteByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<List<LocalMarketplaceItem?>> getAllByFirestoreId(
      List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firestoreId', values);
  }

  List<LocalMarketplaceItem?> getAllByFirestoreIdSync(
      List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'firestoreId', values);
  }

  Future<int> deleteAllByFirestoreId(List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'firestoreId', values);
  }

  int deleteAllByFirestoreIdSync(List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'firestoreId', values);
  }

  Future<Id> putByFirestoreId(LocalMarketplaceItem object) {
    return putByIndex(r'firestoreId', object);
  }

  Id putByFirestoreIdSync(LocalMarketplaceItem object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'firestoreId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirestoreId(List<LocalMarketplaceItem> objects) {
    return putAllByIndex(r'firestoreId', objects);
  }

  List<Id> putAllByFirestoreIdSync(List<LocalMarketplaceItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'firestoreId', objects, saveLinks: saveLinks);
  }
}

extension LocalMarketplaceItemQueryWhereSort
    on QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QWhere> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalMarketplaceItemQueryWhere
    on QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QWhereClause> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
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

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      firestoreIdEqualTo(String firestoreId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firestoreId',
        value: [firestoreId],
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterWhereClause>
      firestoreIdNotEqualTo(String firestoreId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [],
              upper: [firestoreId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [firestoreId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [firestoreId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [],
              upper: [firestoreId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalMarketplaceItemQueryFilter on QueryBuilder<LocalMarketplaceItem,
    LocalMarketplaceItem, QFilterCondition> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'broadcasted',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'broadcastedAt',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'broadcastedAt',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'broadcastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'broadcastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'broadcastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> broadcastedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'broadcastedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'condition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      conditionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      conditionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'condition',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'condition',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> conditionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'condition',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> favoritesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favorites',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> favoritesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favorites',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> favoritesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favorites',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> favoritesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favorites',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firestoreId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      firestoreIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      firestoreIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firestoreId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> firestoreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'image',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      imageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      imageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'image',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'images',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      imagesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      imagesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'images',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> imagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> isSoldEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSold',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'location',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      locationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'location',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobileNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      mobileNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobileNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      mobileNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobileNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> mobileNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobileNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceUnit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      priceUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priceUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      priceUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priceUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> priceUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priceUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sellerAvatar',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sellerAvatar',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellerAvatar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerAvatarContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sellerAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerAvatarMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sellerAvatar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerAvatarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sellerAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sellerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sellerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sellerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sellerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      sellerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sellerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellerName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> sellerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sellerName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'statusUpdatedAt',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'statusUpdatedAt',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> statusUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeAgo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      timeAgoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      timeAgoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeAgo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeAgo',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> timeAgoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeAgo',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension LocalMarketplaceItemQueryObject on QueryBuilder<LocalMarketplaceItem,
    LocalMarketplaceItem, QFilterCondition> {}

extension LocalMarketplaceItemQueryLinks on QueryBuilder<LocalMarketplaceItem,
    LocalMarketplaceItem, QFilterCondition> {}

extension LocalMarketplaceItemQuerySortBy
    on QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QSortBy> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByBroadcasted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcasted', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByBroadcastedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcasted', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByBroadcastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcastedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByBroadcastedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcastedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByCondition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'condition', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByConditionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'condition', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByFavorites() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favorites', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByFavoritesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favorites', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByIsSoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByMobileNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByMobileNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByPriceUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUnit', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByPriceUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUnit', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerAvatar', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerAvatar', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortBySellerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByStatusUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByTimeAgo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByTimeAgoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension LocalMarketplaceItemQuerySortThenBy
    on QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QSortThenBy> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByBroadcasted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcasted', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByBroadcastedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcasted', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByBroadcastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcastedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByBroadcastedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'broadcastedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByCondition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'condition', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByConditionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'condition', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByFavorites() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favorites', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByFavoritesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favorites', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByIsSoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSold', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByMobileNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByMobileNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileNumber', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByPriceUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUnit', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByPriceUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceUnit', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerAvatar', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerAvatar', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerId', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenBySellerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellerName', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByStatusUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByTimeAgo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByTimeAgoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.desc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension LocalMarketplaceItemQueryWhereDistinct
    on QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct> {
  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByBroadcasted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'broadcasted');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByBroadcastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'broadcastedAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByCondition({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'condition', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByFavorites() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favorites');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByFirestoreId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firestoreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByImage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'images');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByIsSold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSold');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByMobileNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobileNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByPriceUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceUnit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctBySellerAvatar({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellerAvatar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctBySellerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctBySellerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByStatusUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusUpdatedAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByTimeAgo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeAgo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalMarketplaceItem, LocalMarketplaceItem, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension LocalMarketplaceItemQueryProperty on QueryBuilder<
    LocalMarketplaceItem, LocalMarketplaceItem, QQueryProperty> {
  QueryBuilder<LocalMarketplaceItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalMarketplaceItem, bool, QQueryOperations>
      broadcastedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'broadcasted');
    });
  }

  QueryBuilder<LocalMarketplaceItem, DateTime?, QQueryOperations>
      broadcastedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'broadcastedAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      conditionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'condition');
    });
  }

  QueryBuilder<LocalMarketplaceItem, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<LocalMarketplaceItem, int, QQueryOperations>
      favoritesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favorites');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      firestoreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firestoreId');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations> imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<LocalMarketplaceItem, List<String>, QQueryOperations>
      imagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'images');
    });
  }

  QueryBuilder<LocalMarketplaceItem, bool, QQueryOperations> isSoldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSold');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      mobileNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobileNumber');
    });
  }

  QueryBuilder<LocalMarketplaceItem, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      priceUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceUnit');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String?, QQueryOperations>
      sellerAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellerAvatar');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      sellerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellerId');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      sellerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellerName');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LocalMarketplaceItem, DateTime?, QQueryOperations>
      statusUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusUpdatedAt');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations>
      timeAgoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeAgo');
    });
  }

  QueryBuilder<LocalMarketplaceItem, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
