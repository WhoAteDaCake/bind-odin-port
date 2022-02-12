package parser
import clang "../odin-clang"

import "core:strings"
import "core:slice"
import "core:fmt"
import "core:os"
import "core:runtime"

import "../types"

ParserContext :: struct {
    allocator: ^runtime.Allocator,
    types: [dynamic]^types.Type,
}

cursor_kind_name :: proc (kind: clang.CXCursorKind) -> string {
    spelling := clang.getCursorKindSpelling(kind)
    return string(clang.getCString(spelling))
}

type_spelling :: proc (t: clang.CXType) -> string {
    spelling := clang.getTypeSpelling(t)
    return string(clang.getCString(spelling))
}

kind_spelling :: proc (t: clang.CXTypeKind) -> string {
    spelling := clang.getTypeKindSpelling(t)
    return string(clang.getCString(spelling))
}

cached_cursors := make(map[u32]^types.Type);

build_function_type :: proc(t: clang.CXType) -> types.Func {
    output := types.Func{}
    // TODO: restrict to FunctionProto, FunctionNoProto
    output.ret = type_(clang.getResultType(t))
    n := cast(u32) clang.getNumArgTypes(t)
    output.params = make([]^types.Type, n)
    for i in 0..(n - 1) {
        output.params[i] = type_(clang.getArgType(t, i))
    }
    return output
}

build_ptr_type :: proc(t: clang.CXType) -> types.Pointer {
    return types.Pointer{type_(clang.getPointeeType(t))}
}

type_ :: proc(t: clang.CXType) -> ^types.Type {
    output := new(types.Type)
    // fmt.println(type_spelling(t))
    // output.name = 
    #partial switch t.kind {
        case .CXType_FunctionProto: {
            output.variant = build_function_type(t)
        }
        // Check if I need to handle special case for function pointers
        case .CXType_Pointer: {
            output.variant = build_ptr_type(t)
        }
        case .CXType_Void: {
            output.variant = types.Primitive{types.Primitive_Kind.void}
        }
        case .CXType_Char_S: {
            output.variant = types.Primitive{types.Primitive_Kind.schar}
        }
        case .CXType_Int: {
            output.variant = types.Primitive{types.Primitive_Kind.int}
        }
        case .CXType_Elaborated: {
            cursor := clang.getTypeDeclaration(t)
            // Free previous data
            found := cached_cursors[clang.hashCursor(cursor)]
            output.variant = types.Node_Ref{found}
        }
        case: fmt.println(t.kind)
    }
    return output
}

visit_typedef :: proc(cursor: clang.CXCursor) -> types.Typedef {
    output := new(types.Typedef)
    t := clang.getTypedefDeclUnderlyingType(cursor)
    base := type_(t)
    name := type_spelling(t)
    cached_cursors[clang.hashCursor(cursor)] = base
    return types.Typedef{name,base}
}

visit :: proc (cursor: clang.CXCursor) ->^types.Type {
    output := new(types.Type)
    #partial switch cursor.kind {
        case .CXCursor_TypedefDecl: {
            output.variant = visit_typedef(cursor)
        }
    }
    return output
}

visitor :: proc "c" (
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) -> clang.CXChildVisitResult {
    c := runtime.default_context()
    ctx := (cast(^ParserContext) client_data)^
    c.allocator = ctx.allocator^
    context = c
    //
    t := visit(cursor)
    append(&ctx.types, t)
    append(&ctx.types, &types.Type{"", types.Va_Arg{}})

    fmt.println(len(ctx.types))

    return clang.CXChildVisitResult.CXChildVisit_Continue;
}

main :: proc() {
    idx := clang.createIndex(0, 1);
    defer clang.disposeIndex(idx)

    content: cstring = "#include \"test/headers.h\""
    file := clang.CXUnsavedFile {
        Filename = "test.c",
        Contents = content,
        Length = auto_cast len(content),
    }
    files := []clang.CXUnsavedFile{file}
    raw_flags := "-I/usr/include/python3.8 -I/usr/include/python3.8  -Wno-unused-result -Wsign-compare -g -fdebug-prefix-map=/build/python3.8-4OrTnN/python3.8-3.8.10=. -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector -Wformat -Werror=format-security  -DNDEBUG -g -fwrapv -O3 -Wall -lcrypt -lpthread -ldl  -lutil -lm -lm"

    options := clang.defaultEditingTranslationUnitOptions()

    flags := strings.split(raw_flags, " ")
    defer delete(flags)

    c_flags := make([dynamic]cstring)
    defer delete(c_flags)

    for flag in flags {
        append(&c_flags, strings.clone_to_cstring(flag))
    }

    tu := clang.CXTranslationUnit{}
    defer clang.disposeTranslationUnit(tu)

    err := clang.parseTranslationUnit2(
        idx,
        "test.c",
        raw_data(c_flags[:]),
        auto_cast len(c_flags),
        slice.first_ptr(files),
        auto_cast len(files),
        options,
        &tu,
    );

    if err != nil {
        fmt.println(err)
    }
    if tu == nil {
        fmt.println("Failed to configure translation unit")
        os.exit(1)
    }
    cursor := clang.getTranslationUnitCursor(tu)
    allocator := context.allocator
    ctx := ParserContext{&allocator,make([dynamic]^types.Type)}
    
    clang.visitChildren(cursor, visitor, &ctx)

    fmt.println(len(ctx.types))
    // for entry in ctx.types {
    //     fmt.println(entry)
    // }
}