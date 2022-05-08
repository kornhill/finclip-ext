#!/usr/bin/env bash
# building
cbindgen src/lib.rs -l c > libfinclipext.h
cargo lipo --release

# moving files to the ios project
proj=ios
inc=../${proj}/include
libs=../${proj}/libs

rm -rf ${inc} ${libs}

mkdir ${inc}
mkdir ${libs}

cp libfinclipext.h ${inc}
cp target/universal/release/libfinclipext.a ${libs}
