#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012-2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a higher level wrapper for `mongodb`:idx:. Example:
##
## .. code-block:: nimrod
##
##    import mongo, db_mongo, oids, json
##
##    var conn = db_mongo.open()
##
##    # construct JSON data:
##    var data = %{"a": %13, "b": %"my string value", 
##                 "inner": %{"i": %71} }
##
##    var id = insertID(conn, "test.test", data)
##
##    for v in find(conn, "test.test", "this.a == 13"):
##      print v
##
##    delete(conn, "test.test", id)
##    close(conn)

import mongo, oids, json

type
  EDb* = object of EIO ## exception that is raised if a database error occurs
  TDbConn* = TMongo    ## a database connection; alias for ``TMongo``

  FDb* = object of FIO ## effect that denotes a database operation
  FReadDb* = object of FDB   ## effect that denotes a read operation
  FWriteDb* = object of FDB  ## effect that denotes a write operation

type
  TBsonKind* = enum
    bkObj
    bkInt32
    bkInt64
    bkStr
  PBsonCtorNode* = ref object
    case kind: TBsonKind
    of bkObj:
      fields: seq[tuple[k: string, v: PBsonCtorNode]]
    of bkInt32:
      int32Val: int32
    of bkInt64:
      int64Val: int64
    of bkStr:
      strVal: string
  PBsonNode* = ref object
    case kind*: TBsonKind
    of bkObj:
      nil
    of bkInt32:
      int32Val*: int32
    of bkInt64:
      int64Val*: int64
    of bkStr:
      strVal*: string
  TMongoBson = mongo.TBson
  TBson = object
    handle: TMongoBson
    iter: ptr TIter
  PBson* = ref TBson

proc newBsonNode(iter: var TIter, kind: mongo.TBsonKind): PBsonNode =
  case kind:
  of mongo.bkOBJECT:
    return PBsonNode(kind: bkObj)
  of mongo.bkINT:
    return PBsonNode(kind: bkInt32, int32Val: iter.intVal)
  of mongo.bkLONG:
    return PBsonNode(kind: bkInt64, int64Val: iter.int64Val)
  of mongo.bkSTRING:
    return PBsonNode(kind: bkStr, strVal: $iter.strVal)
  else:
    assert false # TODO: Cover every case.

iterator subItems*(bson: PBson): tuple[k: string, v: PBsonNode] =
  var
    subIter: TIter
  assert bson.iter != nil
  assert bson.iter[].kind in {mongo.bkOBJECT}
  mongo.subiterator(bson.iter[], subIter)
  while (let kind = subIter.next(); kind != bkEOO):
    let
      key = $subIter.key
    yield (key, newBsonNode(subIter, kind))

iterator items*(bson: var PBson): tuple[k: string, v: PBsonNode] {.inline.} =
  try:
    var
      iter = initIter(bson.handle)
    while (let kind = iter.next(); kind != bkEOO):
      let
        key = $iter.key
      case kind:
      of mongo.bkOBJECT:
        bson.iter[] = iter
        yield (key, PBsonNode(kind: bkObj))
      else:
        yield (key, newBsonNode(iter, kind))
  finally:
    dealloc(bson.iter)
    bson.iter = nil

proc add(bson: var PBson, k: string, v: PBsonCtorNode) =
  case v.kind:
  of bkObj:
    mongo.addStartObject(bson.handle, k)
    for x in v.fields:
      bson.add(x.k, x.v)
    mongo.addFinishObject(bson.handle)
  of bkInt32:
    bson.handle.add(k, v.int32Val)
    discard
  of bkInt64:
    bson.handle.add(k, v.int64Val)
  of bkStr:
    bson.handle.add(k, v.strVal)
  else:
    assert false # TODO: Cover every case.

proc newBson*(
      doc: openarray[tuple[k: string, v: PBsonCtorNode]]): PBson =
  new(result, proc(o: ref TBson) {.nimcall.} = assert o.iter == nil)
  mongo.init(result.handle)
  result.iter = cast[ptr TIter](alloc(TIter.sizeof))
  for x in doc:
    result.add(x.k, x.v)
  mongo.finish(result.handle)

proc `%`*(str: string): PBsonCtorNode =
  PBsonCtorNode(kind: bkStr, strVal: str)

proc `%`*(i: int32): PBsonCtorNode =
  PBsonCtorNode(kind: bkInt32, int32Val: i)

proc `%`*(i: int64): PBsonCtorNode =
  PBsonCtorNode(kind: bkInt64, int64Val: i)

proc `%`*(fields: openarray[tuple[k: string, v: PBsonCtorNode]]): PBsonCtorNode =
  var
    fieldSeq = newSeq[fields[0].type](fields.len)
  for i, x in fields:
    fieldSeq[i] = x
  PBsonCtorNode(kind: bkObj, fields: fieldSeq)

proc dbError*(db: TDbConn, msg: string) {.noreturn.} = 
  ## raises an EDb exception with message `msg`.
  var e: ref EDb
  new(e)
  if db.errstr[0] != '\0':
    e.msg = $db.errstr
  else:
    e.msg = $db.err & " " & msg
  raise e

proc close*(db: var TDbConn) {.tags: [FDB].} = 
  ## closes the database connection.
  disconnect(db)
  destroy(db)

proc open*(host: string = defaultHost, port: int = defaultPort): TDbConn {.
  tags: [FDB].} =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established.
  init(result)
  
  let x = client(result, host, port.cint)
  if x != 0'i32:
    dbError(result, "cannot open: " & host)

proc jsonToBson(b: var mongo.TBson, key: string, j: PJsonNode) =
  case j.kind
  of JString:
    add(b, key, j.str)
  of JInt:
    add(b, key, j.num)
  of JFloat:
    add(b, key, j.fnum)
  of JBool:
    addBool(b, key, ord(j.bval))
  of JNull:
    addNull(b, key)
  of JObject:
    addStartObject(b, key)
    for k, v in items(j.fields):
      jsonToBson(b, k, v)
    addFinishObject(b)
  of JArray:
    addStartArray(b, key)
    for i, e in pairs(j.elems):
      jsonToBson(b, $i, e)
    addFinishArray(b)

proc jsonToBson*(b: var mongo.TBson, j: PJsonNode, oid: TOid) =
  ## converts a JSON value into the BSON format. The result must be
  ## ``destroyed`` explicitely!
  init(b)
  assert j.kind == JObject
  add(b, "_id", oid)
  for key, val in items(j.fields):
    jsonToBson(b, key, val)
  finish(b)

proc jsonToBson*(b: var mongo.TBson, j: PJsonNode) =
  ## converts a JSON value into the BSON format. The result must be
  ## ``destroyed`` explicitely!
  init(b)
  assert j.kind == JObject
  for key, val in items(j.fields):
    jsonToBson(b, key, val)
  finish(b)

proc `[]`*(obj: var mongo.TBson, fieldname: cstring): mongo.TBson =
  ## retrieves the value belonging to `fieldname`. Raises `EInvalidKey` if
  ## the attribute does not exist.
  var it = initIter(obj)
  let res = find(it, result, fieldname)
  if res == bkEOO:
    raise newException(EInvalidIndex, "key not in object")

proc getId*(obj: var mongo.TBson): TOid =
  ## retrieves the ``_id`` attribute of `obj`.
  var it = initIter(obj)
  var b: mongo.TBson
  let res = find(it, b, "_id")
  if res == bkOID:
    result = oidVal(it)[]
  else:
    raise newException(EInvalidIndex, "_id not in object")

proc insertId*(db: var TDbConn, namespace: string, data: PJsonNode): TOid {.
  tags: [FWriteDb].} =
  ## converts `data` to BSON format and inserts it in `namespace`. Returns
  ## the generated OID for the ``_id`` field.
  result = genOid()
  var x: mongo.TBson
  jsonToBson(x, data, result)
  insert(db, namespace, x, nil)
  destroy(x)

proc insert*(db: var TDbConn, namespace: string, data: PJsonNode) {.
  tags: [FWriteDb].} =
  ## converts `data` to BSON format and inserts it in `namespace`.  
  discard InsertID(db, namespace, data)

proc update*(db: var TDbConn, namespace: string, obj: var mongo.TBson) {.
  tags: [FReadDB, FWriteDb].} =
  ## updates `obj` in `namespace`.
  var cond: mongo.TBson
  init(cond)
  cond.add("_id", getId(obj))
  finish(cond)
  update(db, namespace, cond, obj, ord(UPDATE_UPSERT))
  destroy(cond)

proc update*(db: var TDbConn, namespace: string, oid: TOid, obj: PJsonNode) {.
  tags: [FReadDB, FWriteDb].} =
  ## updates the data with `oid` to have the new data `obj`.
  var a: mongo.TBson
  jsonToBson(a, obj, oid)
  Update(db, namespace, a)
  destroy(a)

proc delete*(db: var TDbConn, namespace: string, oid: TOid) {.
  tags: [FWriteDb].} =
  ## Deletes the object belonging to `oid`.
  var cond: mongo.TBson
  init(cond)
  cond.add("_id", oid)
  finish(cond)
  discard remove(db, namespace, cond)
  destroy(cond)

proc delete*(db: var TDbConn, namespace: string, obj: var mongo.TBson) {.
  tags: [FWriteDb].} =
  ## Deletes the object `obj`.
  delete(db, namespace, getId(obj))

iterator find*(db: var TDbConn, namespace: string): var mongo.TBson {.
  tags: [FReadDB].} =
  ## iterates over any object in `namespace`.
  var cursor: TCursor
  init(cursor, db, namespace)
  while next(cursor) == mongo.OK:
    yield bson(cursor)[]
  destroy(cursor)

iterator find*(db: var TDbConn, namespace: string, 
               query, fields: var mongo.TBson): var mongo.TBson {.tags: [FReadDB].} =
  ## yields the `fields` of any document that suffices `query`.
  var cursor = find(db, namespace, query, fields, 0'i32, 0'i32, 0'i32)
  if cursor != nil:
    while next(cursor[]) == mongo.OK:
      yield bson(cursor[])[]
    destroy(cursor[])

proc setupFieldnames(fields: varargs[string]): mongo.TBson =
  init(result)
  for x in fields: add(result, x, 1'i32)
  finish(result)

iterator find*(db: var TDbConn, namespace: string, 
               query: var mongo.TBson, fields: varargs[string]): var mongo.TBson {.
               tags: [FReadDB].} =
  ## yields the `fields` of any document that suffices `query`. If `fields` 
  ## is ``[]`` the whole document is yielded.
  var f = setupFieldnames(fields)
  var cursor = find(db, namespace, query, f, 0'i32, 0'i32, 0'i32)
  if cursor != nil:
    while next(cursor[]) == mongo.OK:
      yield bson(cursor[])[]
    destroy(cursor[])
  destroy(f)

proc setupQuery(query: string): mongo.TBson =
  init(result)
  add(result, "$where", query)
  finish(result)

iterator find*(db: var TDbConn, namespace: string, 
               query: string, fields: varargs[string]): var mongo.TBson {.
               tags: [FReadDB].} =
  ## yields the `fields` of any document that suffices `query`. If `fields` 
  ## is ``[]`` the whole document is yielded.
  var f = setupFieldnames(fields)
  var q = setupQuery(query)
  var cursor = find(db, namespace, q, f, 0'i32, 0'i32, 0'i32)
  if cursor != nil:
    while next(cursor[]) == mongo.OK:
      yield bson(cursor[])[]
    destroy(cursor[])
  destroy(q)
  destroy(f)

when false:
  # this doesn't work this way; would require low level hacking
  iterator fieldPairs*(obj: var mongo.TBson): tuple[key: cstring, value: mongo.TBson] =
    ## iterates over `obj` and yields all (key, value)-Pairs.
    var it = initIter(obj)
    var v: mongo.TBson
    while next(it) != bkEOO:
      let key = key(it)
      discard init(v, value(it))
      yield (key, v)
