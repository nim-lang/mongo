#!strongSpaces

import bson_binding as binding
import times
import oids
import strutils

export binding.BsonTyp
export binding.BinSubtype
export binding.len
export binding.`[]`
export binding.Timestamp
export binding.error_t

type
    Bson* = object {.byRef.}
        handle*: ptr binding.bson_t
    BsonError* = object of Exception
    Value* = object
        handle*: ptr binding.value_t
    Iter* = object
        handle*: binding.iter_t

# TODO: merge these converters when
# https://github.com/Araq/Nimrod/issues/1525 has been fixed
converter toHandle(o: var Value): ptr binding.value_t =
    result = o.handle

converter toHandle(o: var Iter): ptr binding.iter_t =
    result = o.handle.addr

converter toHandle(o: var Bson): ptr binding.bson_t =
    result = o.handle

converter toAddr(o: var binding.iter_t): ptr binding.iter_t =
    result = o.addr

proc typ*(o: Value): BsonTyp =
    result = o.handle[].value_type

proc typ*(o: var Iter): BsonTyp =
    result = iter_type(o)

proc getBool*(o: Value): bool =
    assert o.typ == btBool
    result = o.handle.value.v_bool

proc getFloat64*(o: Value): float64 =
    assert o.typ == btDouble
    result = o.handle.value.v_double

proc getStr*(o: Value): string =
    assert o.typ == btUtf8
    setLen(result, o.handle.value.v_utf8.len.int)
    for i in 0 .. <result.len:
        result[i] = o.handle.value.v_utf8.str[i]

#proc getDocument*(o: Value): bool =
#    assert o.typ == btDocument
#    result = o.handle.value.v_bool

proc getOid*(o: Value): oids.Oid =
    assert o.typ == btOid
    result = o.handle.value.v_oid

proc getInt32*(o: Value): int32 =
    assert o.typ == btInt32
    result = o.handle.value.v_int32

proc getInt64*(o: Value): int64 =
    assert o.typ == btInt64
    result = o.handle.value.v_int64

proc getDatetime*(o: Value): int64 =
    assert o.typ == btDatetime
    result = o.handle.value.v_datetime

proc getTimestamp*(o: Value): Timestamp =
    assert o.typ == btTimestamp
    result = o.handle.value.v_timestamp

proc getRegex*(o: Value): Regex =
    assert o.typ == btRegex
    result = o.handle.value.v_regex

proc getDbPointer*(o: Value): DbPointer =
    assert o.typ == btDbPointer
    result = o.handle.value.v_dbPointer

proc getCode*(o: Value): string =
    assert o.typ == btCode
    setLen(result, o.handle.value.v_code.code_len.int)
    for i in 0 .. <result.len:
        result[i] = o.handle.value.v_code.code[i]

proc getSymbol*(o: Value): string =
    assert o.typ == btSymbol
    setLen(result, o.handle.value.v_symbol.len.int)
    for i in 0 .. <result.len:
        result[i] = o.handle.value.v_symbol.symbol[i]

proc getCodewscope*(o: Value): tuple[code: string, scope: seq[uint8]] =
    assert o.typ == btCodewscope
    setLen(result.code, o.handle.value.v_codewscope.code_len.int)
    for i in 0 .. <result.code.len:
        result.code[i] = o.handle.value.v_codewscope.code[i]

    setLen(result.scope, o.handle.value.v_codewscope.scope_len.int)
    for i in 0 .. <result.scope.len:
        result.scope[i] = o.handle.value.v_codewscope.scope_data[i]

proc fail(msg: string = nil) =
    raise newException(BsonError, msg)

proc `$`*(o: binding.error_t): string =
  result = "$#.$#: " % [$o.domain, $o.code]
  for i in 0 .. o.message.high:
    if o.message[i] == '\0':
      break

    result.add o.message[i]

proc fail*(o: binding.error_t) =
    fail $o

proc oomCheck(o: ptr, msg: string = nil): o.type =
    if o == nil:
        fail msg

    result = o

proc boolCheck(b: bool, msg: string) =
    if not b:
        fail msg

proc overflowCheck(b: bool, msg: string = "append would overflow max BSON size") =
    boolCheck(b, msg)

proc nilCheck(o: ptr, msg: string = "received nil value"): o.type =
    if o == nil:
        fail msg

    result = o

proc nilCheck(o: cstring, msg: string = "received nil value"): cstring =
    if o == nil:
        fail msg

    result = o

proc destroy(o: var Bson) = # {.destructor.} =
    binding.destroy o

proc initBson*: Bson =
    result.handle = create(binding.bson_t)
    binding.init result.handle

proc newBson*: ref Bson =
    new result
    result.handle = create(binding.bson_t)
    binding.init result.handle

proc newBsonFromJson*(json: string): ref Bson =
    new result
    var err: binding.error_t
    var json = json
    result.handle = binding.new_from_json(
        cast[ptr uint8](json[0].addr), json.len.ssize_t, err.addr)

    if result.handle == nil:
        fail err

proc newBson(arr: ptr uint8, len: csize): ref Bson =
    new result
    result.handle = binding.new_from_data(cast[ptr uint8](arr), len)

when false:
    proc appendArr*(o: var Bson, key: string, arr: seq[bson_t]) =
        var key = key
        var arr = arr
        overflowCheck binding.append_array(o, key[0].addr, key.len.cint,
            cast[ptr bson_t](arr[0].addr))

when false:
    proc appendArr*(o: var Bson, key: string, arr: seq[Value]) =
        var child = initBson()
        boolCheck binding.append_array_begin(o, key, key.len.cint, child),
            "unable to append array"
        for i, x in arr:
            var xvar = x
            boolCheck binding.append_value(child, $i, ($i).len.cint, xvar),
                "unable to append value"
        boolCheck binding.append_array_end(o, nil),
            "unable to append array"

# TODO: Safer abstractions for generating aggregates.

proc appendArr*(o: var Bson, key: string, value: var Bson) =
    boolCheck binding.append_array(o, key, key.len.cint, value),
        "unable to append array"

proc appendArrBegin*(o: var Bson, key: string, child: var Bson) =
    boolCheck binding.append_array_begin(o, key, key.len.cint, child),
        "unable to append array start"

proc appendArrEnd*(o, child: var Bson) =
    overflowCheck binding.append_array_end(o, child)

proc appendDoc*(o: var Bson, key: string, value: var Bson) =
    boolCheck binding.append_document(o, key, key.len.cint, value),
        "unable to append document"

proc appendDocBegin*(o: var Bson, key: string, child: var Bson) =
    boolCheck binding.append_document_begin(o, key, key.len.cint, child),
        "unable to append document start"

proc appendDocEnd*(o, child: var Bson) =
    boolCheck binding.append_document_end(o, child),
        "unable to append document end"

template appendImpl(f: expr) {.dirty.} =
    overflowCheck binding.`f`(o, key, key.len.cint)

template appendImpl(f: expr, v) {.dirty.} =
    overflowCheck binding.`f`(o, key, key.len.cint, v)

template appendImpl(f: expr, v1, v2) {.dirty.} =
    overflowCheck binding.`f`(o, key, key.len.cint, v1, v2)

template appendImpl(f, v1, v2, v3: expr) {.dirty.} =
    overflowCheck binding.`f`(o, key, key.len.cint, v1, v2, v3)

proc appendBin*(o: var Bson, key: string, subType: BinSubtype, bin: seq[uint8]) =
    var bin = bin
    #o.appendHelper key, append_binary, subType, bin[0].addr, bin.len.uint32
    appendImpl append_binary, subType, bin[0].addr, bin.len.uint32

proc append*(o: var Bson, key: string, i: int32) =
    appendImpl append_int32, i

proc append*(o: var Bson, key: string, i: int64) =
    appendImpl append_int64, i

proc append*(o: var Bson, key: string, b: bool) =
    appendImpl append_bool, b

proc append*(o: var Bson, key: string, d: float64) =
    appendImpl append_double, d

proc append*(o: var Bson, key: string, oid: Oid) =
    var oid = oid
    appendImpl append_oid, oid.addr

proc appendCode*(o: var Bson, key, js: string) =
    appendImpl append_code, js

proc appendCodewscope*(o: var Bson, key, js: string, scope: Bson) =
    var scope = scope
    appendImpl append_code_with_scope, js, scope

proc appendSymbol*(o: var Bson, key, val: string) =
    appendImpl append_symbol, val, val.len.cint

proc append*(o: var Bson, key: string, t: Time) =
    appendImpl append_date_time, t.toSeconds.int64

proc appendNowUtc*(o: var Bson, key: string) =
    appendImpl append_now_utc

proc append*(o: var Bson, key: string, v: Value) =
    var v = v
    appendImpl append_value, v

proc appendDbPointer*(o: var Bson, key, coll: string, oid: Oid) {.deprecated.} =
    var oid = oid
    appendImpl append_dbpointer, coll, oid.addr

proc appendMaxKey*(o: var Bson, key: string) =
    appendImpl append_maxkey

proc appendMinKey*(o: var Bson, key: string) =
    appendImpl append_minkey

proc appendRegex*(o: var Bson, key, regex, opts: string) =
    appendImpl append_regex, regex, opts

proc appendNull*(o: var Bson, key: string) =
    appendImpl append_null

proc cmp*(a, b: Bson): int =
    var a = a
    var b = b
    result = binding.compare(a, b)

proc `==`*(a, b: Bson): bool =
    var a = a
    var b = b
    result = binding.equal(a, b)

proc `$`*(o: Bson): string =
    var
        o = o
        len: csize
        s = nilCheck binding.as_json(o, len.addr)
    result = $s
    binding.free(s)

proc find*(o: var Bson, key: string, value: var Value): bool =
    var iter: binding.iter_t
    boolCheck binding.iter_init(iter, o), "unable to initialize iterator"
    result = binding.iter_find(iter, key)
    if result:
        value.handle = binding.iter_value(iter)

proc has*(o: var Bson, key: string): bool =
  var value: Value
  result = find(o, key, value)

#iterator items*(o: var Value):
#        tuple[key: string, val: Value, iter: Iter] =
#    var handle = o.handle.addr
#    var iter: binding.iter_t
#    #binding.iter_recurse(

proc getArray*(i: var Iter): ref Bson =
    assert i.typ == btArray
    var
        len: uint32
        arr: ptr ptr uint8
    iter_array(i, len.addr, arr)
    if arr == nil:
        fail "unable to get array from iterator"
    result = newBson(arr[], len.csize)

proc `&`*(a, b: var Bson) =
    boolCheck binding.concat(a, b), "unable to concatenate BSON documents"

iterator items*(o: var Iter): Value =
    var iter: binding.iter_t
    boolCheck binding.iter_recurse(o, iter), "unable to initialize iterator"
    while binding.iter_next(iter):
        yield Value(handle: binding.iter_value(iter))

iterator pairs*(o: var Iter): tuple[key: string, val: Value] =
    var iter: binding.iter_t
    boolCheck binding.iter_recurse(o, iter), "unable to initialize iterator"
    while binding.iter_next(iter):
        yield (
            $nilCheck(binding.iter_key(iter)),
            Value(handle: binding.iter_value(iter))
        )

iterator items*(o: var Bson): Value =
    var handle = o.handle
    var iter: binding.iter_t
    boolCheck binding.iter_init(iter, handle), "unable to initialize iterator"
    while binding.iter_next(iter):
        yield Value(handle: binding.iter_value(iter))

iterator withSubDocIter*(o: var Bson):
        tuple[key: string, val: Value, iter: Iter] =
    var handle = o.handle
    var iter: binding.iter_t
    boolCheck binding.iter_init(iter, handle), "unable to initialize iterator"
    while binding.iter_next(iter):
        yield (
            $nilCheck(binding.iter_key(iter)),
            Value(handle: binding.iter_value(iter)),
            Iter()
        )

iterator pairs*(o: var Bson): tuple[key: string, val: Value] =
    var handle = o.handle
    var iter: binding.iter_t
    boolCheck binding.iter_init(iter, handle), "unable to initialize iterator"
    while binding.iter_next(iter):
        yield (
            $nilCheck(binding.iter_key(iter)),
            Value(handle: binding.iter_value(iter))
        )

when isMainModule:
    import sequtils

    proc main() =
        var b = newBson()
        var asJsonLen = 0
        var val: Value

        # 1

        assert $b[] == "{ }"
        asJsonLen = ($b[]).len

        assert toSeq(b[].items).len == 0
        assert toSeq(b[].pairs).len == 0
        assert toSeq(b[].withSubDocIter).len == 0
        assert bson.find(b[], "ohai", val) == false

        # 2

        b[].appendBin("binVal", bsBin, @[1'u8, 2, 3, 4])
        assert ($b[]).len > asJsonLen
        asJsonLen = ($b[]).len

        for x in b[]:
            assert x.typ == btBinary

        for k, v in b[]:
            assert k == "binVal"
            assert v.typ == btBinary

        assert toSeq(b[].items).len == 1
        assert toSeq(b[].pairs).len == 1
        assert toSeq(b[].withSubDocIter).len == 1
        assert(bson.find(b[], "binVal", val))
        assert bson.find(b[], "ohai", val) == false

        # 3
        var arrChild = newBson()
        b[].appendArrBegin "arr", arrChild[]
        arrChild[].append "0", 1i32
        arrChild[].append "1", 2i64
        b[].appendArrEnd(arrChild[])

        assert ($b[]).len > asJsonLen
        asJsonLen = ($b[]).len

        assert toSeq(b[].items).len == 2
        assert toSeq(b[].pairs).len == 2
        assert toSeq(b[].withSubDocIter).len == 2
        assert bson.find(b[], "binVal", val)
        assert bson.find(b[], "arr", val)
        assert bson.find(b[], "ohai", val) == false

    main()
