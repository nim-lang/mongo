import db_mongo, sequtils, times, oids

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
for x in bson:
  case x.k:
  of "int32":
    assert x.v.kind == bkInt32
    assert x.v.int32Val == 1
  of "int64":
    assert x.v.kind == bkInt64
    assert x.v.int64Val == 2
  of "obj":
    for y in bson.subItems:
      case y.k:
      of "field1":
        assert y.v.kind == bkInt32
        assert y.v.int32Val == 6
      of "field2":
        assert y.v.kind == bkInt64
        assert y.v.int64Val == 7
      of "field3":
        assert y.v.kind == bkStr
        assert y.v.strVal == "field3val"
      else:
        assert false
  of "arr1":
    for y in bson.subItems:
      case y.k:
      of "0":
        assert y.v.kind == bkInt32
        assert y.v.int32Val == 12
      of "1":
        assert y.v.kind == bkInt64
        assert y.v.int64Val == 13
      of "2":
        assert y.v.kind == bkStr
        assert y.v.strVal == "arr1str"
      else:
        assert false
  of "arr2":
    for y in bson.subItems:
      case y.k:
      of "0":
        assert y.v.kind == bkStr
        assert y.v.strVal == "o"
      of "1":
        assert y.v.kind == bkStr
        assert y.v.strVal == "p"
      of "2":
        assert y.v.kind == bkStr
        assert y.v.strVal == "q"
      else:
        assert false
  else:
    assert false

var
  db = db_mongo.open()

db.insert("test.nim_mongo_test", bson)
for x in db.find("test.nim_mongo_test"):
  print x

assert toSeq(db.find("test.nim_mongo_test", limit = 1)).len <= 1

for x in db.find("test.nim_mongo_test",
    %%{"int32": %1i32}, %%{"int32": %1i32}):
  for y in x:
    case y.k:
    of "_id":
      discard
    of "int32":
      assert y.v.int32Val == 1

for x in db.find("test.nim_mongo_test", %%{"int32": %1i32}):
  for y in x:
    case y.k:
    of "_id", "obj", "arr":
      discard
    of "int32":
      assert y.v.int32Val == 1
    of "int64":
      assert y.v.int64Val == 2
    else:
      assert false

assert toSeq(db.find("test.nim_mongo_test",
  %%{"int32": %2i32}, %%{"int32": %1i32})).len == 0
