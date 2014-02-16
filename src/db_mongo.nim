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

import mongo, oids
export mongo.TCursorOpts

type
  EDb* = object of EIO ## exception that is raised if a database error occurs
  TDbConn = object
    handle: mongo.TMongo
    hasClosed: bool
  PDbConn* = ref TDbConn

  FDb* = object of FIO ## effect that denotes a database operation
  FReadDb* = object of FDB   ## effect that denotes a read operation
  FWriteDb* = object of FDB  ## effect that denotes a write operation

type
  TBsonKind* = enum
    bkNone
    bkObj
    bkArr
    bkInt32
    bkInt64
    bkStr
    bkOid
  TBsonBasicTypes* = int32|int64|string|TOid
  PBsonCtorNode* = ref object
    case kind: TBsonKind
    of bkNone:
      nil
    of bkObj:
      fieldsVal: seq[tuple[k: string, v: PBsonCtorNode]]
    of bkArr:
      arrVal: seq[PBsonCtorNode]
    of bkInt32:
      int32Val: int32
    of bkInt64:
      int64Val: int64
    of bkStr:
      strVal: string
    of bkOid:
      oidVal: TOid
  PBsonNode* = ref object
    case kind*: TBsonKind
    of bkNone:
      nil
    of bkObj, bkArr:
      bson: ref TBson
      iter: mongo.TIter
    of bkInt32:
      int32Val*: int32
    of bkInt64:
      int64Val*: int64
    of bkStr:
      strVal*: string
    of bkOid:
      oidVal*: TOid
  TBson = object
    handle: ptr mongo.TBson
    iter: ptr TIter
  PBson* = ref TBson

proc newBsonNode(iter: var TIter, kind: mongo.TBsonKind, bson: PBson):
      PBsonNode =
  result = case kind:
  of mongo.bkOBJECT:
    PBsonNode(kind: bkObj, bson: bson, iter: iter)
  of mongo.bkARRAY:
    PBsonNode(kind: bkArr, bson: bson, iter: iter)
  of mongo.bkINT:
    PBsonNode(kind: bkInt32, int32Val: iter.intVal)
  of mongo.bkLONG:
    PBsonNode(kind: bkInt64, int64Val: iter.int64Val)
  of mongo.bkSTRING:
    PBsonNode(kind: bkStr, strVal: $iter.strVal)
  of mongo.bkOID:
    PBsonNode(kind: bkOid, oidVal: iter.oidVal[])
  else:
    assert false # TODO: Cover every case.
    PBsonNode(kind: bkObj)

proc add(bson: var PBson, k: string, v: PBsonCtorNode) =
  case v.kind:
  of bkNone:
    discard
  of bkObj:
    mongo.addStartObject(bson.handle[], k)
    for x in v.fieldsVal:
      bson.add(x.k, x.v)
    mongo.addFinishObject(bson.handle[])
  of bkArr:
    mongo.addStartArray(bson.handle[], k)
    for i, x in v.arrVal:
      bson.add($i, x)
    mongo.addFinishArray(bson.handle[])
  of bkInt32: # TODO: Condense the following cases.
    add(bson.handle[], k, v.int32Val)
  of bkInt64:
    add(bson.handle[], k, v.int64Val)
  of bkStr:
    add(bson.handle[], k, v.strVal)
  of bkOid:
    add(bson.handle[], k, v.oidVal)

proc newBson*(handle: ptr mongo.TBson): PBson =
  PBson(handle: handle, iter: nil)

proc newBson*(
      doc: openarray[tuple[k: string, v: PBsonCtorNode]] = []): PBson =
  new(result, proc(o: PBson) {.nimcall.} =
    assert o.iter == nil

    # XXX: Possible double-free for some reason.
    when false: mongo.destroy(o.handle[])
  )

  result.handle = cast[ptr mongo.TBson](alloc(mongo.TBson.sizeof))
  mongo.init(result.handle[])
  for x in doc:
    result.add(x.k, x.v)
  mongo.finish(result.handle[])

proc `%%`*(
      doc: openarray[tuple[k: string, v: PBsonCtorNode]] = []): PBson =
  newBson(doc)

proc setIter*(o: PBson, iter: var TIter) =
  if o.iter == nil:
    o.iter = cast[ptr TIter](alloc(TIter.sizeof))

  o.iter[] = iter

proc unsetIter*(o: PBson) =
  if o.iter != nil:
    dealloc(o.iter)
    o.iter = nil

proc print*(o: PBson) =
  mongo.print o.handle[]

iterator subItems*(bson: PBson): tuple[k: string, v: PBsonNode] =
  var
    subIter: TIter
  assert bson.iter != nil
  assert bson.iter[].kind in {mongo.bkOBJECT, mongo.bkARRAY}
  mongo.subiterator(bson.iter[], subIter)
  while (let kind = subIter.next(); kind != bkEOO):
    let
      key = $subIter.key
    yield (key, newBsonNode(subIter, kind, bson = nil))

proc `[]`*(node: PBsonNode, k: string): PBsonNode =
  assert node.kind in {bkArr, bkObj}
  case node.kind:
    of bkArr, bkObj:
      var
        subIter: TIter
      mongo.subiterator(node.iter, subIter)
      while (let kind = subIter.next(); kind != bkEOO):
        if k == $subIter.key:
          return newBsonNode(subIter, kind, node.bson)

      return PBsonNode(kind: bkNone)
    else:
      assert false

proc `[]`*(bson: PBson, k: string): PBsonNode =
  var
    iter = initIter(bson.handle[])
  let
    kind = mongo.find(iter, bson.handle[], k)
  if kind == mongo.bkEOO:
    PBsonNode(kind: bkNone)
  else:
    newBsonNode(iter, kind, bson)

iterator items*(bson: PBson): tuple[k: string, v: PBsonNode] =
  var
    iter = mongo.initIter(bson.handle[])
  while (let kind = mongo.next(iter); kind != mongo.bkEOO):
    let
      key = $iter.key
    case kind:
    of mongo.bkOBJECT, mongo.bkARRAY:
      bson.setIter(iter)
      yield (key, newBsonNode(iter, kind, bson))
    else:
      yield (key, newBsonNode(iter, kind, bson = nil))

  bson.unsetIter()

# TODO: Condense these procs; add type/enum map template.

proc `%`*(str: string): PBsonCtorNode =
  PBsonCtorNode(kind: bkStr, strVal: str)

proc `%`*(i: int32): PBsonCtorNode =
  PBsonCtorNode(kind: bkInt32, int32Val: i)

proc `%`*(i: int64): PBsonCtorNode =
  PBsonCtorNode(kind: bkInt64, int64Val: i)

proc `%`*(oid: TOid): PBsonCtorNode =
  PBsonCtorNode(kind: bkOid, oidVal: oid)

proc `%`*(fields: openarray[tuple[k: string, v: PBsonCtorNode]]): PBsonCtorNode =
  var
    fieldSeq = newSeq[fields[0].type](fields.len)
  for i, x in fields:
    fieldSeq[i] = x
  PBsonCtorNode(kind: bkObj, fieldsVal: fieldSeq)

proc `%`*(arr: openarray[PBsonCtorNode]): PBsonCtorNode =
  var
    arrSeq = newSeq[arr[0].type](arr.len)
  for i, x in arr:
    arrSeq[i] = x
  PBsonCtorNode(kind: bkArr, arrVal: arrSeq)

proc `%`*(arr: openarray[TBsonBasicTypes]): PBsonCtorNode =
  `%`(map(arr, proc(x: arr[0].type): PBsonCtorNode = %x))

proc dbError*(db: PDbConn, msg: string) {.noreturn.} =
  ## raises an EDb exception with message `msg`.
  raise newException(EDb, if db.handle.errstr[0] != '\0':
      $db.handle.errstr
    else:
      $db.handle.err & " " & msg)

proc close*(db: PDbConn) {.tags: [FDB].} =
  ## closes the database connection.
  if not db.hasClosed:
    mongo.disconnect(db.handle)
    mongo.destroy(db.handle)

  db.hasClosed = true

proc open*(host: string = defaultHost, port: int = defaultPort): PDbConn {.
  tags: [FDB].} =
  ## opens a database connection. Raises `EDb` if the connection could not
  ## be established.
  new(result, proc(o: PDbConn) {.nimcall.} =
    o.close()
  )
  mongo.init(result.handle)
  result.hasClosed = false
  
  let x = mongo.client(result.handle, host, port.cint)
  if x != 0i32:
    dbError(result, "cannot open: " & host)

proc insert*(db: PDbConn, namespace: string, data: PBson) {.
  tags: [FWriteDb].} =
  ## insert `data` in `namespace`.
  mongo.insert(db.handle, namespace, data.handle[], nil)

iterator find*(
      db: PDbConn,
      namespace: string,
      query, fields: PBson = newBson(),
      limit, skip = 0.Natural,
      cursorOpts: set[TCursorOpts] = {coTailable}): # Work around ICE.
        PBson {.tags: [FReadDB].} =
  ## yields the `fields` of any document in `namespace` that suffices `query`.
  ## `limit` specifies the maximum amount of documents to yield.
  ## `skip` specifies how many documents should be skipped.
  ## `cursorOpts` specifies cursor options.
  var
    opts: int32
  for x in cursorOpts:
    opts = opts or x.int32
  var
    cursor = mongo.find(db.handle, namespace, query.handle[],
      fields.handle[], limit.int32, skip.int32, opts)
  if cursor != nil:
    while mongo.next(cursor[]) == mongo.OK:
      yield newBson(mongo.bson(cursor[]))
    mongo.destroy(cursor[])

proc setupQuery(query: string): mongo.TBson =
  mongo.init(result)
  mongo.add(result, "$where", query)
  mongo.finish(result)

iterator find*(db: PDbConn, namespace: string, query: string,
               fields: PBson): PBson {.tags: [FReadDB].} =
  ## yields the `fields` of any document that suffices `query`. If `fields` 
  ## is ``[]`` the whole document is yielded.
  var q = setupQuery(query)
  var cursor = mongo.find(db.handle, namespace, q, fields.handle[], 0i32,
                          0i32, 0i32)
  if cursor != nil:
    while mongo.next(cursor[]) == mongo.OK:
      var b = newBson(mongo.bson(cursor[]))
      yield b
    mongo.destroy(cursor[])
  mongo.destroy(q)
