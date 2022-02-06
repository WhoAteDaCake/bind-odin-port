# !/usr/bin/env bash

odin-nightly build \
    parser \
    -out:dist/main \
    -extra-linker-flags:-lclang \
    || { echo 'my_command failed' ; exit 1; }

./dist/main