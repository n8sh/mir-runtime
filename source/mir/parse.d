/++
+/
module mir.parse;

import mir.primitives;
import std.range.primitives: isInputRange;

/++
+/
bool parse(T : byte, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && !__traits(isUnsigned, T))
{
    int lvalue;
    auto ret = parse!(int, Range)(r, lvalue);
    value = cast(byte) lvalue;
    return ret && value == lvalue;
}
/// ditto
bool parse(T : short, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && !__traits(isUnsigned, T))
{
    int lvalue;
    auto ret = parse!(int, Range)(r, lvalue);
    value = cast(short) lvalue;
    return ret && value == lvalue;
}

/// ditto
pragma(inline, false)
bool parse(T : int, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && !__traits(isUnsigned, T))
{
    return parseSignedImpl!(int, Range)(r, value);
}

/// ditto
pragma(inline, false)
bool parse(T : long, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && !__traits(isUnsigned, T))
{
    return parseSignedImpl!(long, Range)(r, value);
}

/// ditto
bool parse(T : ubyte, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && __traits(isUnsigned, T))
{
    uint lvalue;
    auto ret = parse!(uint, Range)(r, lvalue);
    value = cast(ubyte) lvalue;
    return ret && value == lvalue;
}

/// ditto
bool parse(T : ushort, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && __traits(isUnsigned, T))
{
    uint lvalue;
    auto ret = parse!(uint, Range)(r, lvalue);
    value = cast(ushort) lvalue;
    return ret && value == lvalue;
}

/// ditto
pragma(inline, false)
bool parse(T : uint, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && __traits(isUnsigned, T))
{
    return parseUnsignedImpl!(uint, Range)(r, value);
}

/// ditto
pragma(inline, false)
bool parse(T : ulong, Range)(scope ref Range r, scope ref T value)
    if (isInputRange!Range && __traits(isUnsigned, T))
{
    return parseUnsignedImpl!(ulong, Range)(r, value);
}


///
unittest
{
    import std.meta: AliasSeq;
    foreach (T; AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong))
    {
        auto str = "123";
        T val;
        assert(parse(str, val));
        assert(val == 123);
        str = "0";
        assert(parse(str, val));
        assert(val == 0);
        str = "9";
        assert(parse(str, val));
        assert(val == 9);
        str = "";
        assert(!parse(str, val));
        assert(val == 0);
        str = "text";
        assert(!parse(str, val));
        assert(val == 0);
    }
}

///
unittest
{
    import std.meta: AliasSeq;
    foreach (T; AliasSeq!(byte, short, int, long))
    {
        auto str = "-123";
        T val;
        assert(parse(str, val));
        assert(val == -123);
        str = "-0";
        assert(parse(str, val));
        assert(val == 0);
        str = "-9text";
        assert(parse(str, val));
        assert(val == -9);
        assert(str == "text");
        enum m = T.min + 0;
        str = m.stringof;
        assert(parse(str, val));
        assert(val == T.min);
    }
}

///
unittest
{
    import std.meta: AliasSeq;
    foreach (T; AliasSeq!(byte, short, int, long))
    {
    }
}

alias r1 = parseUnsignedImpl!(uint, string);
alias r2 = parseUnsignedImpl!(ulong, string);
alias r3 = parseSignedImpl!(int, string);
alias r4 = parseSignedImpl!(long, string);

private bool parseUnsignedImpl(T, Range)(scope ref Range r, scope ref T value)
    if(__traits(isUnsigned, T))
{
    import core.checkedint: addu, mulu;

    bool sign;
B:
    if (!r.empty)
    {
        auto f = r.front + 0u;
        if (!sign && f == '+')
        {
            r.popFront;
            sign = true;
            goto B;
        }
        uint c = f - '0';
        if (c >= 10)
            goto F;
        T x = c;
        for(;;)
        {
            r.popFront;
            if (r.empty)
                break;
            c = r.front - '0';
            if (c >= 10)
                break;
            bool overflow;
            T y = mulu(x, cast(uint)10, overflow);
            if (overflow)
                goto R;
            x = y;
            T z = addu(x, cast(uint)c, overflow);
            if (overflow)
                goto R;
            x = z;
        }
        value = x;
        return true;
    }
F:  value = 0;
R:  return false;
}

private bool parseSignedImpl(T, Range)(scope ref Range r, scope ref T value)
    if(!__traits(isUnsigned, T))
{
    import core.checkedint: negs;
    import std.traits: Unsigned;

    bool sign;
B:
    if (!r.empty)
    {
        auto f = r.front + 0u;
        if (!sign && f == '-')
        {
            r.popFront;
            sign = true;
            goto B;
        }
        auto retu = (()@trusted=>parse(r, *cast(Unsigned!T*) &value))();
        // auto retu = false;
        if (!retu)
            goto R;
        if (!sign)
        {
            if (value < 0)
                goto R;
        }
        else
        {
            if (value < 0 && value != T.min)
                goto R;
            value = -value;
        }
        return true;
    }
F:  value = 0;
R:  return false;
}
