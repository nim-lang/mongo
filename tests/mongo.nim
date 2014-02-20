import sequtils, times, oids, unittest
import db_mongo2 as db_mongo

suite "MongoDB":
  test "BSON construction":
    var
      arr2 = ["o", "p", "q"]
      bson = %%{
        "int32": %1i32,
        "int64": %2i64,
        "obj": %{
          "field1": %6i32,
          "field2": %7i64,
          "field3": %"field3val"
        },
        "arr1": %[
          %12i32,
          %13i64,
          %"arr1str"
        ],
        "arr2": %arr2
      }

    test "BSON iteration":
      for x in bson:
        case x.k:
        of "int32":
          check:
            x.v.kind == bkInt32
            x.v.int32Val == 1
        of "int64":
          check:
            x.v.kind == bkInt64
            x.v.int64Val == 2
        of "obj":
          for y in bson.subItems:
            case y.k:
            of "field1":
              check:
                y.v.kind == bkInt32
                y.v.int32Val == 6
            of "field2":
              check:
                y.v.kind == bkInt64
                y.v.int64Val == 7
            of "field3":
              check:
                y.v.kind == bkStr
                y.v.strVal == "field3val"
            else:
              check false
        of "arr1":
          for y in bson.subItems:
            case y.k:
            of "0":
              check:
                y.v.kind == bkInt32
                y.v.int32Val == 12
            of "1":
              check:
                y.v.kind == bkInt64
                y.v.int64Val == 13
            of "2":
              check:
                y.v.kind == bkStr
                y.v.strVal == "arr1str"
            else:
              check false
        of "arr2":
          for y in bson.subItems:
            case y.k:
            of "0":
              check:
                y.v.kind == bkStr
                y.v.strVal == "o"
            of "1":
              check:
                y.v.kind == bkStr
                y.v.strVal == "p"
            of "2":
              check:
                y.v.kind == bkStr
                y.v.strVal == "q"
            else:
              check false
        else:
          check false

    test "BSON access":
      check:
        bson["int32"].int32Val == 1
        bson["int64"].int64Val == 2

        bson["obj"]["field1"].int32Val == 6
        bson["obj"]["field2"].int64Val == 7
        bson["obj"]["field3"].strVal == "field3val"

        bson["arr1"]["0"].int32Val == 12
        bson["arr1"]["1"].int64Val == 13
        bson["arr1"]["2"].strVal == "arr1str"

        bson["arr2"]["0"].strVal == "o"
        bson["arr2"]["1"].strVal == "p"
        bson["arr2"]["2"].strVal == "q"

        bson["arr2"][string] == @["o", "p", "q"]

    test "Database access":
      var
        db = db_mongo.open()
      db.insert("test.nim_mongo_test", bson)
      for x in db.find("test.nim_mongo_test", limit = 1):
        echo "DB search result:"
        print x

      test "Find result":
        var
          findResult: seq[PBson]

        findResult = toSeq(db.find("test.nim_mongo_test",
          %%{"int32": %2i32},
          %%{"int32": %1i32}))
        check findResult.len == 0

        findResult = toSeq(db.find("test.nim_mongo_test", limit = 1))
        check findResult.len <= 1

        for x in db.find("test.nim_mongo_test",
            %%{"int32": %1i32},
            %%{"int32": %1i32}):
          for y in x:
            case y.k:
            of "_id":
              discard
            of "int32":
              check:
                y.v.kind == bkInt32
                y.v.int32Val == 1
            else:
              check false

        for x in db.find("test.nim_mongo_test", %%{"int32": %1i32}):
          for y in x:
            case y.k:
            of "_id", "obj", "arr1", "arr2":
              discard
            of "int32":
              check:
                y.v.kind == bkInt32
                y.v.int32Val == 1
            of "int64":
              check:
                y.v.kind == bkInt64
                y.v.int64Val == 2
            else:
              check false
