import db_mongo

var
  bson = newBson({
    "int32": %1'i32,
    "int64": %2'i64,
    "obj": %{
      "field1": %6'i32,
      "field2": %7'i64,
      "field3": %"field3val"
    }
  })
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
  else:
    assert false
