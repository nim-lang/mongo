import times

{.deadCodeElim: on.}

when defined(windows):
  const
    bsondll* = "bson-1.0.dll"
elif defined(macosx):
  const
    bsondll* = "libbson-1.0.dylib"
else:
  const
    bsondll* = "libbson-1.0.so"

type
  cssize* = int
  TUnichar* = uint32
  TContextFlags* {.size: sizeof(cint).} = enum
    cfNone = 0,
    cfThreadSafe = 1 shl 0
    cfDisableHostCache = 1 shl 1
    cfDisablePidCache = 1 shl 2
    cfUseTaskId = 1 shl 3 # For linux.
  TContext* = distinct pointer
  TBson* {.pure, final.} = object
    flags*: uint32
    len*: uint32
    padding*: array[120, uint8]
  TOid* {.pure, final.} = object
    bytes*: array[12, uint8]
  TValidateFlags* {.size: sizeof(cint).} = enum
    VALIDATE_NONE = 0
    VALIDATE_UTF8 = 1 shl 0
    VALIDATE_DOLLAR_KEYS = 1 shl 1
    VALIDATE_DOT_KEYS = 1 shl 2
    VALIDATE_UTF8_ALLOW_NULL = (1 shl 3)
  TBsonKind* {.size: sizeof(cint).} = enum
    bkEod = 0x00000000,
    bkDouble = 0x00000001,
    bkUtf8 = 0x00000002,
    bkDoc = 0x00000003,
    bkArr = 0x00000004,
    bkBin = 0x00000005,
    bkUndefined = 0x00000006,
    bkOid = 0x00000007,
    bkBool = 0x00000008,
    bkDateTime = 0x00000009,
    bkNull = 0x0000000A,
    bkJsRegex = 0x0000000B,
    bkDbPtr = 0x0000000C,
    bkCode = 0x0000000D,
    bkSym = 0x0000000E,
    bkCodewscope = 0x0000000F,
    bkInt32 = 0x00000010,
    bkTimeStamp = 0x00000011,
    bkInt64 = 0x00000012,
    bkMaxKey = 0x0000007F,
    bkMinKey = 0x000000FF
  TBinSubtype* {.size: sizeof(cint).} = enum
    bsBinary = 0x00000000,
    bsFunction = 0x00000001,
    bsBinaryDeprecated = 0x00000002,
    bsUuidDeprecated = 0x00000003,
    bsUuid = 0x00000004,
    bsMd5 = 0x00000005,
    bsUser = 0x00000080
  TTimestamp* = tuple[timestamp: uint32, increment: uint32]
  TUtf8* = tuple[len: uint32, str: cstring]
  TDoc* = tuple[data_len: uint32, data: ptr uint8]
  TBinary* = tuple[data_len: uint32, data: ptr uint8, subtype: TBinSubtype]
  TRegex* = tuple[regex: cstring, options: cstring]
  TDbPtr* = tuple[collection: cstring, collection_len: uint32, oid: TOid]
  TCode* = tuple[code_len: uint32, code: cstring]
  TCodewscope* = tuple[code_len: uint32, code: cstring,
    scope_len: uint32, scope_data: ptr uint8]
  TSymbol* = tuple[len: uint32, symbol: cstring]
  TValueUnion* {.union.} = object
    oid*: TOid
    int64Val*: int64
    int32Val*: int32
    float64Val*: float64
    boolVal*: bool
    datetime*: int64
    timestamp*: TTimestamp
    utf8*: TUtf8
    doc*: ptr TDoc
    bin*: TBinary
    regex*: TRegex
    dbPtr*: TDbPtr
    code*: TCode
    codewscope*: TCodewscope
    symbol*: TSymbol
  TBsonVal* {.pure, final.} = object
    case kind*: TBsonKind
    of bkEod, bkUndefined, bkNull:
      nil
    of bkDouble:
      float64Val*: float64
    of bkUtf8:
      utf8*: tuple[len: uint32, str: cstring]
    of bkDoc, bkArr:
      doc*: ptr TDoc
    of bkBin:
      bin*: tuple[len: uint32, data: ptr uint8, subtype: TBinSubtype]
    of bkOid:
      oid*: TOid
    of bkBool:
      boolVal*: bool
    of bkDateTime:
      dateTime*: int64
    of bkJsRegex:
      jsRegex*: tuple[pattern: cstring, opts: cstring]
    of bkDbPtr:
      dbPtr*: tuple[coll: cstring, len: uint32, oid: TOid]
    of bkCode:
      code*: tuple[len: uint32, code: cstring]
    of bkSym:
      sym*: tuple[len: uint32, sym: cstring]
    of bkCodewscope:
      codewscope*: tuple[len: uint32, code: cstring, scopeLen: uint32,
        scopeData: cstring]
    of bkInt32:
      int32Val*: int32
    of bkTimeStamp:
      timestamp*: tuple[timestamp, increment: uint32]
    of bkInt64:
      int64Val*: int64
    of bkMaxKey, bkMinKey:
      nil
    else:
      nil # Needed for some reason.
  TIter* {.pure, final.} = object
    raw: ptr uint8
    len: uint32
    off: uint32
    `type`: uint32
    key: uint32
    d1: uint32
    d2: uint32
    d3: uint32
    d4: uint32
    next_off: uint32
    err_off: uint32
    value: TBsonVal
  TReader* {.pure, final.} = object
    `type`: uint32
  TVisitor* {.pure, final.} = object
    visit_before*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    visit_after*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    visit_corrupt*: proc (iter: ptr TIter; data: pointer)
    visit_double*: proc (iter: ptr TIter; key: cstring;
                         v_double: cdouble; data: pointer): bool
    visit_utf8*: proc (iter: ptr TIter; key: cstring;
                       v_utf8_len: csize; v_utf8: cstring; data: pointer): bool
    visit_doc*: proc (iter: ptr TIter; key: cstring;
                           v_doc: ptr TBson; data: pointer): bool
    visit_arr*: proc (iter: ptr TIter; key: cstring;
                        v_arr: ptr TBson; data: pointer): bool
    visit_binary*: proc (iter: ptr TIter; key: cstring;
                         v_subtype: TBinSubtype; v_binary_len: csize;
                         v_binary: ptr uint8; data: pointer): bool
    visit_undefined*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    visit_oid*: proc (iter: ptr TIter; key: cstring;
                      v_oid: ptr TOid; data: pointer): bool
    visit_bool*: proc (iter: ptr TIter; key: cstring; v_bool: bool;
                       data: pointer): bool
    visit_date_time*: proc (iter: ptr TIter; key: cstring;
                            msec_since_epoch: int64; data: pointer): bool
    visit_null*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    visit_regex*: proc (iter: ptr TIter; key: cstring; v_regex: cstring;
                        v_options: cstring; data: pointer): bool
    visit_dbpointer*: proc (iter: ptr TIter; key: cstring;
                            v_collection_len: csize; v_collection: cstring;
                            v_oid: ptr TOid; data: pointer): bool
    visit_code*: proc (iter: ptr TIter; key: cstring;
                       v_code_len: csize; v_code: cstring; data: pointer): bool
    visit_symbol*: proc (iter: ptr TIter; key: cstring;
                         v_symbol_len: csize; v_symbol: cstring;
                         data: pointer): bool
    visit_codewscope*: proc (iter: ptr TIter; key: cstring;
                             v_code_len: csize; v_code: cstring;
                             v_scope: ptr TBson; data: pointer): bool
    visit_int32*: proc (iter: ptr TIter; key: cstring; v_int32: int32;
                        data: pointer): bool
    visit_timestamp*: proc (iter: ptr TIter; key: cstring;
                            v_timestamp: uint32; v_increment: uint32;
                            data: pointer): bool
    visit_int64*: proc (iter: ptr TIter; key: cstring; v_int64: int64;
                        data: pointer): bool
    visit_maxkey*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    visit_minkey*: proc (iter: ptr TIter; key: cstring; data: pointer): bool
    padding*: array[9, pointer]
  TError* {.pure, final.} = object
    domain*: uint32
    code*: uint32
    message*: array[504, char]
  realloc_func* = proc (mem: pointer; num_bytes: csize; ctx: pointer): pointer


proc init*: TBson =
  result.flags = 3
  result.len = 5
  result.padding[0] = 5
  result.padding[1] = 0
  result.padding[2] = 0
  result.padding[3] = 0
  result.padding[4] = 0

proc init*(o: var TBson) =
  o.flags = 3
  o.len = 5
  o.padding[0] = 5
  o.padding[1] = 0
  o.padding[2] = 0
  o.padding[3] = 0
  o.padding[4] = 0

const MAX_SIZE* = ((csize)((1 shl 31) + 1))

template xappend_array*(b, key, val: expr): expr =
  append_arr(b, key, key.len.cint, val)

template xappend_array_begin*(b, key, child: expr): expr =
  append_array_begin(b, key, key.len.cint, child)

template xappend_binary*(b, key, subtype, val, l: expr): expr =
  append_binary(b, key, key.len.cint, subtype, val, l)

template xappend_bool*(b, key, val: expr): expr =
  append_bool(b, key, key.len.cint, val)

template xappend_code*(b, key, val: expr): expr =
  append_code(b, key, key.len.cint, val)

template xappend_code_with_scope*(b, key, val, scope: expr): expr =
  append_code_with_scope(b, key, key.len.cint, val, scope)

template xappend_dbpointer*(b, key, coll, oid: expr): expr =
  append_dbpointer(b, key, key.len.cint, coll, oid)

template xappend_document_begin*(b, key, child: expr): expr =
  append_document_begin(b, key, key.len.cint, child)

template xappend_double*(b, key, val: expr): expr =
  append_double(b, key, key.len.cint, val)

template xappend_doc*(b, key, val: expr): expr =
  append_doc(b, key, key.len.cint, val)

template xappend_int32*(b, key, val: expr): expr =
  append_int32(b, key, key.len.cint, val)

template xappend_int64*(b, key, val: expr): expr =
  append_int64(b, key, key.len.cint, val)

template xappend_minkey*(b, key: expr): expr =
  append_minkey(b, key, key.len.cint)

template xappend_maxkey*(b, key: expr): expr =
  append_maxkey(b, key, key.len.cint)

template xappend_null*(b, key: expr): expr =
  append_null(b, key, key.len.cint)

template xappend_oid*(b, key, val: expr): expr =
  append_oid(b, key, key.len.cint, val)

template xappend_regex*(b, key, val, opt: expr): expr =
  append_regex(b, key, key.len.cint, val, opt)

template xappend_utf8*(b, key, val: expr): expr =
  append_utf8(b, key, key.len.cint, val, val.len.cint)

template xappend_symbol*(b, key, val: expr): expr =
  append_symbol(b, key, key.len.cint, val, val.len.cint)

template xappend_time_t*(b, key, val: expr): expr =
  append_time_t(b, key, key.len.cint, val)

#template xappend_timeval*(b, key, val: expr): expr =
#  append_timeval(b, key, key.len.cint, val)

template xappend_date_time*(b, key, val: expr): expr =
  append_date_time(b, key, key.len.cint, val)

template xappend_timestamp*(b, key, val, inc: expr): expr =
  append_timestamp(b, key, key.len.cint, val, inc)

template xappend_undefined*(b, key: expr): expr =
  append_undefined(b, key, key.len.cint)

template xappend_value*(b, key, val: expr): expr =
  append_value(b, key, key.len.cint, (val))

{.push cdecl, importc: "bson_$1", dynlib: bsondll.}

proc new*(): ptr TBson
proc new_from_json*(data: ptr uint8; len: csize; error: ptr TError): ptr TBson
proc init_from_json*(bson: ptr TBson; data: cstring; len: cssize;
                          error: ptr TError): bool

proc init_static*(b: var TBson; data: var uint8; length: uint32): bool

proc init*(b: ptr TBson)

proc reinit*(b: ptr TBson)

proc new_from_data*(data: ptr uint8; length: uint32): ptr TBson

proc new_from_buffer*(buf: ptr ptr uint8; buf_len: ptr csize;
                           realloc_func: realloc_func;
                           realloc_func_ctx: pointer): ptr TBson

proc sized_new*(size: csize): ptr TBson

proc copy*(bson: ptr TBson): ptr TBson

proc copy_to*(src: ptr TBson; dst: ptr TBson)

proc copy_to_excluding*(src: ptr TBson; dst: ptr TBson;
                             first_exclude_varargs_follows: cstring)

proc destroy*(bson: ptr TBson)

proc destroy_with_steal*(bson: ptr TBson; steal: bool;
                              length: ptr uint32): ptr uint8

proc get_data*(bson: ptr TBson): ptr uint8

proc count_keys*(bson: ptr TBson): uint32

proc has_field*(bson: ptr TBson; key: cstring): bool

proc compare*(bson: ptr TBson; other: ptr TBson): cint

proc equal*(bson: ptr TBson; other: ptr TBson): bool

proc validate*(bson: ptr TBson; flags: TValidateFlags;
                    offset: ptr csize): bool

proc as_json*(bson: ptr TBson; length: ptr csize): cstring
proc append_value*(bson: ptr TBson; key: cstring; key_length: cint;
                        value: ptr TBsonVal): bool

proc append_arr*(bson: ptr TBson; key: cstring; key_length: cint;
                        arr: ptr TBson): bool

proc append_binary*(bson: ptr TBson; key: cstring; key_length: cint;
                         subtype: TBinSubtype; binary: ptr uint8;
                         length: uint32): bool

proc append_bool*(bson: ptr TBson; key: cstring; key_length: cint;
                       value: bool): bool

proc append_code*(bson: ptr TBson; key: cstring; key_length: cint;
                       javascript: cstring): bool

proc append_code_with_scope*(bson: ptr TBson; key: cstring;
                                  key_length: cint; javascript: cstring;
                                  scope: ptr TBson): bool

proc append_dbpointer*(bson: ptr TBson; key: cstring; key_length: cint;
                            collection: cstring; oid: ptr TOid): bool

proc append_double*(bson: ptr TBson; key: cstring; key_length: cint;
                         value: cdouble): bool

proc append_document*(bson: ptr TBson; key: cstring; key_length: cint;
                           value: ptr TBson): bool

proc append_document_begin*(bson: ptr TBson; key: cstring;
                                 key_length: cint; child: ptr TBson): bool

proc append_document_end*(bson: ptr TBson; child: ptr TBson): bool

proc append_array_begin*(bson: ptr TBson; key: cstring; key_length: cint;
                              child: ptr TBson): bool

proc append_array_end*(bson: ptr TBson; child: ptr TBson): bool

proc append_int32*(bson: ptr TBson; key: cstring; key_length: cint;
                        value: int32): bool

proc append_int64*(bson: ptr TBson; key: cstring; key_length: cint;
                        value: int64): bool

proc append_iter*(bson: ptr TBson; key: cstring; key_length: cint;
                       iter: ptr TIter): bool

proc append_minkey*(bson: ptr TBson; key: cstring; key_length: cint): bool

proc append_maxkey*(bson: ptr TBson; key: cstring; key_length: cint): bool

proc append_null*(bson: ptr TBson; key: cstring; key_length: cint): bool

proc append_oid*(bson: ptr TBson; key: cstring; key_length: cint;
                      oid: ptr TOid): bool

proc append_regex*(bson: ptr TBson; key: cstring; key_length: cint;
                        regex: cstring; options: cstring): bool

proc append_utf8*(bson: ptr TBson; key: cstring; key_length: cint;
                       value: cstring; length: cint): bool

proc append_symbol*(bson: ptr TBson; key: cstring; key_length: cint;
                         value: cstring; length: cint): bool

proc append_time_t*(bson: ptr TBson; key: cstring; key_length: cint;
                         value: TTime): bool

#proc append_timeval*(bson: ptr TBson; key: cstring; key_length: cint;
#                          value: ptr timeval): bool

proc append_date_time*(bson: ptr TBson; key: cstring; key_length: cint;
                            value: int64): bool

proc append_now_utc*(bson: ptr TBson; key: cstring; key_length: cint): bool

proc append_timestamp*(bson: ptr TBson; key: cstring; key_length: cint;
                            timestamp: uint32; increment: uint32): bool

proc append_undefined*(bson: ptr TBson; key: cstring; key_length: cint): bool
proc concat*(dst: ptr TBson; src: ptr TBson): bool
proc iter_init*(iter: var TIter, b: var TBson): bool
proc iter_recurse*(iter, child: var TIter): bool
proc iter_value*(iter: var TIter): ptr TBsonVal
proc iter_next*(iter: var TIter): bool
proc iter_key*(iter: var TIter): cstring
proc iter_type*(iter: var TIter): TBsonKind
proc iter_document*(iter: var TIter, len: var uint32, data: ptr ptr uint8)
proc iter_array*(iter: var TIter, len: var uint32, array: ptr ptr uint8)
{.pop.} # cdecl, importc, dynlib: bsondll

var valueUnionSize: TValueUnion
assert valueUnionSize.sizeof == 32
var bsonValSize: TBsonVal

assert int.sizeof in [4, 8],
  "int.sizeof is neither 4 nor 8. This needs to be looked into."
assert bsonValSize.sizeof == 32 + int.sizeof

var bsonSize: TBson
assert bsonSize.sizeof == 128
var oidSize: TOid
assert oidSize.sizeof == 12
var errorSize: TError
assert errorSize.sizeof == 512
