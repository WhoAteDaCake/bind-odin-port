package parser
import clang "../odin-clang"

import "core:strings"
import "core:slice"
import "core:fmt"
import "core:os"
import "core:runtime"

cursor_kind_name :: proc (kind: clang.CXCursorKind) -> string {
    spelling := clang.getCursorKindSpelling(kind)
    defer clang.disposeString(spelling)

    return string(clang.getCString(spelling))
}

visitor :: proc "c" (
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) -> clang.CXChildVisitResult {
    c := runtime.default_context()
    allocator := cast(^runtime.Allocator) client_data
    c.allocator = allocator^
    context = c

    fmt.println(cursor)
    // name := cursor_kind_name(cursor.kind)
    // defer delete(name)

    // fmt.println(name)

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
    clang.visitChildren(cursor, visitor, &allocator)
}