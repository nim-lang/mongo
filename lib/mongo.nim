#!strongSpaces

import mongo_binding as binding
import bson_binding
import bson

export binding.QueryFlags

type
    Client* = object
        handle: binding.client_t
    Coll* = object
        handle: binding.collection_t
    WriteConcern* = object
        handle: binding.write_concern_t
    EMongoError* = object of Exception
    QueryFlags* = enum
      qfNone
      qfTailableCursor
      qfSlaveOk
      qfOplogReplay
      qfNoCursorTimeout
      qfAwaitData
      qfExhaust
      qfPartial
    UpdateFlags* = enum
      ufNone
      ufUpsert
      ufMultiUpdate
    RemoveFlags* = enum
      rfNone
      rfSingleRemove

# TODO: reduce repetition.

converter toRemoveFlags(o: set[RemoveFlags]): binding.RemoveFlags =
  template add(o: binding.RemoveFlags) =
    ret = ret or o.cint

  var ret: cint
  for x in o:
    add (case x
      of rfNone:
        binding.rfNone
      of rfSingleRemove:
        binding.rfSingleRemove
    )

  result = type(result)(ret)

converter toUpdateFlags(o: set[UpdateFlags]): binding.UpdateFlags =
  template add(o: binding.UpdateFlags) =
    ret = ret or o.cint

  var ret: cint
  for x in o:
    add (case x
      of ufNone:
        binding.ufNone
      of ufUpsert:
        binding.ufUpsert
      of ufMultiUpdate:
        binding.ufMultiUpdate
    )

  result = type(result)(ret)

converter toQueryFlags(o: set[QueryFlags]): binding.QueryFlags =
  template add(o: binding.QueryFlags) =
    ret = ret or o.cint

  var ret: cint
  # TODO: different approach?
  for x in o:
    add (case x
    of qfNone:
      binding.qfNone
    of qfTailableCursor:
      binding.qfTailableCursor
    of qfSlaveOk:
      binding.qfSlaveOk
    of qfOplogReplay:
      binding.qfOplogReplay
    of qfNoCursorTimeout:
      binding.qfNoCursorTimeout
    of qfAwaitData:
      binding.qfAwaitData
    of qfExhaust:
      binding.qfExhaust
    of qfPartial:
      binding.qfPartial
    )

  result = type(result)(ret)

proc destroy*(o: var WriteConcern) = # {.destructor.}
    binding.write_concern_destroy o.handle

# TODO: merge these converters when
# https://github.com/Araq/Nimrod/issues/1525 (???) has been fixed
converter toHandle(o: WriteConcern): binding.write_concern_t =
    result = o.handle

converter toHandle(o: Client): binding.client_t =
    result = o.handle

converter toHandle(o: Coll): binding.collection_t =
    result = o.handle

converter toHandle(o: var Bson): ptr bson_binding.bson_t =
    result = o.handle

proc fail(msg: string) =
    raise newException(EMongoError, msg)

# XXX: ambiguous call; both system.type(x: expr) and system.type(x: expr) match for: (client_t)
#proc nilCheck(o: ptr|pointer, msg: string): o.type =

proc nilCheck(o: ptr|pointer, msg: string): type(o) =
    result = o
    if o == nil:
        fail msg

proc initWriteConcern*(
            journal, fsync = true,
            w = 0.int32,
            wTimeout, wMajority = 1000.int32,
            wTag = nil.string): WriteConcern =
    var wTag = wTag
    var handle = create result.handle.type
    binding.write_concern_set_journal handle, journal
    binding.write_concern_set_fsync handle, fsync
    binding.write_concern_set_w handle, w
    binding.write_concern_set_wtimeout handle, wTimeout
    binding.write_concern_set_wmajority handle, wMajority
    if wTag != nil:
        binding.write_concern_set_wtag handle, wTag[0].addr

proc nilWriteConcern*(): WriteConcern =
    discard

proc initClient*(uri: string): Client =
    result.handle = nilCheck(binding.client_new uri, "invalid client URI: " & uri)

proc getColl*(o: Client, db, coll: string): Coll =
    result.handle = nilCheck(binding.client_get_collection(o, db, coll),
        "unable to get collection")

proc count*(o: Coll, query = initBson(), skip, limit = 0i64,
        flags = {qfNone}): int64 =
  var query = query
  var err: bson.error_t
  # TODO: read prefs
  result = binding.collection_count(o, flags, query, skip, limit, nil, addr err)
  if result < 0:
    bson.fail err

iterator find*(
            o: Coll,
            query = newBson(),
            fields: ref Bson = nil,
            flags = {qfNone},
            skip, limit = 0u32,
            batchSize = 100u32, # readPrefs: binding.read_prefs_t
            ): ref Bson =
    var query = query
    var fields = fields

    # TODO: read prefs
    # TODO: destroy cursor
    var cursor = binding.collection_find(o, flags, skip, limit, batchSize,
      query.handle, if fields.isNil: nil else: fields.handle, nil)

    var doc = newBson()
    while binding.cursor_more(cursor) and binding.cursor_next(cursor, doc.handle.addr):
        yield doc

    var err: bson.error_t
    if binding.cursor_error(cursor, addr err):
      bson.fail err

proc updateMulti*(o: Coll, update: Bson, selector = initBson(), flags = {ufNone},
        writeConcern = nilWriteConcern()) =
  var err: bson.error_t
  var update = update
  var selector = selector
  if not binding.collection_update(o, flags, selector, update, writeConcern, addr err):
    bson.fail err

proc update*(o: Coll, update: Bson, selector = initBson(), flags = {ufNone},
        writeConcern = nilWriteConcern()) =
  var err: bson.error_t
  var update = update
  var selector = selector
  if not binding.collection_update(o, flags, selector, update, writeConcern, addr err):
    bson.fail err

# TODO: flag set?
proc insert*(o: Coll, doc: Bson, flags: InsertFlags = ifNone) =
    var doc = doc
    var err: bson.error_t
    if not binding.collection_insert(o, flags, doc, nil, addr err):
        bson.fail err

proc remove*(o: Coll, selector = initBson(), flags: set[RemoveFlags] = {rfNone},
            writeConcern = nilWriteConcern()) =
    var b = selector
    var err: bson.error_t
    if not binding.collection_remove(o, flags, b, writeConcern, addr err):
        bson.fail err

proc drop*(o: Coll) =
    var err: bson.error_t
    if not binding.collection_drop(o, addr err):
      bson.fail err

proc stats*(o: Coll): ref Bson =
    var err: bson.error_t
    # TODO: options
    result = newBson()
    if not binding.collection_stats(o, nil, result.handle, addr err):
      bson.fail err

when isMainModule: # TODO: Better structure.
    import sequtils, util
    proc unittest() =
        binding.init()
        var client = initClient "mongodb://127.0.0.1"
        var coll = client.getColl("test", "nim_mongo_test")
        var count = 0
        coll.remove()
        assert toSeq(coll.find).len == 0
        assert coll.count == 0
        var b = initBson()
        b.append "int32", 1i32
        coll.insert b
        assert toSeq(coll.find).len == 1
        assert coll.count == 1
        coll.insert b
        assert toSeq(coll.find).len == 2
        assert coll.count == 2
        coll.remove(flags = {rfSingleRemove})
        assert coll.count == 1
        coll.remove(flags = {rfSingleRemove})
        assert coll.count == 0
        coll.insert b
        assert toSeq(coll.find).len == 1
        assert coll.count == 1
        coll.insert b
        coll.insert b
        coll.insert b
        assert toSeq(coll.find).len == 4
        assert coll.count == 4
        b = initBson()
        b.append "int64", 2i64
        coll.update(b)
        for x in coll.find: # XXX: toSeq(coll.find) causes a segfault in find below
            var value: bson.Value
            if x[].find("int64", value):
                inc count

        assert count == 1
        count = 0

        assertRaised BsonError, coll.update(b, flags = {ufMultiUpdate})
        var child = initBson()
        child.append "int64", 2i64
        b = initBson()
        b.appendDoc("$set", child)
        coll.update(b, flags = {ufMultiUpdate})
        for x in coll.find: # XXX: toSeq(coll.find) causes a segfault in find below
            var value: bson.Value
            #echo x[]
            if x[].find("int64", value):
                inc count

        assert count == 4
        count = 0

        coll.remove()
        assert toSeq(coll.find).len == 0
        assert coll.count == 0
        #for x in coll.find:
        #    echo x[]
        when false: # TODO: Validate.
          echo coll.stats[]

    unittest()
