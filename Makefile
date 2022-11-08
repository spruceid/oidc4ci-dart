TARGET=target
ifeq ($(OS),Windows_NT)
	OS_NAME=Windows_NT
else
	OS_NAME=$(shell uname | tr '[:upper:]' '[:lower:]')
endif

ifeq ($(OS_NAME),darwin)
	LIB_NAME=liboidc4ci.dylib
else 
	LIB_NAME=liboidc4ci.so
endif

.PHONY: test
test: $(TARGET)/test/c.stamp \
	$(TARGET)/test/android.stamp \
	$(TARGET)/test/ios.stamp \
	$(TARGET)/test/flutter.stamp

## Setup

$(TARGET)/test:
	mkdir -p $@

## Rust

RUST_SRC=Cargo.toml $(wildcard src/*.rs src/*/*.rs src/*/*/*.rs)

$(TARGET)/oidc4ci.h: cbindgen.toml cbindings/build.rs cbindings/Cargo.toml $(RUST_SRC)
	cargo build -p oidc4ci-cbindings
	test -s $@ && touch $@

$(TARGET)/release/$(LIB_NAME): $(RUST_SRC)
	cargo build --lib --release
	strip $@ || true

## C

$(TARGET)/test/c.stamp: $(TARGET)/cabi-test $(TARGET)/release/$(LIB_NAME) | $(TARGET)/test
	LD_LIBRARY_PATH=$(TARGET)/release $(TARGET)/cabi-test
	touch $@

$(TARGET)/cabi-test: c/test.c $(TARGET)/release/$(LIB_NAME) $(TARGET)/oidc4ci.h
	$(CC) -I$(TARGET) -L$(TARGET)/release $< -ldl -loidc4ci -o $@

## Android

.PHONY: install-rustup-android
install-rustup-android:
	rustup target add i686-linux-android armv7-linux-androideabi aarch64-linux-android x86_64-linux-android

ANDROID_SDK_ROOT ?= ~/Android/Sdk
ANDROID_TOOLS ?= $(lastword $(wildcard $(ANDROID_SDK_ROOT)/build-tools/*))
ANDROID_NDK_HOME ?= $(lastword $(wildcard \
					$(ANDROID_SDK_ROOT)/ndk/* \
					$(ANDROID_SDK_ROOT)/ndk-bundle))
TOOLCHAIN=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(OS_NAME)-x86_64
ANDROID_LIBS=\
	$(TARGET)/i686-linux-android/release/liboidc4ci.so\
	$(TARGET)/armv7-linux-androideabi/release/liboidc4ci.so\
	$(TARGET)/aarch64-linux-android/release/liboidc4ci.so\
	$(TARGET)/x86_64-linux-android/release/liboidc4ci.so

$(TARGET)/test/android.stamp: $(ANDROID_LIBS) | $(TARGET)/test
	touch $@

$(TARGET)/%/release/liboidc4ci.so: $(RUST_SRC)
	PATH=$(TOOLCHAIN)/bin:"$(PATH)" \
	cargo ndk --target $* build --lib --release
	#cargo build --lib --release --target $*
	#$(TOOLCHAIN)/bin/llvm-strip $@

## iOS

.PHONY: install-rustup-ios
install-rustup-ios:
	rustup target add \
		aarch64-apple-ios \
		x86_64-apple-ios

IOS_LIBS=\
	$(TARGET)/aarch64-apple-ios/release/liboidc4ci.a \
	$(TARGET)/x86_64-apple-ios/release/liboidc4ci.a

$(TARGET)/test/ios.stamp: $(TARGET)/universal/release/liboidc4ci.a $(TARGET)/oidc4ci.h | $(TARGET)/test
	touch $@

$(TARGET)/universal/release/liboidc4ci.a: $(IOS_LIBS)
	mkdir -p $(TARGET)/universal/release
	lipo -create $^ -output $@

$(TARGET)/%/release/liboidc4ci.a: $(RUST_SRC)
	cargo build --lib --release --target $*
	#strip $@

## Flutter

$(TARGET)/test/flutter.stamp: flutter/lib/oidc4ci.dart flutter/test/oidc4ci_test.dart $(TARGET)/release/$(LIB_NAME) | $(TARGET)/test
	cd flutter && LD_LIBRARY_PATH=$(shell pwd)/flutter \
		flutter --suppress-analytics test
	touch $@

## Cleanup

.PHONY: clean
clean:
	cargo clean
