#!strongSpaces

when defined(windows):
    import winlean
elif defined(posix):
    import posix
else:
    {.error: "platform not supported".}

import bson_binding

when defined(windows):
  const
    BsonDll* = "libmongoc-1.0.dll"
elif defined(macosx):
  const
    BsonDll* = "libmongoc-1.0.dylib"
else:
  const
    BsonDll* = "libmongoc-1.0.so"

{.deadCodeElim: on.}
type
  gridfs_t* = pointer
  iovec_t* = pointer
  read_prefs_t* = pointer
  gridfs_file_t* = pointer
  gridfs_file_opt_t* = pointer
  gridfs_file_list_t* = pointer
  gridfs_file_page_t* = pointer
  host_list_t* = pointer
  matcher_t* = pointer
  opcode_t* {.size: sizeof(cint).} = enum
    OPCODE_REPLY = 1, OPCODE_MSG = 1000,
    OPCODE_UPDATE = 2001, OPCODE_INSERT = 2002,
    OPCODE_QUERY = 2004, OPCODE_GET_MORE = 2005,
    OPCODE_DELETE = 2006, OPCODE_KILL_CURSORS = 2007
  log_level_t* {.size: sizeof(cint).} = enum
    LOG_LEVEL_ERROR, LOG_LEVEL_CRITICAL, LOG_LEVEL_WARNING,
    LOG_LEVEL_MESSAGE, LOG_LEVEL_INFO, LOG_LEVEL_DEBUG,
    LOG_LEVEL_TRACE

#*
#  QueryFlags:
#  @QUERY_NONE: No query flags supplied.
#  @QUERY_TAILABLE_CURSOR: Cursor will not be closed when the last
#     data is retrieved. You can resume this cursor later.
#  @QUERY_SLAVE_OK: Allow query of replica slave.
#  @QUERY_OPLOG_REPLAY: Used internally by Mongo.
#  @QUERY_NO_CURSOR_TIMEOUT: The server normally times out idle
#     cursors after an inactivity period (10 minutes). This prevents that.
#  @QUERY_AWAIT_DATA: Use with %QUERY_TAILABLE_CURSOR. Block
#     rather than returning no data. After a period, time out.
#  @QUERY_EXHAUST: Stream the data down full blast in multiple
#     "more" packages. Faster when you are pulling a lot of data and
#     know you want to pull it all down.
#  @QUERY_PARTIAL: Get partial results from mongos if some shards
#     are down (instead of throwing an error).
#
#  #QueryFlags is used for querying a Mongo instance.
#

type
    QueryFlags* {.size: sizeof(cint).} = enum
        qfNone = 0,
        qfTailableCursor = 1 shl 1,
        qfSlaveOk = 1 shl 2,
        qfOplogReplay = 1 shl 3,
        qfNoCursorTimeout = 1 shl 4,
        qfAwaitData = 1 shl 5,
        qfExhaust = 1 shl 6,
        qfPartial = 1 shl 7


#*
#  reply_flags_t:
#  @REPLY_NONE: No flags set.
#  @REPLY_CURSOR_NOT_FOUND: Cursor was not found.
#  @REPLY_QUERY_FAILURE: Query failed, error document provided.
#  @REPLY_SHARD_CONFIG_STALE: Shard configuration is stale.
#  @REPLY_AWAIT_CAPABLE: Wait for data to be returned until timeout
#     has passed. Used with %QUERY_TAILABLE_CURSOR.
#
#  #reply_flags_t contains flags supplied by the Mongo server in reply
#  to a request.
#

type
  reply_flags_t* {.size: sizeof(cint).} = enum
    REPLY_NONE = 0, REPLY_CURSOR_NOT_FOUND = 1 shl 0,
    REPLY_QUERY_FAILURE = 1 shl 1,
    REPLY_SHARD_CONFIG_STALE = 1 shl 2,
    REPLY_AWAIT_CAPABLE = 1 shl 3


#*
#  UpdateFlags:
#  @UPDATE_NONE: No update flags specified.
#  @UPDATE_UPSERT: Perform an upsert.
#  @UPDATE_MULTI_UPDATE: Continue updating after first match.
#
#  #UpdateFlags is used when updating documents found in Mongo.
#

type
  UpdateFlags* {.size: sizeof(cint).} = enum
    ufNone = 0, ufUpsert = 1 shl 0,
    ufMultiUpdate = 1 shl 1




#*
#  log_func_t:
#  @log_level: The level of the log message.
#  @log_domain: The domain of the log message, such as "client".
#  @message: The message generated.
#  @user_data: User data provided to log_set_handler().
#
#  This function prototype can be used to set a custom log handler for the
#  libmongoc library. This is useful if you would like to show them in a
#  user interface or alternate storage.
#

type
  log_func_t* = proc (log_level: log_level_t; log_domain: cstring;
                             message: cstring; user_data: pointer)
type
  socket_t* = pointer
  stream_t* = pointer
  stream_file_t* = pointer
  stream_socket_t* = pointer
  bulk_operation_t* = pointer
  database_t* = pointer
  write_concern_t* = pointer
  uri_t* = pointer
  client_pool_t* = pointer
  collection_t* = pointer
  cursor_t* = pointer
  index_opt_t* = object
    is_initialized*: bool
    background*: bool
    unique*: bool
    name*: cstring
    drop_dups*: bool
    sparse*: bool
    expire_after_seconds*: int32
    v*: int32
    weights*: ptr bson_t
    default_language*: cstring
    language_override*: cstring
    padding*: array[8, pointer]
  error_domain_t* {.size: sizeof(cint).} = enum
    ERROR_CLIENT = 1, ERROR_STREAM, ERROR_PROTOCOL,
    ERROR_CURSOR, ERROR_QUERY, ERROR_INSERT,
    ERROR_SASL, ERROR_BSON, ERROR_MATCHER,
    ERROR_NAMESPACE, ERROR_COMMAND, ERROR_COLLECTION,
    ERROR_GRIDFS
  error_code_t* {.size: sizeof(cint).} = enum
    ERROR_STREAM_INVALID_TYPE = 1,
    ERROR_STREAM_INVALID_STATE,
    ERROR_STREAM_NAME_RESOLUTION,
    ERROR_STREAM_SOCKET,
    ERROR_STREAM_CONNECT,
    ERROR_STREAM_NOT_ESTABLISHED,
    ERROR_CLIENT_NOT_READY,
    ERROR_CLIENT_TOO_BIG,
    ERROR_CLIENT_TOO_SMALL,
    ERROR_CLIENT_GETNONCE,
    ERROR_CLIENT_AUTHENTICATE,
    ERROR_CLIENT_NO_ACCEPTABLE_PEER,
    ERROR_CLIENT_IN_EXHAUST,
    ERROR_PROTOCOL_INVALID_REPLY,
    ERROR_PROTOCOL_BAD_WIRE_VERSION,
    ERROR_CURSOR_INVALID_CURSOR,
    ERROR_QUERY_FAILURE,
    ERROR_BSON_INVALID,
    ERROR_MATCHER_INVALID,
    ERROR_NAMESPACE_INVALID,
    ERROR_COMMAND_INVALID_ARG,
    ERROR_COLLECTION_INSERT_FAILED,
    ERROR_GRIDFS_INVALID_FILENAME,
    ERROR_QUERY_COMMAND_NOT_FOUND = 59,
    ERROR_QUERY_NOT_TAILABLE = 13051

#*
#  RemoveFlags:
#  @rfNone: Specify no delete flags.
#  @rfSingleRemove: Only remove the first document matching the
#     document selector.
#
#  #RemoveFlags are used when performing a remove operation.
#

type
  RemoveFlags* {.size: sizeof(cint).} = enum
    rfNone = 0,
    rfSingleRemove = 1 shl 0


#*
#  InsertFlags:
#  @ifNone: Specify no insert flags.
#  @ifContinueOnError: Continue inserting documents from
#     the insertion set even if one fails.
#
#  #InsertFlags are used when performing an insert operation.
#

type
  InsertFlags* {.size: sizeof(cint).} = enum
    ifNone = 0,
    ifContinueOnError = 1 shl 0


#*
#  client_t:
#
#  The client_t structure maintains information about a connection to
#  a MongoDB server.
#

type
  client_t* = pointer

#*
#  stream_initiator_t:
#  @uri: The uri and options for the stream.
#  @host: The host and port (or UNIX domain socket path) to connect to.
#  @error: A location for an error.
#
#  Creates a new stream_t for the host and port. This can be used
#  by language bindings to create network transports other than those
#  built into libmongoc. An example of such would be the streams API
#  provided by PHP.
#
#  Returns: A newly allocated stream_t or NULL on failure.
#

type
  stream_initiator_t* = proc (uri: uri_t;
                                     host: host_list_t;
                                     user_data: pointer; error: ptr bson_binding.error_t): stream_t

{.push cdecl, importc: "mongoc_$1", dynlib: BsonDll.}


proc bulk_operation_destroy*(bulk: bulk_operation_t)
proc bulk_operation_execute*(bulk: bulk_operation_t;
                                    reply: ptr bson_t; error: ptr bson_binding.error_t): uint32
proc bulk_operation_insert*(bulk: bulk_operation_t;
                                   document: ptr bson_t)
proc bulk_operation_remove*(bulk: bulk_operation_t;
                                   selector: ptr bson_t)
proc bulk_operation_remove_one*(bulk: bulk_operation_t;
                                       selector: ptr bson_t)
proc bulk_operation_replace_one*(bulk: bulk_operation_t;
                                        selector: ptr bson_t;
                                        document: ptr bson_t; upsert: bool)
proc bulk_operation_update*(bulk: bulk_operation_t;
                                   selector: ptr bson_t; document: ptr bson_t;
                                   upsert: bool)
proc bulk_operation_update_one*(bulk: bulk_operation_t;
                                       selector: ptr bson_t;
                                       document: ptr bson_t; upsert: bool)
#
#  The following functions are really only useful by language bindings and
#  those wanting to replay a bulk operation to a number of clients or
#  collections.
#

proc bulk_operation_new*(ordered: bool): bulk_operation_t
proc bulk_operation_set_write_concern*(bulk: bulk_operation_t;
    write_concern: write_concern_t)
proc bulk_operation_set_database*(bulk: bulk_operation_t;
    database: cstring)
proc bulk_operation_set_collection*(bulk: bulk_operation_t;
    collection: cstring)
proc bulk_operation_set_client*(bulk: bulk_operation_t;
                                       client: pointer)
proc bulk_operation_set_hint*(bulk: bulk_operation_t;
                                     hint: uint32)
const
  NAMESPACE_MAX* = 128

proc client_new*(uri_string: cstring): client_t
proc client_new_from_uri*(uri: uri_t): client_t
proc client_get_uri*(client: client_t): uri_t
proc client_set_stream_initiator*(client: client_t;
    initiator: stream_initiator_t; user_data: pointer)
proc client_command*(client: client_t; db_name: cstring;
                            flags: QueryFlags; skip: uint32;
                            limit: uint32; batch_size: uint32;
                            query: ptr bson_t; fields: ptr bson_t;
                            read_prefs: read_prefs_t): cursor_t
proc client_command_simple*(client: client_t;
                                   db_name: cstring; command: ptr bson_t;
                                   read_prefs: read_prefs_t;
                                   reply: ptr bson_t; error: ptr bson_binding.error_t): bool
proc client_destroy*(client: client_t)
proc client_get_database*(client: client_t; name: cstring): database_t
proc client_get_gridfs*(client: client_t; db: cstring;
                               prefix: cstring; error: ptr bson_binding.error_t): gridfs_t
proc client_get_collection*(client: client_t; db: cstring;
                                   collection: cstring): collection_t
proc client_get_database_names*(client: client_t;
                                       error: ptr bson_binding.error_t): cstringArray
proc client_get_server_status*(client: client_t;
                                      read_prefs: read_prefs_t;
                                      reply: ptr bson_t; error: ptr bson_binding.error_t): bool
proc client_get_max_message_size*(client: client_t): int32
proc client_get_max_bson_size*(client: client_t): int32
proc client_get_write_concern*(client: client_t): write_concern_t
proc client_set_write_concern*(client: client_t;
                                      write_concern: write_concern_t)
proc client_get_read_prefs*(client: client_t): read_prefs_t
proc client_set_read_prefs*(client: client_t;
                                   read_prefs: read_prefs_t)
when defined(ENABLE_SSL):
  proc client_set_ssl_opts*(client: client_t;
                                   opts: ptr ssl_opt_t)
proc client_pool_new*(uri: uri_t): client_pool_t
proc client_pool_destroy*(pool: client_pool_t)
proc client_pool_pop*(pool: client_pool_t): client_t
proc client_pool_push*(pool: client_pool_t;
                              client: client_t)
proc client_pool_try_pop*(pool: client_pool_t): client_t
when defined(ENABLE_SSL):
  proc client_pool_set_ssl_opts*(pool: client_pool_t;
                                        opts: ptr ssl_opt_t)
proc collection_aggregate*(collection: collection_t;
                                  flags: QueryFlags;
                                  pipeline: ptr bson_t; options: ptr bson_t;
                                  read_prefs: read_prefs_t): cursor_t
proc collection_destroy*(collection: collection_t)
proc collection_command*(collection: collection_t;
                                flags: QueryFlags; skip: uint32;
                                limit: uint32; batch_size: uint32;
                                command: ptr bson_t; fields: ptr bson_t;
                                read_prefs: read_prefs_t): cursor_t
proc collection_command_simple*(collection: collection_t;
                                       command: ptr bson_t;
                                       read_prefs: read_prefs_t;
                                       reply: ptr bson_t;
                                       error: ptr bson_binding.error_t): bool
proc collection_count*(collection: collection_t;
                              flags: QueryFlags; query: ptr bson_t;
                              skip: int64; limit: int64;
                              read_prefs: read_prefs_t;
                              error: ptr bson_binding.error_t): int64
proc collection_drop*(collection: collection_t;
                             error: ptr bson_binding.error_t): bool
proc collection_drop_index*(collection: collection_t;
                                   index_name: cstring; error: ptr bson_binding.error_t): bool
proc collection_create_index*(collection: collection_t;
                                     keys: ptr bson_t;
                                     opt: ptr index_opt_t;
                                     error: ptr bson_binding.error_t): bool
proc collection_find*(collection: collection_t;
                             flags: QueryFlags; skip: uint32;
                             limit: uint32; batch_size: uint32;
                             query: ptr bson_t; fields: ptr bson_t;
                             read_prefs: read_prefs_t): cursor_t
proc collection_insert*(collection: collection_t;
                               flags: InsertFlags;
                               document: ptr bson_t;
                               write_concern: write_concern_t;
                               error: ptr bson_binding.error_t): bool
proc collection_update*(collection: collection_t;
                               flags: UpdateFlags;
                               selector: ptr bson_t; update: ptr bson_t;
                               write_concern: write_concern_t;
                               error: ptr bson_binding.error_t): bool
proc collection_save*(collection: collection_t;
                             document: ptr bson_t;
                             write_concern: write_concern_t;
                             error: ptr bson_binding.error_t): bool
proc collection_remove*(collection: collection_t;
                               flags: RemoveFlags;
                               selector: ptr bson_t;
                               write_concern: write_concern_t;
                               error: ptr bson_binding.error_t): bool
proc collection_rename*(collection: collection_t;
                               new_db: cstring; new_name: cstring;
                               drop_target_before_rename: bool;
                               error: ptr bson_binding.error_t): bool
proc collection_find_and_modify*(collection: collection_t;
                                        query: ptr bson_t; sort: ptr bson_t;
                                        update: ptr bson_t; fields: ptr bson_t;
                                        remove: bool; upsert: bool; new: bool;
                                        reply: ptr bson_t;
                                        error: ptr bson_binding.error_t): bool
proc collection_stats*(collection: collection_t;
                              options: ptr bson_t; reply: ptr bson_t;
                              error: ptr bson_binding.error_t): bool
proc collection_create_bulk_operation*(
    collection: collection_t; ordered: bool;
    write_concern: write_concern_t): bulk_operation_t
proc collection_get_read_prefs*(collection: collection_t): read_prefs_t
proc collection_set_read_prefs*(collection: collection_t;
                                       read_prefs: read_prefs_t)
proc collection_get_write_concern*(collection: collection_t): write_concern_t
proc collection_set_write_concern*(collection: collection_t;
    write_concern: write_concern_t)
proc collection_get_name*(collection: collection_t): cstring
proc collection_get_last_error*(collection: collection_t): ptr bson_t
proc collection_keys_to_index_string*(keys: ptr bson_t): cstring
proc collection_validate*(collection: collection_t;
                                 options: ptr bson_t; reply: ptr bson_t;
                                 error: ptr bson_binding.error_t): bool
proc cursor_clone*(cursor: cursor_t): cursor_t
proc cursor_destroy*(cursor: cursor_t)
proc cursor_more*(cursor: cursor_t): bool
proc cursor_next*(cursor: cursor_t; bson: ptr ptr bson_t): bool
proc cursor_error*(cursor: cursor_t; error: ptr bson_binding.error_t): bool
proc cursor_get_host*(cursor: cursor_t;
                             host: host_list_t)
proc cursor_is_alive*(cursor: cursor_t): bool
proc cursor_current*(cursor: cursor_t): ptr bson_t
proc cursor_get_hint*(cursor: cursor_t): uint32
proc database_get_name*(database: database_t): cstring
proc database_remove_user*(database: database_t;
                                  username: cstring; error: ptr bson_binding.error_t): bool
proc database_remove_all_users*(database: database_t;
                                       error: ptr bson_binding.error_t): bool
proc database_add_user*(database: database_t;
                               username: cstring; password: cstring;
                               roles: ptr bson_t; custom_data: ptr bson_t;
                               error: ptr bson_binding.error_t): bool
proc database_destroy*(database: database_t)
proc database_command*(database: database_t;
                              flags: QueryFlags; skip: uint32;
                              limit: uint32; batch_size: uint32;
                              command: ptr bson_t; fields: ptr bson_t;
                              read_prefs: read_prefs_t): cursor_t
proc database_command_simple*(database: database_t;
                                     command: ptr bson_t;
                                     read_prefs: read_prefs_t;
                                     reply: ptr bson_t; error: ptr bson_binding.error_t): bool
proc database_drop*(database: database_t;
                           error: ptr bson_binding.error_t): bool
proc database_has_collection*(database: database_t;
                                     name: cstring; error: ptr bson_binding.error_t): bool
proc database_create_collection*(database: database_t;
                                        name: cstring; options: ptr bson_t;
                                        error: ptr bson_binding.error_t): collection_t
proc database_get_read_prefs*(database: database_t): read_prefs_t
proc database_set_read_prefs*(database: database_t;
                                     read_prefs: read_prefs_t)
proc database_get_write_concern*(database: database_t): write_concern_t
proc database_set_write_concern*(database: database_t;
    write_concern: write_concern_t)
proc database_get_collection_names*(database: database_t;
    error: ptr bson_binding.error_t): cstringArray
proc database_get_collection*(database: database_t;
                                     name: cstring): collection_t
proc index_opt_get_default*(): ptr index_opt_t
proc index_opt_init*(opt: ptr index_opt_t)


const
  ERROR_PROTOCOL_ERROR = ERROR_QUERY_FAILURE
const
  INSERT_NO_VALIDATE* = (1 shl 31)
const
  UPDATE_NO_VALIDATE* = (1 shl 31)

proc gridfs_create_file_from_stream*(gridfs: gridfs_t;
    stream: stream_t; opt: gridfs_file_opt_t): gridfs_file_t
proc gridfs_create_file*(gridfs: gridfs_t;
                                opt: gridfs_file_opt_t): gridfs_file_t
proc gridfs_find*(gridfs: gridfs_t; query: ptr bson_t): gridfs_file_list_t
proc gridfs_find_one*(gridfs: gridfs_t; query: ptr bson_t;
                             error: ptr bson_binding.error_t): gridfs_file_t
proc gridfs_find_one_by_filename*(gridfs: gridfs_t;
    filename: cstring; error: ptr bson_binding.error_t): gridfs_file_t
proc gridfs_drop*(gridfs: gridfs_t; error: ptr bson_binding.error_t): bool
proc gridfs_destroy*(gridfs: gridfs_t)
proc gridfs_get_files*(gridfs: gridfs_t): collection_t
proc gridfs_get_chunks*(gridfs: gridfs_t): collection_t
proc gridfs_remove_by_filename*(gridfs: gridfs_t;
                                       filename: cstring;
                                       error: ptr bson_binding.error_t): bool

proc gridfs_file_get_length*(file: gridfs_file_t): int64
proc gridfs_file_get_chunk_size*(file: gridfs_file_t): int32
proc gridfs_file_get_upload_date*(file: gridfs_file_t): int64
proc gridfs_file_writev*(file: gridfs_file_t;
                                iov: iovec_t; iovcnt: csize;
                                timeout_msec: uint32): ssize_t
proc gridfs_file_readv*(file: gridfs_file_t;
                               iov: iovec_t; iovcnt: csize;
                               min_bytes: csize; timeout_msec: uint32): ssize_t
proc gridfs_file_seek*(file: gridfs_file_t; delta: uint64;
                              whence: cint): cint
proc gridfs_file_tell*(file: gridfs_file_t): uint64
proc gridfs_file_save*(file: gridfs_file_t): bool
proc gridfs_file_destroy*(file: gridfs_file_t)
proc gridfs_file_error*(file: gridfs_file_t;
                               error: ptr bson_binding.error_t): bool
proc gridfs_file_remove*(file: gridfs_file_t;
                                error: ptr bson_binding.error_t): bool
proc gridfs_file_list_next*(list: gridfs_file_list_t): gridfs_file_t
proc gridfs_file_list_destroy*(list: gridfs_file_list_t)
proc gridfs_file_list_error*(list: gridfs_file_list_t;
                                    error: ptr bson_binding.error_t): bool
proc init*()
proc cleanup*()

proc matcher_new*(query: ptr bson_t; error: ptr bson_binding.error_t): matcher_t
proc matcher_match*(matcher: matcher_t; document: ptr bson_t): bool
proc matcher_destroy*(matcher: matcher_t)

#*
#  log_set_handler:
#  @log_func: A function to handle log messages.
#  @user_data: User data for @log_func.
#
#  Sets the function to be called to handle logging.
#

proc log_set_handler*(log_func: log_func_t; user_data: pointer)
#*
#  log:
#  @log_level: The log level.
#  @log_domain: The log domain (such as "client").
#  @format: The format string for the log message.
#
#  Logs a message using the currently configured logger.
#
#  This method will hold a logging lock to prevent concurrent calls to the
#  logging infrastructure. It is important that your configured log function
#  does not re-enter the logging system or deadlock will occur.
#
#

proc log*(log_level: log_level_t; log_domain: cstring;
                 format: cstring) {.varargs.}
proc log_default_handler*(log_level: log_level_t;
                                 log_domain: cstring; message: cstring;
                                 user_data: pointer)
#*
#  log_level_str:
#  @log_level: The log level.
#
#  Returns: The string representation of log_level
#

proc log_level_str*(log_level: log_level_t): cstring

proc socket_accept*(sock: socket_t; expire_at: int64): socket_t
proc socket_bind*(sock: socket_t; `addr`: ptr SockAddr;
                         addrlen: SockLen): cint
proc socket_close*(socket: socket_t): cint
proc socket_connect*(sock: socket_t; `addr`: ptr SockAddr;
                            addrlen: SockLen; expire_at: int64): cint
proc socket_getnameinfo*(sock: socket_t): cstring
proc socket_destroy*(sock: socket_t)
proc socket_errno*(sock: socket_t): cint
proc socket_getsockname*(sock: socket_t; `addr`: ptr SockAddr;
                                addrlen: ptr SockLen): cint
proc socket_listen*(sock: socket_t; backlog: cuint): cint
proc socket_new*(domain: cint; typ: cint; protocol: cint): socket_t
proc socket_recv*(sock: socket_t; buf: pointer; buflen: csize;
                         flags: cint; expire_at: int64): ssize_t
proc socket_setsockopt*(sock: socket_t; level: cint;
                               optname: cint; optval: pointer; optlen: SockLen): cint
proc socket_send*(sock: socket_t; buf: pointer; buflen: csize;
                         expire_at: int64): ssize_t
proc socket_sendv*(sock: socket_t; iov: iovec_t;
                          iovcnt: csize; expire_at: int64): ssize_t

proc stream_get_base_stream*(stream: stream_t): stream_t
proc stream_close*(stream: stream_t): cint
proc stream_destroy*(stream: stream_t)
proc stream_flush*(stream: stream_t): cint
proc stream_writev*(stream: stream_t; iov: iovec_t;
                           iovcnt: csize; timeout_msec: int32): ssize_t
proc stream_readv*(stream: stream_t; iov: iovec_t;
                          iovcnt: csize; min_bytes: csize; timeout_msec: int32): ssize_t
proc stream_read*(stream: stream_t; buf: pointer;
                         count: csize; min_bytes: csize; timeout_msec: int32): ssize_t
proc stream_setsockopt*(stream: stream_t; level: cint;
                               optname: cint; optval: pointer; optlen: SockLen): cint
proc stream_buffered_new*(base_stream: stream_t;
                                 buffer_size: csize): stream_t
proc stream_file_new*(fd: cint): stream_t
proc stream_file_new_for_path*(path: cstring; flags: cint; mode: cint): stream_t
proc stream_file_get_fd*(stream: stream_file_t): cint
proc stream_gridfs_new*(file: gridfs_file_t): stream_t

proc stream_socket_new*(socket: socket_t): stream_t
proc stream_socket_get_socket*(stream: stream_socket_t): socket_t

proc uri_copy*(uri: uri_t): uri_t
proc uri_destroy*(uri: uri_t)
proc uri_new*(uri_string: cstring): uri_t
proc uri_new_for_host_port*(hostname: cstring; port: uint16): uri_t
proc uri_get_hosts*(uri: uri_t): host_list_t
proc uri_get_database*(uri: uri_t): cstring
proc uri_get_options*(uri: uri_t): ptr bson_t
proc uri_get_password*(uri: uri_t): cstring
proc uri_get_read_prefs*(uri: uri_t): ptr bson_t
proc uri_get_replica_set*(uri: uri_t): cstring
proc uri_get_string*(uri: uri_t): cstring
proc uri_get_username*(uri: uri_t): cstring
proc uri_get_auth_source*(uri: uri_t): cstring
proc uri_get_auth_mechanism*(uri: uri_t): cstring
proc uri_get_ssl*(uri: uri_t): bool
proc uri_unescape*(escaped_string: cstring): cstring
proc uri_get_write_concern*(uri: uri_t): write_concern_t
const
  WRITE_CONCERN_W_UNACKNOWLEDGED* = 0
  WRITE_CONCERN_W_ERRORS_IGNORED* = - 1
  WRITE_CONCERN_W_DEFAULT* = - 2
  WRITE_CONCERN_W_MAJORITY* = - 3
  WRITE_CONCERN_W_TAG* = - 4

proc write_concern_new*(): write_concern_t
proc write_concern_copy*(write_concern: write_concern_t): write_concern_t
proc write_concern_destroy*(write_concern: write_concern_t)
proc write_concern_get_fsync*(write_concern: write_concern_t): bool
proc write_concern_set_fsync*(write_concern: write_concern_t;
                                    fsync: bool)
proc write_concern_get_journal*(write_concern: write_concern_t): bool
proc write_concern_set_journal*(write_concern: write_concern_t;
                                       journal: bool)
proc write_concern_get_w*(write_concern: write_concern_t): int32
proc write_concern_set_w*(write_concern: write_concern_t;
                                 w: int32)
proc write_concern_get_wtag*(write_concern: write_concern_t): cstring
proc write_concern_set_wtag*(write_concern: write_concern_t;
                                    tag: cstring)
proc write_concern_get_wtimeout*(write_concern: write_concern_t): int32
proc write_concern_set_wtimeout*(write_concern: write_concern_t;
                                        wtimeout_msec: int32)
proc write_concern_get_wmajority*(
    write_concern: write_concern_t): bool
proc write_concern_set_wmajority*(
    write_concern: write_concern_t; wtimeout_msec: int32)

{.pop.} # importc, dynlib: BsonDll
