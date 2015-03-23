import typetraits

template assertRaised*(e: typedesc, code: stmt) =
    var x = true
    try:
        code
    except e:
        x = false

    if x:
        assert false, typetraits.name(e) & " was not raised"
