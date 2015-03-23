#!strongSpaces

import times, unsigned, oids

when defined(windows):
    import winlean
elif defined(posix):
    import posix
else:
    {.fatal: "platform not supported".}

when defined(windows):
  const
    BsonDll* = "libbson-1.0.dll"
elif defined(macosx):
  const
    BsonDll* = "libbson-1.0.dylib"
else:
  const
    BsonDll* = "libbson-1.0.so"

when defined(windows):
    type
        ssize_t* = int32
        off_t* = clong
else:
    type
        ssize_t* = int
        off_t = int64

type
  md5_t* = object
    count*: array[2, uint32]  # message length in bits, lsw first
    abcd*: array[4, uint32]   # digest buffer
    buf*: array[64, uint8]  # accumulate block


type
  string_t* = object
    str*: cstring
    len*: uint32
    alloc*: uint32

type
  json_reader_t* = distinct pointer
  json_error_code_t* {.size: sizeof(cint).} = enum
    JSON_ERROR_READ_CORRUPT_JS = 1, JSON_ERROR_READ_INVALID_PARAM,
    JSON_ERROR_READ_CB_FAILURE
  json_reader_cb* = proc (handle: pointer; buf: ptr uint8; count: csize): ssize_t
  json_destroy_cb* = proc (handle: pointer)


#*
#  bson_t:
#
#  This structure manages a buffer whose contents are a properly formatted
#  BSON document. You may perform various transforms on the BSON documents.
#  Additionally, it can be iterated over using iter_t.
#
#  See iter_init() for iterating the contents of a bson_t.
#
#  When building a bson_t structure using the various append functions,
#  memory allocations may occur. That is performed using power of two
#  allocations and realloc().
#
#  See http://bsonspec.org for the BSON document spec.
#
#  This structure is meant to fit in two sequential 64-byte cachelines.
#

type
  bson_t* = object
    flags*: uint32            # Internal flags for the bson_t.
    len*: uint32              # Length of BSON data.
    padding*: array[120, uint8] # Padding for stack allocation.

#*
#  bson_type_t:
#
#  This enumeration contains all of the possible types within a BSON document.
#  Use iter_type() to fetch the type of a field while iterating over it.
#
type
  BsonTyp* {.size: sizeof(cint).} = enum
    btEod = 0x00000000,
    btDouble = 0x00000001,
    btUtf8 = 0x00000002,
    btDocument = 0x00000003,
    btArray = 0x00000004,
    btBinary = 0x00000005,
    btUndefined = 0x00000006,
    btOid = 0x00000007,
    btBool = 0x00000008,
    btDateTime = 0x00000009,
    btNull = 0x0000000A,
    btRegex = 0x0000000B,
    btDbPointer = 0x0000000C,
    btCode = 0x0000000D,
    btSymbol = 0x0000000E,
    btCodewscope = 0x0000000F,
    btInt32 = 0x00000010,
    btTimestamp = 0x00000011,
    btInt64 = 0x00000012,
    btMaxkey = 0x0000007F,
    btMinkey = 0x000000FF

#*
#  Oid:
#
#  This structure contains the binary form of a BSON Object Id as specified
#  on http://bsonspec.org. If you would like the Oid in string form
#  see oid_to_string() or oid_to_string_r().
#

when false:
    type
      Oid* = object
        bytes*: array[12, uint8]

#*
#  BinSubtype:
#
#  This enumeration contains the various subtypes that may be used in a binary
#  field. See http://bsonspec.org for more information.
#

type
  BinSubtype* {.size: sizeof(cint).} = enum
    bsBin = 0x00000000,
    bsFunc = 0x00000001,
    bsDeprecated = 0x00000002,
    bsUuidDeprecated = 0x00000003,
    bsUuid = 0x00000004,
    BsMd5 = 0x00000005,
    BsUser = 0x00000080

type
  Timestamp* = object
    timestamp*: uint32
    increment*: uint32

  Utf8* = object
    str*: cstring
    len*: uint32

  Doc* = object
    data*: ptr uint8
    data_len*: uint32

  Binary* = object
    data: ptr array[0 .. 0xffffffff, uint8]
    data_len: uint32
    subtype*: BinSubtype

  Regex* = object
    regex*: cstring
    options*: cstring

  DbPointer* = object
    collection*: cstring
    collection_len*: uint32
    oid*: Oid

  Code* = object
    code*: cstring
    code_len*: uint32

  Codewscope* = object
    code*: cstring
    scope_data*: ptr array[0 .. 0xffffffff, uint8]
    code_len*: uint32
    scope_len*: uint32

  Symbol* = object
    symbol*: cstring
    len*: uint32

  value_union_t* = object {.union.}
    v_oid*: Oid
    v_int64*: int64
    v_int32*: int32
    v_int8*: int8
    v_double*: cdouble
    v_bool*: bool
    v_datetime*: int64
    v_timestamp*: Timestamp
    v_utf8*: Utf8
    v_doc*: Doc
    v_binary*: Binary
    v_regex*: Regex
    v_dbPointer*: DbPointer
    v_code*: Code
    v_codewscope*: Codewscope
    v_symbol*: Symbol

  value_t* = object
    value_type*: BsonTyp
    padding*: int32
    value*: value_union_t

type
  flags_t* {.size: sizeof(cint).} = enum
    FLAG_NONE = 0, FLAG_INLINE = (1 shl 0),
    FLAG_STATIC = (1 shl 1), FLAG_RDONLY = (1 shl 2),
    FLAG_CHILD = (1 shl 3), FLAG_IN_CHILD = (1 shl 4),
    FLAG_NO_FREE = (1 shl 5)
  impl_inline_t* = object
    flags*: flags_t
    len*: uint32
    data*: array[120, uint8]
  realloc_func* = proc (mem: pointer; num_bytes: csize; ctx: pointer): pointer
  mem_vtable_t* = object
    malloc*: proc (num_bytes: csize): pointer
    calloc*: proc (n_members: csize; num_bytes: csize): pointer
    realloc*: proc (mem: pointer; num_bytes: csize): pointer
    free*: proc (mem: pointer)
    padding*: array[4, pointer]

  impl_alloc_t* = object
    flags*: flags_t      # flags describing the bson_t
    len*: uint32              # length of bson document in bytes
    parent*: ptr bson_t       # parent bson if a child
    depth*: uint32            # Subdocument depth.
    buf*: ptr ptr uint8     # pointer to buffer pointer
    buflen*: ptr csize        # pointer to buffer length
    offset*: csize            # our offset inside *buf
    alloc*: ptr uint8       # buffer that we own.
    alloclen*: csize          # length of buffer that we own.
    realloc*: realloc_func # our realloc implementation
    realloc_func_ctx*: pointer # context for our realloc func



#
# --------------------------------------------------------------------------
#
#  reader_read_func_t --
#
#        This function is a callback used by reader_t to read the
#        next chunk of data from the underlying opaque file descriptor.
#
#        This function is meant to operate similar to the read() function
#        as part of libc on UNIX-like systems.
#
#  Parameters:
#        @handle: The handle to read from.
#        @buf: The buffer to read into.
#        @count: The number of bytes to read.
#
#  Returns:
#        0 for end of stream.
#        -1 for read failure.
#        Greater than zero for number of bytes read into @buf.
#
#  Side effects:
#        None.
#
# --------------------------------------------------------------------------
#

type
  reader_read_func_t* = proc (handle: pointer; buf: pointer; count: csize): ssize_t
#
# --------------------------------------------------------------------------
#
#  reader_destroy_func_t --
#
#        Destroy callback to release any resources associated with the
#        opaque handle.
#
#  Parameters:
#        @handle: the handle provided to reader_new_from_handle().
#
#  Returns:
#        None.
#
#  Side effects:
#        None.
#
# --------------------------------------------------------------------------
#

type
  reader_destroy_func_t* = proc (handle: pointer)
#*
#  reader_t:
#
#  This structure is used to iterate over a sequence of BSON documents. It
#  allows for them to be iterated with the possibility of no additional
#  memory allocations under certain circumstances such as reading from an
#  incoming mongo packet.
#

type
  reader_t* = object
    typ: uint32             #< private >
#
# --------------------------------------------------------------------------
#
#  unichar_t --
#
#        unichar_t provides an unsigned 32-bit type for containing
#        unicode characters. When iterating UTF-8 sequences, this should
#        be used to avoid losing the high-bits of non-ascii characters.
#
#  See also:
#        string_append_unichar()
#
# --------------------------------------------------------------------------
#

type
  unichar_t* = uint32
type
    va_list* = cstring

#*
#  validate_flags_t:
#
#  This enumeration is used for validation of BSON documents. It allows
#  selective control on what you wish to validate.
#
#  %VALIDATE_NONE: No additional validation occurs.
#  %VALIDATE_UTF8: Check that strings are valid UTF-8.
#  %VALIDATE_DOLLAR_KEYS: Check that keys do not start with $.
#  %VALIDATE_DOT_KEYS: Check that keys do not contain a period.
#  %VALIDATE_UTF8_ALLOW_NULL: Allow NUL bytes in UTF-8 text.
#

#*
#  writer_t:
#
#  The writer_t structure is a helper for writing a series of BSON
#  documents to a single malloc() buffer. You can provide a realloc() style
#  function to grow the buffer as you go.
#
#  This is useful if you want to build a series of BSON documents right into
#  the target buffer for an outgoing packet. The offset parameter allows you to
#  start at an offset of the target buffer.
#

type
  writer_t* = distinct pointer
type
  validate_flags_t* {.size: sizeof(cint).} = enum
    VALIDATE_NONE = 0, VALIDATE_UTF8 = (1 shl 0),
    VALIDATE_DOLLAR_KEYS = (1 shl 1), VALIDATE_DOT_KEYS = (1 shl 2),
    VALIDATE_UTF8_ALLOW_NULL = (1 shl 3)

#*
#  context_flags_t:
#
#  This enumeration is used to configure a context_t.
#
#  %CONTEXT_NONE: Use default options.
#  %CONTEXT_THREAD_SAFE: Context will be called from multiple threads.
#  %CONTEXT_DISABLE_PID_CACHE: Call getpid() instead of caching the
#    result of getpid() when initializing the context.
#  %CONTEXT_DISABLE_HOST_CACHE: Call gethostname() instead of caching the
#    result of gethostname() when initializing the context.
#

type
  context_flags_t* {.size: sizeof(cint).} = enum
    CONTEXT_NONE = 0, CONTEXT_THREAD_SAFE = (1 shl 0),
    CONTEXT_DISABLE_HOST_CACHE = (1 shl 1),
    CONTEXT_DISABLE_PID_CACHE = (1 shl 2),
    XXX_FOR_LINUX_CONTEXT_USE_TASK_ID = (1 shl 3)


type
  error_t* = object
    domain*: uint32
    code*: uint32
    message*: array[504, char]

assert error_t.sizeof == 512

#*
#  context_t:
#
#  This structure manages context for the bson library. It handles
#  configuration for thread-safety and other performance related requirements.
#  Consumers will create a context and may use multiple under a variety of
#  situations.
#
#  If your program calls fork(), you should initialize a new context_t
#  using context_init().
#
#  If you are using threading, it is suggested that you use a context_t
#  per thread for best performance. Alternatively, you can initialize the
#  context_t with CONTEXT_THREAD_SAFE, although a performance penalty
#  will be incurred.
#
#  Many functions will require that you provide a context_t such as OID
#  generation.
#
#  This structure is oqaque in that you cannot see the contents of the
#  structure. However, it is stack allocatable in that enough padding is
#  provided in _context_t to hold the structure.
#

type
  context_t* = distinct pointer

{.deadCodeElim: on.}
{.push cdecl, importc: "bson_$1", dynlib: BsonDll.}

proc get_monotonic_time*(): int64

proc gettimeofday*(tv: ptr TimeVal): cint

proc context_new*(flags: context_flags_t): ptr context_t

proc context_destroy*(context: ptr context_t)

proc context_get_default*(): ptr context_t

proc set_error*(error: ptr error_t; domain: uint32; code: uint32;
                     format: cstring) {.varargs.}
proc strerror_r*(err_code: cint; buf: cstring; buflen: csize): cstring

#*
#  empty:
#  @b: a bson_t.
#
#  Checks to see if @b is an empty BSON document. An empty BSON document is
#  a 5 byte document which contains the length (4 bytes) and a single NUL
#  byte indicating end of fields.
#

template empty*(b: expr): expr =
  (((b).len == 5) or not get_data((b))[4])

#*
#  empty0:
#
#  Like empty() but treats NULL the same as an empty bson_t document.
#

template empty0*(b: expr): expr =
  (not (b) or empty(b))


#*
#  destroy:
#  @bson: A bson_t.
#
#  Frees the resources associated with @bson.
#

proc destroy*(bson: ptr bson_t)

assert bson_t.sizeof == 128

#*
#  clear:
#
#  Easily free a bson document and set it to NULL. Use like:
#
#  bson_t *doc = new();
#  clear (&doc);
#  assert (doc == NULL);
#

proc clear*(b: var ptr bson_t) =
    if b != nil:
        destroy(b)
        b = nil

#*
#  MAX_SIZE:
#
#  The maximum size in bytes of a BSON document.
#

const
  MAX_SIZE* = ((csize)((1 shl 31) - 1))

#*
#  new:
#
#  Allocates a new bson_t structure. Call the various append_*()
#  functions to add fields to the bson. You can iterate the bson_t at any
#  time using a iter_t and iter_init().
#
#  Returns: A newly allocated bson_t that should be freed with destroy().
#

proc new*(): ptr bson_t

proc new_from_json*(data: ptr uint8; len: ssize_t;
                         error: ptr error_t): ptr bson_t

proc init_from_json*(bson: ptr bson_t; data: cstring; len: ssize_t;
                          error: ptr error_t): bool

#*
#  init_static:
#  @b: A pointer to a bson_t.
#  @data: The data buffer to use.
#  @length: The length of @data.
#
#  Initializes a bson_t using @data and @length. This is ideal if you would
#  like to use a stack allocation for your bson and do not need to grow the
#  buffer. @data must be valid for the life of @b.
#
#  Returns: true if initialized successfully; otherwise false.
#

proc init_static*(b: ptr bson_t; data: ptr uint8; length: csize): bool

#*
#  init:
#  @b: A pointer to a bson_t.
#
#  Initializes a bson_t for use. This function is useful to those that want a
#  stack allocated bson_t. The usefulness of a stack allocated bson_t is
#  marginal as the target buffer for content will still require heap
#  allocations. It can help reduce heap fragmentation on allocators that do
#  not employ SLAB/magazine semantics.
#
#  You must call destroy() with @b to release resources when you are done
#  using @b.
#

proc init*(b: ptr bson_t)
#*
#  reinit:
#  @b: (inout): A bson_t.
#
#  This is equivalent to calling destroy() and init() on a #bson_t.
#  However, it will try to persist the existing malloc'd buffer if one exists.
#  This is useful in cases where you want to reduce malloc overhead while
#  building many documents.
#

proc reinit*(b: ptr bson_t)
#*
#  new_from_data:
#  @data: A buffer containing a serialized bson document.
#  @length: The length of the document in bytes.
#
#  Creates a new bson_t structure using the data provided. @data should contain
#  at least @length bytes that can be copied into the new bson_t structure.
#
#  Returns: A newly allocated bson_t that should be freed with destroy().
#    If the first four bytes (little-endian) of data do not match @length,
#    then NULL will be returned.
#

proc new_from_data*(data: ptr uint8; length: csize): ptr bson_t

#*
#  new_from_buffer:
#  @buf: A pointer to a buffer containing a serialized bson document.  Or null
#  @buf_len: The length of the buffer in bytes.
#  @realloc_fun: a realloc like function
#  @realloc_fun_ctx: a context for the realloc function
#
#  Creates a new bson_t structure using the data provided. @buf should contain
#  a bson document, or null pointer should be passed for new allocations.
#
#  Returns: A newly allocated bson_t that should be freed with destroy().
#           The underlying buffer will be used and not be freed in destroy.
#

proc new_from_buffer*(buf: ptr ptr uint8; buf_len: ptr csize;
                           realloc_func: realloc_func;
                           realloc_func_ctx: pointer): ptr bson_t

#*
#  sized_new:
#  @size: A size_t containing the number of bytes to allocate.
#
#  This will allocate a new bson_t with enough bytes to hold a buffer
#  sized @size. @size must be smaller than INT_MAX bytes.
#
#  Returns: A newly allocated bson_t that should be freed with destroy().
#

proc sized_new*(size: csize): ptr bson_t

#*
#  copy:
#  @bson: A bson_t.
#
#  Copies @bson into a newly allocated bson_t. You must call destroy()
#  when you are done with the resulting value to free its resources.
#
#  Returns: A newly allocated bson_t that should be free'd with destroy()
#

proc copy*(bson: ptr bson_t): ptr bson_t
#*
#  copy_to:
#  @src: The source bson_t.
#  @dst: The destination bson_t.
#
#  Initializes @dst and copies the content from @src into @dst.
#

proc copy_to*(src: ptr bson_t; dst: ptr bson_t)

#*
#  copy_to_excluding:
#  @src: A bson_t.
#  @dst: A bson_t to initialize and copy into.
#  @first_exclude: First field name to exclude.
#
#  Copies @src into @dst excluding any field that is provided.
#  This is handy for situations when you need to remove one or
#  more fields in a bson_t.
#

proc copy_to_excluding*(src: ptr bson_t; dst: ptr bson_t;
                             first_exclude: cstring) {.varargs.}

#*
#  destroy_with_steal:
#  @bson: A #bson_t.
#  @steal: If ownership of the data buffer should be transfered to caller.
#  @length: (out): location for the length of the buffer.
#
#  Destroys @bson similar to calling destroy() except that the underlying
#  buffer will be returned and ownership transfered to the caller if @steal
#  is non-zero.
#
#  If length is non-NULL, the length of @bson will be stored in @length.
#
#  It is a programming error to call this function with any bson that has
#  been initialized static, or is being used to create a subdocument with
#  functions such as append_document_begin() or append_array_begin().
#
#  Returns: a buffer owned by the caller if @steal is true. Otherwise NULL.
#     If there was an error, NULL is returned.
#

proc destroy_with_steal*(bson: ptr bson_t; steal: bool; length: ptr uint32): ptr uint8

#*
#  get_data:
#  @bson: A bson_t.
#
#  Fetched the data buffer for @bson of @bson->len bytes in length.
#
#  Returns: A buffer that should not be modified or freed.
#

proc get_data*(bson: ptr bson_t): ptr uint8

#*
#  count_keys:
#  @bson: A bson_t.
#
#  Counts the number of elements found in @bson.
#

proc count_keys*(bson: ptr bson_t): uint32

#*
#  has_field:
#  @bson: A bson_t.
#  @key: The key to lookup.
#
#  Checks to see if @bson contains a field named @key.
#
#  This function is case-sensitive.
#
#  Returns: true if @key exists in @bson; otherwise false.
#

proc has_field*(bson: ptr bson_t; key: cstring): bool

#*
#  compare:
#  @bson: A bson_t.
#  @other: A bson_t.
#
#  Compares @bson to @other in a qsort() style comparison.
#  See qsort() for information on how this function works.
#
#  Returns: Less than zero, zero, or greater than zero.
#

proc compare*(bson: ptr bson_t; other: ptr bson_t): cint

#
#  compare:
#  @bson: A bson_t.
#  @other: A bson_t.
#
#  Checks to see if @bson and @other are equal.
#
#  Returns: true if equal; otherwise false.
#

proc equal*(bson: ptr bson_t; other: ptr bson_t): bool

#*
#  validate:
#  @bson: A bson_t.
#  @offset: A location for the error offset.
#
#  Validates a BSON document by walking through the document and inspecting
#  the fields for valid content.
#
#  Returns: true if @bson is valid; otherwise false and @offset is set.
#

proc validate*(bson: ptr bson_t; flags: validate_flags_t;
                    offset: ptr csize): bool
#*
#  as_json:
#  @bson: A bson_t.
#  @length: A location for the string length, or NULL.
#
#  Creates a new string containing @bson in extended JSON format. The caller
#  is responsible for freeing the resulting string. If @length is non-NULL,
#  then the length of the resulting string will be placed in @length.
#
#  See http://docs.mongodb.org/manual/reference/mongodb-extended-json/ for
#  more information on extended JSON.
#
#  Returns: A newly allocated string that should be freed with free().
#

proc as_json*(bson: ptr bson_t; length: ptr csize): cstring

# like as_json() but for outermost arrays.

proc array_as_json*(bson: ptr bson_t; length: ptr csize): cstring


#
# --------------------------------------------------------------------------
#
#  value_t --
#
#        A boxed type to contain various bson_type_t types.
#
#  See also:
#        value_copy()
#        value_destroy()
#
# --------------------------------------------------------------------------
#

proc `[]`*(o: Binary, i: Natural): uint8 =
    assert i.uint32 <= o.data_len
    result = o.data[0]

proc len*(o: Binary): uint32 =
    result = o.data_len

proc append_value*(bson: ptr bson_t; key: cstring; key_length: cint;
                        value: ptr value_t): bool

#*
#  append_array:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @array: A bson_t containing the array.
#
#  Appends a BSON array to @bson. BSON arrays are like documents where the
#  key is the string version of the index. For example, the first item of the
#  array would have the key "0". The second item would have the index "1".
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_array*(bson: ptr bson_t; key: cstring; key_length: cint;
                        array: ptr bson_t): bool

#*
#  append_binary:
#  @bson: A bson_t to append.
#  @key: The key for the field.
#  @subtype: The BinSubtype of the binary.
#  @binary: The binary buffer to append.
#  @length: The length of @binary.
#
#  Appends a binary buffer to the BSON document.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_binary*(bson: ptr bson_t; key: cstring; key_length: cint;
                         subtype: BinSubtype; binary: ptr uint8;
                         length: uint32): bool

#*
#  append_bool:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: The boolean value.
#
#  Appends a new field to @bson of type TYPE_BOOL.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_bool*(bson: ptr bson_t; key: cstring; key_length: cint;
                       value: bool): bool
#*
#  append_code:
#  @bson: A bson_t.
#  @key: The key for the document.
#  @javascript: JavaScript code to be executed.
#
#  Appends a field of type TYPE_CODE to the BSON document. @javascript
#  should contain a script in javascript to be executed.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_code*(bson: ptr bson_t; key: cstring; key_length: cint;
                       javascript: cstring): bool

#*
#  append_code_with_scope:
#  @bson: A bson_t.
#  @key: The key for the document.
#  @javascript: JavaScript code to be executed.
#  @scope: A bson_t containing the scope for @javascript.
#
#  Appends a field of type TYPE_CODEWSCOPE to the BSON document.
#  @javascript should contain a script in javascript to be executed.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_code_with_scope*(bson: ptr bson_t; key: cstring;
                                  key_length: cint; javascript: cstring;
                                  scope: ptr bson_t): bool

#*
#  append_dbpointer:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @collection: The collection name.
#  @oid: The oid to the reference.
#
#  Appends a new field of type TYPE_DBPOINTER. This datum type is
#  deprecated in the BSON spec and should not be used in new code.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_dbpointer*(bson: ptr bson_t; key: cstring; key_length: cint;
                            collection: cstring; oid: ptr Oid): bool

#*
#  append_double:
#  @bson: A bson_t.
#  @key: The key for the field.
#
#  Appends a new field to @bson of the type TYPE_DOUBLE.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_double*(bson: ptr bson_t; key: cstring; key_length: cint;
                         value: cdouble): bool

#*
#  append_document:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: A bson_t containing the subdocument.
#
#  Appends a new field to @bson of the type TYPE_DOCUMENT.
#  The documents contents will be copied into @bson.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_document*(bson: ptr bson_t; key: cstring; key_length: cint;
                           value: ptr bson_t): bool

#*
#  append_document_begin:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @key_length: The length of @key in bytes not including NUL or -1
#     if @key_length is NUL terminated.
#  @child: A location to an uninitialized bson_t.
#
#  Appends a new field named @key to @bson. The field is, however,
#  incomplete.  @child will be initialized so that you may add fields to the
#  child document.  Child will use a memory buffer owned by @bson and
#  therefore grow the parent buffer as additional space is used. This allows
#  a single malloc'd buffer to be used when building documents which can help
#  reduce memory fragmentation.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_document_begin*(bson: ptr bson_t; key: cstring;
                                 key_length: cint; child: ptr bson_t): bool

#*
#  append_document_end:
#  @bson: A bson_t.
#  @child: A bson_t supplied to append_document_begin().
#
#  Finishes the appending of a document to a @bson. @child is considered
#  disposed after this call and should not be used any further.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_document_end*(bson: ptr bson_t; child: ptr bson_t): bool

#*
#  append_array_begin:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @key_length: The length of @key in bytes not including NUL or -1
#     if @key_length is NUL terminated.
#  @child: A location to an uninitialized bson_t.
#
#  Appends a new field named @key to @bson. The field is, however,
#  incomplete. @child will be initialized so that you may add fields to the
#  child array. Child will use a memory buffer owned by @bson and
#  therefore grow the parent buffer as additional space is used. This allows
#  a single malloc'd buffer to be used when building arrays which can help
#  reduce memory fragmentation.
#
#  The type of @child will be TYPE_ARRAY and therefore the keys inside
#  of it MUST be "0", "1", etc.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_array_begin*(bson: ptr bson_t; key: cstring; key_length: cint;
                              child: ptr bson_t): bool

#*
#  append_array_end:
#  @bson: A bson_t.
#  @child: A bson_t supplied to append_array_begin().
#
#  Finishes the appending of a array to a @bson. @child is considered
#  disposed after this call and should not be used any further.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_array_end*(bson: ptr bson_t; child: ptr bson_t): bool

#*
#  append_int32:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: The int32_t 32-bit integer value.
#
#  Appends a new field of type TYPE_INT32 to @bson.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_int32*(bson: ptr bson_t; key: cstring; key_length: cint;
                        value: int32): bool

#*
#  append_int64:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: The int64_t 64-bit integer value.
#
#  Appends a new field of type TYPE_INT64 to @bson.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_int64*(bson: ptr bson_t; key: cstring; key_length: cint;
                        value: int64): bool

#*
#  visitor_t:
#
#  This structure contains a series of pointers that can be executed for
#  each field of a BSON document based on the field type.
#
#  For example, if an int32 field is found, visit_int32 will be called.
#
#  When visiting each field using iter_visit_all(), you may provide a
#  data pointer that will be provided with each callback. This might be useful
#  if you are marshaling to another language.
#
#  You may pre-maturely stop the visitation of fields by returning true in your
#  visitor. Returning false will continue visitation to further fields.
#

#*
#  iter_t:
#
#  This structure manages iteration over a bson_t structure. It keeps track
#  of the location of the current key and value within the buffer. Using the
#  various functions to get the value of the iter will read from these
#  locations.
#
#  This structure is safe to discard on the stack. No cleanup is necessary
#  after using it.
#

type
  iter_t* = object
    raw*: ptr uint8         # The raw buffer being iterated.
    len*: uint32              # The length of raw.
    off*: uint32              # The offset within the buffer.
    typ*: uint32             # The offset of the type byte.
    key*: uint32              # The offset of the key byte.
    d1*: uint32               # The offset of the first data byte.
    d2*: uint32               # The offset of the second data byte.
    d3*: uint32               # The offset of the third data byte.
    d4*: uint32               # The offset of the fourth data byte.
    next_off*: uint32         # The offset of the next field.
    err_off*: uint32          # The offset of the error.
    value*: value_t      # Internal value for various state.


type
  visitor_t* = object
    visit_before*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    visit_after*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    visit_corrupt*: proc (iter: ptr iter_t; data: pointer)
    visit_double*: proc (iter: ptr iter_t; key: cstring; v_double: cdouble;
                         data: pointer): bool
    visit_utf8*: proc (iter: ptr iter_t; key: cstring; v_utf8_len: csize;
                       v_utf8: cstring; data: pointer): bool
    visit_document*: proc (iter: ptr iter_t; key: cstring;
                           v_document: ptr bson_t; data: pointer): bool
    visit_array*: proc (iter: ptr iter_t; key: cstring;
                        v_array: ptr bson_t; data: pointer): bool
    visit_binary*: proc (iter: ptr iter_t; key: cstring;
                         v_subtype: BinSubtype; v_binary_len: csize;
                         v_binary: ptr uint8; data: pointer): bool
    visit_undefined*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    visit_oid*: proc (iter: ptr iter_t; key: cstring;
                      v_oid: ptr Oid; data: pointer): bool
    visit_bool*: proc (iter: ptr iter_t; key: cstring; v_bool: bool;
                       data: pointer): bool
    visit_date_time*: proc (iter: ptr iter_t; key: cstring;
                            msec_since_epoch: int64; data: pointer): bool
    visit_null*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    visit_regex*: proc (iter: ptr iter_t; key: cstring; v_regex: cstring;
                        v_options: cstring; data: pointer): bool
    visit_dbpointer*: proc (iter: ptr iter_t; key: cstring;
                            v_collection_len: csize; v_collection: cstring;
                            v_oid: ptr Oid; data: pointer): bool
    visit_code*: proc (iter: ptr iter_t; key: cstring; v_code_len: csize;
                       v_code: cstring; data: pointer): bool
    visit_symbol*: proc (iter: ptr iter_t; key: cstring;
                         v_symbol_len: csize; v_symbol: cstring; data: pointer): bool
    visit_codewscope*: proc (iter: ptr iter_t; key: cstring;
                             v_code_len: csize; v_code: cstring;
                             v_scope: ptr bson_t; data: pointer): bool
    visit_int32*: proc (iter: ptr iter_t; key: cstring; v_int32: int32;
                        data: pointer): bool
    visit_timestamp*: proc (iter: ptr iter_t; key: cstring;
                            v_timestamp: uint32; v_increment: uint32;
                            data: pointer): bool
    visit_int64*: proc (iter: ptr iter_t; key: cstring; v_int64: int64;
                        data: pointer): bool
    visit_maxkey*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    visit_minkey*: proc (iter: ptr iter_t; key: cstring; data: pointer): bool
    padding*: array[9, pointer]

#*
#  append_iter:
#  @bson: A bson_t to append to.
#  @key: The key name or %NULL to take current key from @iter.
#  @key_length: The key length or -1 to use strlen().
#  @iter: The iter located on the position of the element to append.
#
#  Appends a new field to @bson that is equivalent to the field currently
#  pointed to by @iter.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_iter*(bson: ptr bson_t; key: cstring; key_length: cint;
                       iter: ptr iter_t): bool

#*
#  append_minkey:
#  @bson: A bson_t.
#  @key: The key for the field.
#
#  Appends a new field of type TYPE_MINKEY to @bson. This is a special
#  type that compares lower than all other possible BSON element values.
#
#  See http://bsonspec.org for more information on this type.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_minkey*(bson: ptr bson_t; key: cstring; key_length: cint): bool

#*
#  append_maxkey:
#  @bson: A bson_t.
#  @key: The key for the field.
#
#  Appends a new field of type TYPE_MAXKEY to @bson. This is a special
#  type that compares higher than all other possible BSON element values.
#
#  See http://bsonspec.org for more information on this type.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_maxkey*(bson: ptr bson_t; key: cstring; key_length: cint): bool

#*
#  append_null:
#  @bson: A bson_t.
#  @key: The key for the field.
#
#  Appends a new field to @bson with NULL for the value.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_null*(bson: ptr bson_t; key: cstring; key_length: cint): bool

#*
#  append_oid:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @oid: Oid.
#
#  Appends a new field to the @bson of type TYPE_OID using the contents of
#  @oid.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_oid*(bson: ptr bson_t; key: cstring; key_length: cint;
                      oid: ptr Oid): bool

#*
#  append_regex:
#  @bson: A bson_t.
#  @key: The key of the field.
#  @regex: The regex to append to the bson.
#  @options: Options for @regex.
#
#  Appends a new field to @bson of type TYPE_REGEX. @regex should
#  be the regex string. @options should contain the options for the regex.
#
#  Valid options for @options are:
#
#    'i' for case-insensitive.
#    'm' for multiple matching.
#    'x' for verbose mode.
#    'l' to make \w and \W locale dependent.
#    's' for dotall mode ('.' matches everything)
#    'u' to make \w and \W match unicode.
#
#  For more information on what comprimises a BSON regex, see bsonspec.org.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_regex*(bson: ptr bson_t; key: cstring; key_length: cint;
                        regex: cstring; options: cstring): bool

#*
#  append_utf8:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: A UTF-8 encoded string.
#  @length: The length of @value or -1 if it is NUL terminated.
#
#  Appends a new field to @bson using @key as the key and @value as the UTF-8
#  encoded value.
#
#  It is the callers responsibility to ensure @value is valid UTF-8. You can
#  use utf8_validate() to perform this check.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_utf8*(bson: ptr bson_t; key: cstring; key_length: cint;
                       value: cstring; length: cint): bool

#*
#  append_symbol:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: The symbol as a string.
#  @length: The length of @value or -1 if NUL-terminated.
#
#  Appends a new field to @bson of type TYPE_SYMBOL. This BSON type is
#  deprecated and should not be used in new code.
#
#  See http://bsonspec.org for more information on this type.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_symbol*(bson: ptr bson_t; key: cstring; key_length: cint;
                         value: cstring; length: cint): bool

#*
#  append_time_t:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: A Time.
#
#  Appends a TYPE_DATE_TIME field to @bson using the Time @value for the
#  number of seconds since UNIX epoch in UTC.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_time_t*(bson: ptr bson_t; key: cstring; key_length: cint;
                         value: Time): bool

#*
#  append_timeval:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @value: A struct TimeVal containing the date and time.
#
#  Appends a TYPE_DATE_TIME field to @bson using the struct TimeVal
#  provided. The time is persisted in milliseconds since the UNIX epoch in UTC.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_timeval*(bson: ptr bson_t; key: cstring; key_length: cint;
                          value: ptr TimeVal): bool

#*
#  append_date_time:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @key_length: The length of @key in bytes or -1 if \0 terminated.
#  @value: The number of milliseconds elapsed since UNIX epoch.
#
#  Appends a new field to @bson of type TYPE_DATE_TIME.
#
#  Returns: true if sucessful; otherwise false.
#

proc append_date_time*(bson: ptr bson_t; key: cstring; key_length: cint;
                            value: int64): bool

#*
#  append_now_utc:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @key_length: The length of @key or -1 if it is NULL terminated.
#
#  Appends a TYPE_DATE_TIME field to @bson using the current time in UTC
#  as the field value.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_now_utc*(bson: ptr bson_t; key: cstring; key_length: cint): bool

#*
#  append_timestamp:
#  @bson: A bson_t.
#  @key: The key for the field.
#  @timestamp: 4 byte timestamp.
#  @increment: 4 byte increment for timestamp.
#
#  Appends a field of type TYPE_TIMESTAMP to @bson. This is a special type
#  used by MongoDB replication and sharding. If you need generic time and date
#  fields use append_time_t() or append_timeval().
#
#  Setting @increment and @timestamp to zero has special semantics. See
#  http://bsonspec.org for more information on this field type.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_timestamp*(bson: ptr bson_t; key: cstring; key_length: cint;
                            timestamp: uint32; increment: uint32): bool

#*
#  append_undefined:
#  @bson: A bson_t.
#  @key: The key for the field.
#
#  Appends a field of type TYPE_UNDEFINED. This type is deprecated in the
#  spec and should not be used for new code. However, it is provided for those
#  needing to interact with legacy systems.
#
#  Returns: true if successful; false if append would overflow max size.
#

proc append_undefined*(bson: ptr bson_t; key: cstring; key_length: cint): bool

proc concat*(dst: ptr bson_t; src: ptr bson_t): bool

proc iter_value*(iter: ptr iter_t): ptr value_t

proc iter_array*(iter: ptr iter_t; array_len: ptr uint32;
                      array: ptr ptr uint8)

proc iter_binary*(iter: ptr iter_t; subtype: ptr BinSubtype;
                       binary_len: ptr uint32; binary: ptr ptr uint8)

proc iter_code*(iter: ptr iter_t; length: ptr uint32): cstring

proc iter_codewscope*(iter: ptr iter_t; length: ptr uint32;
                           scope_len: ptr uint32; scope: ptr ptr uint8): cstring

proc iter_dbpointer*(iter: ptr iter_t; collection_len: ptr uint32;
                          collection: cstringArray; oid: ptr ptr Oid)

proc iter_document*(iter: ptr iter_t; document_len: ptr uint32;
                         document: ptr ptr uint8)

proc iter_double*(iter: ptr iter_t): cdouble

proc iter_init*(iter: ptr iter_t; bson: ptr bson_t): bool

proc iter_init_find*(iter: ptr iter_t; bson: ptr bson_t; key: cstring): bool

proc iter_init_find_case*(iter: ptr iter_t; bson: ptr bson_t;
                               key: cstring): bool

proc iter_int32*(iter: ptr iter_t): int32

proc iter_int64*(iter: ptr iter_t): int64

proc iter_as_int64*(iter: ptr iter_t): int64

proc iter_find*(iter: ptr iter_t; key: cstring): bool

proc iter_find_case*(iter: ptr iter_t; key: cstring): bool

proc iter_find_descendant*(iter: ptr iter_t; dotkey: cstring;
                                descendant: ptr iter_t): bool

proc iter_next*(iter: ptr iter_t): bool

proc iter_oid*(iter: ptr iter_t): ptr Oid

proc iter_key*(iter: ptr iter_t): cstring

proc iter_utf8*(iter: ptr iter_t; length: ptr uint32): cstring

proc iter_dup_utf8*(iter: ptr iter_t; length: ptr uint32): cstring

proc iter_date_time*(iter: ptr iter_t): int64

proc iter_time_t*(iter: ptr iter_t): Time

proc iter_timeval*(iter: ptr iter_t; tv: ptr TimeVal)

proc iter_timestamp*(iter: ptr iter_t; timestamp: ptr uint32;
                          increment: ptr uint32)

proc iter_bool*(iter: ptr iter_t): bool

proc iter_as_bool*(iter: ptr iter_t): bool

proc iter_regex*(iter: ptr iter_t; options: cstringArray): cstring

proc iter_symbol*(iter: ptr iter_t; length: ptr uint32): cstring

proc iter_type*(iter: ptr iter_t): BsonTyp

proc iter_recurse*(iter: ptr iter_t; child: ptr iter_t): bool

proc iter_overwrite_int32*(iter: ptr iter_t; value: int32)

proc iter_overwrite_int64*(iter: ptr iter_t; value: int64)

proc iter_overwrite_double*(iter: ptr iter_t; value: cdouble)

proc iter_overwrite_bool*(iter: ptr iter_t; value: bool)

proc iter_visit_all*(iter: ptr iter_t; visitor: ptr visitor_t;
                          data: pointer): bool

proc json_reader_new*(data: pointer; cb: json_reader_cb;
                           dcb: json_destroy_cb; allow_multiple: bool;
                           buf_size: csize): ptr json_reader_t

proc json_reader_new_from_fd*(fd: cint; close_on_destroy: bool): ptr json_reader_t

proc json_reader_new_from_file*(filename: cstring; error: ptr error_t): ptr json_reader_t

proc json_reader_destroy*(reader: ptr json_reader_t)

proc json_reader_read*(reader: ptr json_reader_t; bson: ptr bson_t;
                            error: ptr error_t): cint

proc json_data_reader_new*(allow_multiple: bool; size: csize): ptr json_reader_t

proc json_data_reader_ingest*(reader: ptr json_reader_t;
                                   data: ptr uint8; len: csize)

proc uint32_to_string*(value: uint32; strptr: cstringArray; str: cstring;
                            size: csize): csize

template str_empty*(s: expr): expr =
  (not s[0])

template str_empty0*(s: expr): expr =
  (not s or not s[0])

proc md5_init*(pms: ptr md5_t)
proc md5_append*(pms: ptr md5_t; data: ptr uint8; nbytes: uint32)

proc md5_finish*(pms: ptr md5_t; digest: array[16, uint8])


proc mem_set_vtable*(vtable: ptr mem_vtable_t)

proc oid_compare*(oid1: ptr Oid; oid2: ptr Oid): cint

proc oid_copy*(src: ptr Oid; dst: ptr Oid)

proc oid_equal*(oid1: ptr Oid; oid2: ptr Oid): bool

proc oid_is_valid*(str: cstring; length: csize): bool

proc oid_get_time_t*(oid: ptr Oid): Time

proc oid_hash*(oid: ptr Oid): uint32

proc oid_init*(oid: ptr Oid; context: ptr context_t)

proc oid_init_from_data*(oid: ptr Oid; data: ptr uint8)

proc oid_init_from_string*(oid: ptr Oid; str: cstring)

proc oid_init_sequence*(oid: ptr Oid; context: ptr context_t)

proc oid_to_string*(oid: ptr Oid; str: array[25, char])


proc reader_new_from_handle*(handle: pointer; rf: reader_read_func_t;
                                  df: reader_destroy_func_t): ptr reader_t

proc reader_new_from_fd*(fd: cint; close_on_destroy: bool): ptr reader_t

proc reader_new_from_file*(path: cstring; error: ptr error_t): ptr reader_t

proc reader_new_from_data*(data: ptr uint8; length: csize): ptr reader_t

proc reader_destroy*(reader: ptr reader_t)

proc reader_set_read_func*(reader: ptr reader_t;
                                `func`: reader_read_func_t)

proc reader_set_destroy_func*(reader: ptr reader_t;
                                   `func`: reader_destroy_func_t)

proc reader_read*(reader: ptr reader_t; reached_eof: ptr bool): ptr bson_t

proc reader_tell*(reader: ptr reader_t): off_t

proc string_new*(str: cstring): ptr string_t

proc string_free*(string: ptr string_t; free_segment: bool): cstring

proc string_append*(string: ptr string_t; str: cstring)

proc string_append_c*(string: ptr string_t; str: char)

proc string_append_unichar*(string: ptr string_t;
                                 unichar: unichar_t)

proc string_append_printf*(string: ptr string_t; format: cstring)

proc string_truncate*(string: ptr string_t; len: uint32)

proc strdup*(str: cstring): cstring
proc strdup_printf*(format: cstring): cstring {.varargs.}

proc strdupv_printf*(format: cstring; args: va_list): cstring

proc strndup*(str: cstring; n_bytes: csize): cstring

proc strncpy*(dst: cstring; src: cstring; size: csize)

proc vsnprintf*(str: cstring; size: csize; format: cstring; ap: va_list): cint

proc snprintf*(str: cstring; size: csize; format: cstring): cint {.varargs.}

proc strfreev*(strv: cstringArray)
proc strnlen*(s: cstring; maxlen: csize): csize

proc ascii_strtoll*(str: cstring; endptr: cstringArray; base: cint): int64


#*
#  INITIALIZER:
#
#  This macro can be used to initialize a #bson_t structure on the stack
#  without calling init().
#
#  |[
#  bson_t b = INITIALIZER;
#  ]|
#

const
  INITIALIZER* = "XXX: { 3, 5, { 5 } }"

proc utf8_validate*(utf8: cstring; utf8_len: csize; allow_null: bool): bool

proc utf8_escape_for_json*(utf8: cstring; utf8_len: ssize_t): cstring

proc utf8_get_char*(utf8: cstring): unichar_t

proc utf8_next_char*(utf8: cstring): cstring

proc utf8_from_unichar*(unichar: unichar_t; utf8: array[6, char];
                             len: ptr uint32)

proc value_copy*(src: ptr value_t; dst: ptr value_t)

proc value_destroy*(value: ptr value_t)

#*
#  get_major_version:
#
#  Helper function to return the runtime major version of the library.
#

proc get_major_version*(): cint
#*
#  get_minor_version:
#
#  Helper function to return the runtime minor version of the library.
#

proc get_minor_version*(): cint
#*
#  get_micro_version:
#
#  Helper function to return the runtime micro version of the library.
#

proc get_micro_version*(): cint

proc writer_new*(buf: ptr ptr uint8; buflen: ptr csize; offset: csize;
                      realloc_func: realloc_func; realloc_func_ctx: pointer): ptr writer_t

proc writer_destroy*(writer: ptr writer_t)

proc writer_get_length*(writer: ptr writer_t): csize

proc writer_begin*(writer: ptr writer_t; bson: ptr ptr bson_t): bool

proc writer_end*(writer: ptr writer_t)

proc writer_rollback*(writer: ptr writer_t)


proc free*(mem: pointer)
{.pop.} # cdecl, importc, dynlib: BsonDll.}

when isMainModule or true:
    var b = new()
    var iter: iter_t
    #assert(not iter_init_find(iter.addr, b, "ohai"))
    assert append_bool(b, "hio", 2, false)
    assert(iter_init_find(iter.addr, b, "hi"))
    assert(not iter_init_find(iter.addr, b, "hio"))
    #assert(iter_find(iter.addr, "oha"))
