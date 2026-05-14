#!/usr/bin/env bash
# scripts/android-env.sh — source before any Tauri Android command.
#
# Usage:
#     source scripts/android-env.sh
#     pnpm tauri android build --debug --target aarch64 --apk
#
# What it does:
#   1. Exports JAVA_HOME (JDK 17), ANDROID_HOME, NDK_HOME/ANDROID_NDK_HOME.
#   2. Prepends the NDK toolchain bin dir to PATH so cargo, cc, and shells
#      can find the cross-compilers and (via the symlinks below) the legacy
#      per-target tool names that openssl-src's Makefile still expects.
#   3. Creates symlinks like aarch64-linux-android-ranlib → llvm-ranlib in
#      the NDK toolchain bin dir (NDK r23+ removed the per-target wrappers,
#      but openssl-src's Configure-generated Makefile still calls them by
#      the old names). Idempotent — only creates symlinks that don't exist.
#   4. Sets HUSKY=0 so upstream's main-only pre-commit hook doesn't fire
#      on this fork's long-lived android branch.
#
# Customize the path defaults below if your Android SDK / JDK lives elsewhere.

export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

# Pick the highest-versioned installed NDK if NDK_HOME isn't already set.
if [ -z "${NDK_HOME:-}" ]; then
  NDK_DIR="$(ls -1 "$ANDROID_HOME/ndk/" 2>/dev/null | sort -V | tail -1)"
  if [ -n "$NDK_DIR" ]; then
    export NDK_HOME="$ANDROID_HOME/ndk/$NDK_DIR"
  fi
fi
export ANDROID_NDK_HOME="${NDK_HOME:-}"
export ANDROID_NDK_ROOT="${NDK_HOME:-}"

NDK_TOOLCHAIN="${NDK_HOME:-}/toolchains/llvm/prebuilt/darwin-x86_64"

# Prepend NDK + JDK + Android SDK + cargo to PATH.
export PATH="$NDK_TOOLCHAIN/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/.cargo/bin:$PATH"

# Create legacy-name symlinks for openssl-src cross-compile (idempotent).
if [ -x "$NDK_TOOLCHAIN/bin/llvm-ranlib" ] && [ ! -e "$NDK_TOOLCHAIN/bin/aarch64-linux-android-ranlib" ]; then
  echo "scripts/android-env.sh: creating NDK legacy-name symlinks for openssl-src..."
  for triple in aarch64-linux-android arm-linux-androideabi armv7-linux-androideabi armv7a-linux-androideabi i686-linux-android x86_64-linux-android; do
    for tool in ar ranlib strip nm; do
      target="$NDK_TOOLCHAIN/bin/${triple}-${tool}"
      [ -e "$target" ] || ln -s "llvm-${tool}" "$target"
    done
  done
fi

# Long-lived android branch needs upstream's main-only pre-commit hook off.
export HUSKY=0

echo "Android env ready:"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  ANDROID_HOME=$ANDROID_HOME"
echo "  NDK_HOME=${NDK_HOME:-(unset — install NDK via sdkmanager 'ndk;27.0.12077973')}"
