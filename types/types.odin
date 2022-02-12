package types

Primitive_Flag :: enum
{
    Integer,
    Unsigned,
    Float,
}
Primitive_Flags :: bit_set[Primitive_Flag];

Primitive_Kind :: enum
{
    void,
    
    char,
    
    schar,
    short,
    int,
    long,
    longlong,
    
    uchar,
    ushort,
    uint,
    ulong,
    ulonglong,
    
    float,
    double,
    longdouble,
    
    i8,
    i16,
    i32,
    i64,
    
    u8,
    u16,
    u32,
    u64,
    
    wchar_t,
    size_t,
    ssize_t,
    ptrdiff_t,
    uintptr_t,
    intptr_t,
}

Type :: struct
{
    name: string,
    variant: union
    {
        Invalid,
        Primitive,
        Typedef,
        Pointer,
        Array,
        Func,
        Struct,
        Union,
        // Bitfield,
        Va_Arg,
        Node_Ref,
    },
}

Va_Arg :: struct {}

Invalid :: struct{};

Primitive :: struct
{
    kind: Primitive_Kind,
    // flags: Primitive_Flags,
}

Node_Ref :: struct {
    base: ^Type,
}

Typedef :: struct
{
    name: string,
    base: ^Type,
}

Func :: struct
{
    ret: ^Type,
    params: []^Type,
}

Pointer :: struct
{
    base: ^Type,
}

Struct :: struct
{
    fields: []^Type,
}

Union :: struct
{
    fields: []^Type,
}

Array :: struct
{
    base: ^Type,
    size: i64,
}