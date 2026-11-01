#!/bin/sh
# Puts the quillo this program is written for in .quillo/bin/, the release's
# build for this machine, checked against the SHA-256 published beside it.
#
#   sh get-quillo.sh            then  .quillo/bin/quillo run --watch
#
# QUILLO_VERSION=v0.7.0 takes another release; QUILLO_RELEASES another place
# to download from (a mirror, or a folder as file:///...).
set -eu

version=${QUILLO_VERSION:-v0.6.0}
releases=${QUILLO_RELEASES:-https://github.com/quillolang/quillo/releases/download}
here=$(cd "$(dirname "$0")" && pwd)
bin="$here/.quillo/bin"
source_build="build it from source instead: https://github.com/quillolang/quillo#getting-started"

os=$(uname -s)
cpu=$(uname -m)
target=
case "$os" in
    Darwin)
        # A shell under Rosetta says x86_64 on Apple silicon; the arm64 build is the one to run there.
        if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = 1 ]; then cpu=arm64; fi
        case "$cpu" in
            arm64) target=aarch64-apple-darwin ;;
            x86_64) target=x86_64-apple-darwin ;;
        esac ;;
    Linux)
        # The Linux builds are linked against glibc 2.34 or later (they are made on
        # Ubuntu 22.04): Alpine's musl cannot run them, nor Ubuntu 20.04, Debian 11
        # or RHEL 8, which would fail with "GLIBC_2.34 not found".
        glibc=$(getconf GNU_LIBC_VERSION 2>/dev/null | sed -n 's/^glibc \([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
        if [ -z "$glibc" ]; then
            echo "get-quillo: Quillo's Linux builds need glibc, which this system does not have; $source_build" >&2
            exit 1
        fi
        set -- $glibc
        if [ "$1" -lt 2 ] || { [ "$1" -eq 2 ] && [ "$2" -lt 34 ]; }; then
            echo "get-quillo: Quillo's Linux builds need glibc 2.34 or later, and this system has $1.$2; $source_build" >&2
            exit 1
        fi
        case "$cpu" in
            x86_64 | amd64) target=x86_64-unknown-linux-gnu ;;
            aarch64 | arm64) target=aarch64-unknown-linux-gnu ;;
        esac ;;
    MINGW* | MSYS* | CYGWIN*)
        echo "get-quillo: on Windows, run get-quillo.ps1 in PowerShell" >&2
        exit 1 ;;
esac
if [ -z "$target" ]; then
    echo "get-quillo: Quillo $version has no build for $os on $cpu; $source_build" >&2
    exit 1
fi

if [ -x "$bin/quillo" ] && "$bin/quillo" version 2>/dev/null | grep -q "^quillo ${version#v} "; then
    echo "get-quillo: $("$bin/quillo" version) is already in .quillo/bin"
    exit 0
fi

name="quillo-$version-$target"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for f in "$name.tar.gz" "$name.tar.gz.sha256"; do
    if ! curl -fsSL -o "$tmp/$f" "$releases/$version/$f"; then
        echo "get-quillo: cannot download $releases/$version/$f (is $version a Quillo release?)" >&2
        exit 1
    fi
done
if command -v sha256sum >/dev/null 2>&1; then sum="sha256sum -c"; else sum="shasum -a 256 -c"; fi
if ! (cd "$tmp" && $sum "$name.tar.gz.sha256") >/dev/null 2>&1; then
    echo "get-quillo: $name.tar.gz does not match its SHA-256; nothing was installed" >&2
    exit 1
fi
tar -xzf "$tmp/$name.tar.gz" -C "$tmp"
mkdir -p "$bin"
# Moved in whole, so a quillo that is running from here is not overwritten as it runs.
mv "$tmp/$name/quillo" "$bin/quillo.new"
chmod +x "$bin/quillo.new"
mv -f "$bin/quillo.new" "$bin/quillo"
echo "get-quillo: $("$bin/quillo" version), in .quillo/bin"
