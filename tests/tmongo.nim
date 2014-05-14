#!strongSpaces

import db_mongo, bson, mongo, sequtils, tables, future, unittest

suite "mongo":
  setup:
    db_mongo.init()
    var
      client = initClient()
      coll = ("test", "nim_mongo")

  teardown:
    db_mongo.cleanup()

  test "insert":
    client.delete(coll)
    assert client.count(coll) == 0

    for i in 0 .. 19:
      client.insert(coll, %{
          "int32Val": %1i32,
          "int64Val": %2i64,
          "double": %3.3,
          "jsRegex": %("foo.*bar", {broInsensitive, broMultiline}),
          "bool1": %true,
          "bool2": %false,
          "doc": %{
            "docInt32Val": %12i32,
            "docInt64Val": %13i64,
            "docArr": %[
              %50i32,
              %60i64
            ]
          },
          "arr": %[
            %20i32,
            %21i64,
            %{
              "arrDocInt32Val": %100i32,
              "arrDocInt64Val": %101i64,
            }
          ]
        }
      )

    var findResult = toSeq(client.find(coll, limit=10, skip=15))
    assert findResult.len == 5
    for x in findResult:
      var fieldKeys = map(
        toSeq(x.fields),
        (x: tuple[k: string, v: ptr TBsonVal, iter: ptr bson.TIter]) => x.k)
      assert "_id" in fieldKeys
      assert "int32Val" in fieldKeys
      assert "int64Val" in fieldKeys
      assert "bool1" in fieldKeys
      assert "bool2" in fieldKeys
      assert "doc" in fieldKeys
      assert "arr" in fieldKeys

      for k, v, iter in x.fields:
        case k
        of "_id":
          nil
        of "int32Val":
          assert v.int32Val == 1
        of "int64Val":
          assert v.int64Val == 2
        of "double":
          assert v.float64Val in 3.29 .. 3.31
        of "jsRegex":
          assert $v.jsRegex.pattern == "foo.*bar"
          assert v[].jsRegexOpts == {broInsensitive, broMultiline}
        of "bool1":
          assert v.boolVal
        of "bool2":
          assert(not v.boolVal)
        of "doc":
          var field2Keys = map(
            toSeq(iter.fields),
            (x: tuple[k: string, v: ptr TBsonVal, iter: ptr bson.TIter]) =>
              x.k)
          assert "docInt32Val" in field2Keys
          assert "docInt64Val" in field2Keys
          assert "docArr" in field2Keys
          for k2, v2, iter2 in iter.fields:
            case k2
            of "docInt32Val":
              assert v2.int32Val == 12
            of "docInt64Val":
              assert v2.int64Val == 13
            of "docArr":
              for i, v3, iter3 in iter2.arrIndices:
                case i
                of 0:
                  assert v3.int32Val == 50
                of 1:
                  assert v3.int64Val == 60
                else:
                  assert false
            else:
              assert false, k2
        of "arr":
          assert toSeq(iter.arrIndices).len == 3
          for i, v, iter2 in iter.arrIndices:
            case i
            of 0:
              assert v.int32Val == 20
            of 1:
              assert v.int64Val == 21
            of 2:
              for k, v, iter3 in iter2.fields:
                case k
                of "arrDocInt32Val":
                  assert v.int32Val == 100
                of "arrDocInt64Val":
                  assert v.int64Val == 101
                else:
                  assert false
            else:
              assert false
        else:
          assert false, k

    when false: # TODO: %{:} is ambiguous. compiler bug?
      test "update":
        client.update(coll, %{:}, %{"$set": %{"int32Val": %500i32}})
        var nUpdated = 0
        for doc in client.find(coll):
          for k, v, iter in doc.fields:
            if k == "int32Val":
              if v.int32Val == 500i32:
                inc nUpdated

        check nUpdated == 1

    test "delete":
      client.delete(coll, flags = {dfRemoveOne})
      assert client.count(coll) == 19

      client.delete(coll)
      assert client.count(coll) == 0
