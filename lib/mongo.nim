import bson

{.deadCodeElim: on.}

when defined(windows):
  const
    mongodll* = "mongoc-1.0.dll"
elif defined(macosx):
  const
    mongodll* = "libmongoc-1.0.dylib"
else:
  const
    mongodll* = "libmongoc-1.0.so"

when defined(windows):
  import winlean
elif defined(posix):
  import posix

const
  MONGOC_NAMESPACE_MAX* = 128
const
  MONGOC_STREAM_SOCKET* = 1
  MONGOC_STREAM_FILE* = 2
  MONGOC_STREAM_BUFFERED* = 3
  MONGOC_STREAM_GRIDFS* = 4
  MONGOC_STREAM_TLS* = 5
const
  MONGOC_CLUSTER_MAX_NODES* = 12
  MONGOC_CLUSTER_PING_NUM_SAMPLES* = 5
const
  MONGOC_ERROR_PROTOCOL_ERROR = 17 # part of TErrorCode
  MONGOC_INSERT_NO_VALIDATE* = (1 shl 31)
type
  TClientPool* = distinct pointer
  TGridFsFileList* = distinct pointer
  TLogLevel* {.size: sizeof(cint).} = enum
    MONGOC_LOG_LEVEL_ERROR, MONGOC_LOG_LEVEL_CRITICAL, MONGOC_LOG_LEVEL_WARNING,
    MONGOC_LOG_LEVEL_MESSAGE, MONGOC_LOG_LEVEL_INFO, MONGOC_LOG_LEVEL_DEBUG,
    MONGOC_LOG_LEVEL_TRACE
  TLog_func* = proc (log_level: TLogLevel; log_domain: cstring;
                             message: cstring; user_data: pointer)
  TClusterMode* {.size: sizeof(cint).} = enum
    MONGOC_CLUSTER_DIRECT, MONGOC_CLUSTER_REPLICA_SET,
    MONGOC_CLUSTER_SHARDED_CLUSTER
  TClusterState* {.size: sizeof(cint).} = enum
    MONGOC_CLUSTER_STATE_BORN = 0, MONGOC_CLUSTER_STATE_HEALTHY = 1,
    MONGOC_CLUSTER_STATE_DEAD = 2, MONGOC_CLUSTER_STATE_UNHEALTHY = (
        MONGOC_CLUSTER_STATE_DEAD.cint or MONGOC_CLUSTER_STATE_HEALTHY.cint)
  TOpcode* {.size: sizeof(cint).} = enum
    MONGOC_OPCODE_REPLY = 1, MONGOC_OPCODE_MSG = 1000,
    MONGOC_OPCODE_UPDATE = 2001, MONGOC_OPCODE_INSERT = 2002,
    MONGOC_OPCODE_QUERY = 2004, MONGOC_OPCODE_GET_MORE = 2005,
    MONGOC_OPCODE_REMOVE = 2006, MONGOC_OPCODE_KILL_CURSORS = 2007
  TQueue* = distinct pointer
  TQueueItem* = distinct pointer
  TSslOpt* = distinct pointer
  TStreamSocket* = distinct pointer
  TStream_file* = distinct pointer
  TSocket* = distinct pointer
  TGridfs_file_page* = distinct pointer
  TClient* = distinct pointer
  TStream_initiator* = proc (uri: TUri;
                             host: THostList;
                             user_data: pointer;
                             error: ptr bson.TError): TStream
  cssize* = int
  TErrorDomain* {.size: sizeof(cint).} = enum
    edCLIENT = 1,
    edSTREAM,
    edPROTOCOL,
    edCURSOR,
    edQUERY,
    edINSERT,
    edSASL,
    edBSON,
    edMATCHER,
    edNAMESPACE,
    edCOMMAND,
    edCOLLECTION
  TErrorCode* {.size: sizeof(cint).} = enum
    ecSTREAM_INVALID_TYPE = 1,
    ecSTREAM_INVALID_STATE,
    ecSTREAM_NAME_RESOLUTION,
    ecSTREAM_SOCKET,
    ecSTREAM_CONNECT,
    ecSTREAM_NOT_ESTABLISHED,
    ecCLIENT_NOT_READY,
    ecCLIENT_TOO_BIG,
    ecCLIENT_TOO_SMALL,
    ecCLIENT_GETNONCE,
    ecCLIENT_AUTHENTICATE,
    ecCLIENT_NO_ACCEPTABLE_PEER,
    ecCLIENT_IN_EXHAUST,
    ecPROTOCOL_INVALID_REPLY,
    ecPROTOCOL_BAD_WIRE_VERSION,
    ecCURSOR_INVALID_CURSOR,
    ecQUERY_FAILURE,
    ecBSON_INVALID,
    ecMATCHER_INVALID,
    ecNAMESPACE_INVALID,
    ecCOMMAND_INVALID_ARG,
    ecCOLLECTION_INSERT_FAILED,
    ecQUERY_COMMAND_NOT_FOUND = 59,
    ecQUERY_NOT_TAILABLE = 13051,
  TArray* = distinct pointer
  TBuffer* = distinct pointer
  TUri* = distinct pointer
  TRead_mode* = distinct pointer
  THostList* = distinct pointer
  TStream* = distinct pointer
  TReadPrefs* = distinct pointer
  TCursor* = distinct pointer
  TDatabase* = distinct pointer
  TGridfs* = distinct pointer
  TCollection* = distinct pointer
  TWriteConcern* = distinct pointer
  TIovec* = distinct pointer
  TIndex_opt* {.pure, final.} = object
    is_initialized*: bool
    background*: bool
    unique*: bool
    name*: cstring
    drop_dups*: bool
    sparse*: bool
    expire_after_seconds*: int32
    v*: int32
    weights*: ptr TBson
    default_language*: cstring
    language_override*: cstring
    padding*: array[8, pointer]
  TBulk_operation* = distinct pointer
  TRemoveFlags* {.size: sizeof(cint).} = enum
    rfRemoveOne = 1 shl 0
  TInsertFlags* {.size: sizeof(cint).} = enum
    ifContinueOnErr = 1 shl 0
  TQueryFlags* {.size: sizeof(cint).} = enum
    qfTailableCursor = 1 shl 1,
    qfSlaveOk = 1 shl 2,
    qfOplogReplay = 1 shl 3,
    qfNoCursorTimeout = 1 shl 4,
    qfAwaitData = 1 shl 5,
    qfExhaust = 1 shl 6,
    qfQueryPartial = 1 shl 7
  TReply_flags* {.size: sizeof(cint).} = enum
    rfCursorNotFound = 1 shl 0,
    rfQueryFailure = 1 shl 1,
    rfShardConfigStale = 1 shl 2,
    rfAwaitCapable = 1 shl 3
  TUpdate_flags* {.size: sizeof(cint).} = enum
    ufUpsert = 1 shl 0,
    ufMultiUpdate = 1 shl 1
  TGridfs_file* = distinct pointer
  TGridfs_file_opt* = distinct pointer
  TCursor_interface* = distinct pointer

{.push cdecl, importc: "mongoc_$1", dynlib: mongodll.}
proc bulk_operation_destroy*(bulk: TBulk_operation)
proc bulk_operation_execute*(bulk: TBulk_operation;
                                    reply: ptr TBson; error: ptr bson.TError): bool
proc bulk_operation_remove*(bulk: TBulk_operation;
                                   selector: ptr TBson)
proc bulk_operation_remove_one*(bulk: TBulk_operation;
                                       selector: ptr TBson)
proc bulk_operation_insert*(bulk: TBulk_operation;
                                   document: ptr TBson)
proc bulk_operation_replace_one*(bulk: TBulk_operation;
                                        selector: ptr TBson;
                                        document: ptr TBson; upsert: bool)
proc bulk_operation_update*(bulk: TBulk_operation;
                                   selector: ptr TBson; document: ptr TBson;
                                   upsert: bool)
proc bulk_operation_update_one*(bulk: TBulk_operation;
                                       selector: ptr TBson;
                                       document: ptr TBson; upsert: bool)
proc client_new*(uri_string: cstring): TClient
proc client_new_from_uri*(uri: TUri): TClient
proc client_get_uri*(client: TClient): TUri
proc client_set_stream_initiator*(client: TClient;
    initiator: TStream_initiator; user_data: pointer)
proc client_command*(client: TClient; db_name: cstring;
                            flags: TQueryFlags; skip: uint32;
                            limit: uint32; batch_size: uint32;
                            query: ptr TBson; fields: ptr TBson;
                            read_prefs: TReadPrefs): TCursor
proc client_command_simple*(client: TClient;
                                   db_name: cstring; command: ptr TBson;
                                   read_prefs: TReadPrefs;
                                   reply: ptr TBson; error: ptr bson.TError): bool
proc client_destroy*(client: TClient)
proc client_get_database*(client: TClient; name: cstring): TDatabase
proc client_get_gridfs*(client: TClient; db: cstring;
                               prefix: cstring; error: ptr bson.TError): TGridfs
proc client_get_collection*(client: TClient; db: cstring;
                                   collection: cstring): TCollection
proc client_get_database_names*(client: TClient;
                                       error: ptr bson.TError): cstringArray
proc client_get_server_status*(client: TClient;
                                      read_prefs: TReadPrefs;
                                      reply: ptr TBson; error: ptr bson.TError): bool
proc client_get_max_message_size*(client: TClient): int32
proc client_get_max_bson_size*(client: TClient): int32
proc client_get_write_concern*(client: TClient): TWriteConcern
proc client_set_write_concern*(client: TClient;
                                      write_concern: TWriteConcern)
proc client_get_read_prefs*(client: TClient): TReadPrefs
proc client_set_read_prefs*(client: TClient;
                                   read_prefs: TReadPrefs)
proc client_set_ssl_opts*(client: TClient;
                                   opts: TSslOpt)
proc client_pool_new*(uri: TUri): TClientPool
proc client_pool_destroy*(pool: TClientPool)
proc client_pool_pop*(pool: TClientPool): TClient
proc client_pool_push*(pool: TClientPool;
                              client: TClient)
proc TClientPoolry_pop*(pool: TClientPool): TClient
proc collection_aggregate*(collection: TCollection;
                                  flags: TQueryFlags;
                                  pipeline: ptr TBson; options: ptr TBson;
                                  read_prefs: TReadPrefs): TCursor
proc collection_destroy*(collection: TCollection)
proc collection_command*(collection: TCollection;
                                flags: TQueryFlags; skip: uint32;
                                limit: uint32; batch_size: uint32;
                                command: ptr TBson; fields: ptr TBson;
                                read_prefs: TReadPrefs): TCursor
proc collection_command_simple*(collection: TCollection;
                                       command: ptr TBson;
                                       read_prefs: TReadPrefs;
                                       reply: ptr TBson;
                                       error: ptr bson.TError): bool
proc collection_count*(collection: TCollection;
                              flags: TQueryFlags; query: ptr TBson;
                              skip: int64; limit: int64;
                              read_prefs: TReadPrefs;
                              error: ptr bson.TError): int64
proc collection_drop*(collection: TCollection;
                             error: ptr bson.TError): bool
proc collection_drop_index*(collection: TCollection;
                                   index_name: cstring; error: ptr bson.TError): bool
proc collection_create_index*(collection: TCollection;
                                     keys: ptr TBson;
                                     opt: ptr TIndex_opt;
                                     error: ptr bson.TError): bool
proc collection_ensure_index*(collection: TCollection;
                                     keys: ptr TBson;
                                     opt: ptr TIndex_opt;
                                     error: ptr bson.TError): bool
proc collection_find*(collection: TCollection;
                             flags: TQueryFlags; skip: uint32;
                             limit: uint32; batch_size: uint32;
                             query: ptr TBson; fields: ptr TBson;
                             read_prefs: TReadPrefs): TCursor
proc collection_insert*(collection: TCollection;
                               flags: TInsertFlags;
                               document: ptr TBson;
                               write_concern: TWriteConcern;
                               error: ptr bson.TError): bool
proc collection_insert_bulk*(collection: TCollection;
                                    flags: TInsertFlags;
                                    documents: ptr TBson;
                                    n_documents: uint32;
                                    write_concern: TWriteConcern;
                                    error: ptr bson.TError): bool
proc collection_update*(collection: TCollection;
                               flags: TUpdate_flags;
                               selector: ptr TBson; update: ptr TBson;
                               write_concern: TWriteConcern;
                               error: ptr bson.TError): bool
proc collection_remove*(collection: TCollection;
                               flags: TRemoveFlags;
                               selector: ptr TBson;
                               write_concern: TWriteConcern;
                               error: ptr bson.TError): bool
proc collection_save*(collection: TCollection;
                             document: ptr TBson;
                             write_concern: TWriteConcern;
                             error: ptr bson.TError): bool
proc collection_rename*(collection: TCollection;
                               new_db: cstring; new_name: cstring;
                               drop_target_before_rename: bool;
                               error: ptr bson.TError): bool
proc collection_find_and_modify*(collection: TCollection;
                                        query: ptr TBson; sort: ptr TBson;
                                        update: ptr TBson; fields: ptr TBson;
                                        remove: bool; upsert: bool; new: bool;
                                        reply: ptr TBson;
                                        error: ptr bson.TError): bool
proc collection_stats*(collection: TCollection;
                              options: ptr TBson; reply: ptr TBson;
                              error: ptr bson.TError): bool
proc collection_create_bulk_operation*(
    collection: TCollection; ordered: bool;
    write_concern: TWriteConcern): TBulk_operation
proc collection_get_read_prefs*(collection: TCollection): TReadPrefs
proc collection_set_read_prefs*(collection: TCollection;
                                       read_prefs: TReadPrefs)
proc collection_get_write_concern*(collection: TCollection): TWriteConcern
proc collection_set_write_concern*(collection: TCollection;
    write_concern: TWriteConcern)
proc collection_get_name*(collection: TCollection): cstring
proc collection_get_last_error*(collection: TCollection): ptr TBson
proc collection_keys_to_index_string*(keys: ptr TBson): cstring
proc collection_validate*(collection: TCollection;
                                 options: ptr TBson; reply: ptr TBson;
                                 error: ptr bson.TError): bool
proc cursor_clone*(cursor: TCursor): TCursor
proc cursor_destroy*(cursor: TCursor)
proc cursor_more*(cursor: TCursor): bool
proc cursor_next*(cursor: TCursor; bson: ptr ptr TBson): bool
proc cursor_error*(cursor: TCursor; error: ptr bson.TError): bool
proc cursor_get_host*(cursor: TCursor;
                             host: THostList)
proc cursor_is_alive*(cursor: TCursor): bool
proc cursor_current*(cursor: TCursor): ptr TBson
proc database_get_name*(database: TDatabase): cstring
proc database_remove_user*(database: TDatabase;
                                  username: cstring; error: ptr bson.TError): bool
proc database_remove_all_users*(database: TDatabase;
                                       error: ptr bson.TError): bool
proc database_add_user*(database: TDatabase;
                               username: cstring; password: cstring;
                               roles: ptr TBson; custom_data: ptr TBson;
                               error: ptr bson.TError): bool
proc database_destroy*(database: TDatabase)
proc database_command*(database: TDatabase;
                              flags: TQueryFlags; skip: uint32;
                              limit: uint32; batch_size: uint32;
                              command: ptr TBson; fields: ptr TBson;
                              read_prefs: TReadPrefs): TCursor
proc database_command_simple*(database: TDatabase;
                                     command: ptr TBson;
                                     read_prefs: TReadPrefs;
                                     reply: ptr TBson; error: ptr bson.TError): bool
proc database_drop*(database: TDatabase;
                           error: ptr bson.TError): bool
proc database_has_collection*(database: TDatabase;
                                     name: cstring; error: ptr bson.TError): bool
proc database_create_collection*(database: TDatabase;
                                        name: cstring; options: ptr TBson;
                                        error: ptr bson.TError): TCollection
proc database_get_read_prefs*(database: TDatabase): TReadPrefs
proc database_set_read_prefs*(database: TDatabase;
                                     read_prefs: TReadPrefs)
proc database_get_write_concern*(database: TDatabase): TWriteConcern
proc database_set_write_concern*(database: TDatabase;
    write_concern: TWriteConcern)
proc database_get_collection_names*(database: TDatabase;
    error: ptr bson.TError): cstringArray
proc database_get_collection*(database: TDatabase;
                                     name: cstring): TCollection
proc gridfs_file_get_length*(file: TGridfs_file): int64
proc gridfs_file_get_chunk_size*(file: TGridfs_file): int32
proc gridfs_file_get_upload_date*(file: TGridfs_file): int64
proc gridfs_file_writev*(file: TGridfs_file;
                                iov: TIovec; iovcnt: csize;
                                timeout_msec: uint32): cssize
proc gridfs_file_readv*(file: TGridfs_file;
                               iov: TIovec; iovcnt: csize;
                               min_bytes: csize; timeout_msec: uint32): cssize
proc gridfs_file_seek*(file: TGridfs_file; delta: uint64;
                              whence: cint): cint
proc gridfs_file_tell*(file: TGridfs_file): uint64
proc gridfs_file_save*(file: TGridfs_file): bool
proc gridfs_file_destroy*(file: TGridfs_file)
proc gridfs_file_error*(file: TGridfs_file;
                               error: ptr bson.TError): bool
proc gridfs_file_list_next*(list: TGridFsFileList): TGridfs_file
proc gridfs_file_list_destroy*(list: TGridFsFileList)
proc gridfs_file_list_error*(list: TGridFsFileList;
                                    error: ptr bson.TError): bool
proc gridfs_create_file_from_stream*(gridfs: TGridfs;
    stream: TStream; opt: TGridfs_file_opt): TGridfs_file
proc gridfs_create_file*(gridfs: TGridfs;
                                opt: TGridfs_file_opt): TGridfs_file
proc gridfs_find*(gridfs: TGridfs; query: ptr TBson): TGridFsFileList
proc gridfs_find_one*(gridfs: TGridfs; query: ptr TBson;
                             error: ptr bson.TError): TGridfs_file
proc gridfs_find_one_by_filename*(gridfs: TGridfs;
    filename: cstring; error: ptr bson.TError): TGridfs_file
proc gridfs_drop*(gridfs: TGridfs; error: ptr bson.TError): bool
proc gridfs_destroy*(gridfs: TGridfs)
proc gridfs_get_files*(gridfs: TGridfs): TCollection
proc gridfs_get_chunks*(gridfs: TGridfs): TCollection
proc index_opt_get_default*(): ptr TIndex_opt
proc index_opt_init*(opt: ptr TIndex_opt)
proc init*()
proc cleanup*()
proc log_set_handler*(log_func: TLog_func; user_data: pointer)
proc log*(log_level: TLogLevel; log_domain: cstring;
                 format: cstring)
proc log_default_handler*(log_level: TLogLevel;
                                 log_domain: cstring; message: cstring;
                                 user_data: pointer)
proc log_level_str*(log_level: TLogLevel): cstring
proc read_prefs_new*(read_mode: TRead_mode): TReadPrefs
proc read_prefs_copy*(read_prefs: TReadPrefs): TReadPrefs
proc read_prefs_destroy*(read_prefs: TReadPrefs)
proc read_prefs_get_mode*(read_prefs: TReadPrefs): TRead_mode
proc read_prefs_set_mode*(read_prefs: TReadPrefs;
                                 mode: TRead_mode)
proc read_prefs_get_tags*(read_prefs: TReadPrefs): ptr TBson
proc read_prefs_set_tags*(read_prefs: TReadPrefs;
                                 tags: ptr TBson)
proc read_prefs_add_tag*(read_prefs: TReadPrefs;
                                tag: ptr TBson)
proc read_prefs_is_valid*(read_prefs: TReadPrefs): bool
proc socket_accept*(sock: TSocket; expire_at: int64): TSocket
proc socket_bind*(sock: TSocket; `addr`: TSockAddr;
                         addrlen: TSocklen): cint
proc socket_close*(socket: TSocket): cint
proc socket_connect*(sock: TSocket; `addr`: TSockAddr;
                            addrlen: TSocklen; expire_at: int64): cint
proc socket_getnameinfo*(sock: TSocket): cstring
proc socket_destroy*(sock: TSocket)
proc socket_errno*(sock: TSocket): cint
proc socket_getsockname*(sock: TSocket; `addr`: TSockAddr;
                                addrlen: TSocklen): cint
proc socket_listen*(sock: TSocket; backlog: cuint): cint
proc socket_new*(domain: cint; `type`: cint; protocol: cint): TSocket
proc socket_recv*(sock: TSocket; buf: pointer;
                         buflen: csize; flags: cint; expire_at: int64): cssize
proc socket_setsockopt*(sock: TSocket; level: cint;
                               optname: cint; optval: pointer; optlen: TSocklen): cint
proc socket_send*(sock: TSocket; buf: pointer;
                         buflen: csize; expire_at: int64): cssize
proc socket_sendv*(sock: TSocket; iov: TIovec;
                          iovcnt: csize; expire_at: int64): cssize
proc ssl_opt_get_default*(): TSslOpt
proc stream_buffered_new*(base_stream: TStream;
                                 buffer_size: csize): TStream
proc stream_file_new*(fd: cint): TStream
proc stream_file_new_for_path*(path: cstring; flags: cint; mode: cint): TStream
proc stream_file_get_fd*(stream: TStream_file): cint
proc stream_gridfs_new*(file: TGridfs_file): TStream
proc stream_get_base_stream*(stream: TStream): TStream
proc stream_close*(stream: TStream): cint
proc stream_cork*(stream: TStream): cint
proc stream_uncork*(stream: TStream): cint
proc stream_destroy*(stream: TStream)
proc stream_flush*(stream: TStream): cint
proc stream_writev*(stream: TStream; iov: TIovec;
                           iovcnt: csize; timeout_msec: int32): cssize
proc stream_readv*(stream: TStream; iov: TIovec;
                          iovcnt: csize; min_bytes: csize;
                          timeout_msec: int32): cssize
proc stream_read*(stream: TStream; buf: pointer;
                         count: csize; min_bytes: csize; timeout_msec: int32): cssize
proc stream_setsockopt*(stream: TStream; level: cint;
                               optname: cint; optval: pointer; optlen: TSocklen): cint
proc stream_socket_new*(socket: TSocket): TStream
proc stream_socket_get_socket*(stream: TStreamSocket): TSocket
proc TStreamls_do_handshake*(stream: TStream;
                                     timeout_msec: int32): bool
proc TStreamls_check_cert*(stream: TStream; host: cstring): bool
proc TStreamls_new*(base_stream: TStream;
                            opt: TSslOpt; client: cint): TStream
proc uri_copy*(uri: TUri): TUri
proc uri_destroy*(uri: TUri)
proc uri_new*(uri_string: cstring): TUri
proc uri_new_for_host_port*(hostname: cstring; port: uint16): TUri
proc uri_get_hosts*(uri: TUri): THostList
proc uri_get_database*(uri: TUri): cstring
proc uri_get_options*(uri: TUri): ptr TBson
proc uri_get_password*(uri: TUri): cstring
proc uri_get_read_prefs*(uri: TUri): ptr TBson
proc uri_get_replica_set*(uri: TUri): cstring
proc uri_get_string*(uri: TUri): cstring
proc uri_get_username*(uri: TUri): cstring
proc uri_get_auth_source*(uri: TUri): cstring
proc uri_get_auth_mechanism*(uri: TUri): cstring
proc uri_get_ssl*(uri: TUri): bool
proc uri_unescape*(escaped_string: cstring): cstring
proc uri_get_write_concern*(uri: TUri): TWriteConcern
proc write_concern_new*(): TWriteConcern
proc write_concern_copy*(write_concern: TWriteConcern): TWriteConcern
proc write_concern_destroy*(write_concern: TWriteConcern)
proc write_concern_get_fsync*(write_concern: TWriteConcern): bool
proc write_concern_set_fsync*(write_concern: TWriteConcern;
                                     fsync: bool)
proc write_concern_get_journal*(write_concern: TWriteConcern): bool
proc write_concern_set_journal*(write_concern: TWriteConcern;
                                       journal: bool)
proc write_concern_get_w*(write_concern: TWriteConcern): int32
proc write_concern_set_w*(write_concern: TWriteConcern;
                                 w: int32)
proc write_concern_get_wtag*(write_concern: TWriteConcern): cstring
proc write_concern_set_wtag*(write_concern: TWriteConcern;
                                    tag: cstring)
proc write_concern_get_wtimeout*(write_concern: TWriteConcern): int32
proc write_concern_set_wtimeout*(write_concern: TWriteConcern;
                                        wtimeout_msec: int32)
proc write_concern_get_wmajority*(
    write_concern: TWriteConcern): bool
proc write_concern_set_wmajority*(
    write_concern: TWriteConcern; wtimeout_msec: int32)
{.pop.} # cdecl, importc, dynlib: mongodll
