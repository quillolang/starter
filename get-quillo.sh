#!/bin/sh
# Starts this folder's program from a sample app, when it has no main.qwe yet,
# and puts the quillo it is written for in .quillo/bin/: the release's build for
# this machine, checked against the SHA-256 published beside it.
#
#   sh get-quillo.sh            asks which sample; then  ./run.sh --watch
#   sh get-quillo.sh spa        that sample: hello, spa or ssr (see samples/)
#
# The sample's files are copied here, and samples/ is removed. Once main.qwe is
# here, the folder's program is kept as it is: only quillo is fetched.
#
# It also writes run.sh, which runs this folder's main.qwe with that quillo,
# unless there is a run.sh already.
#
# QUILLO_VERSION=v0.7.0 takes another release; QUILLO_RELEASES another place
# to download from (a mirror, or a folder as file:///...).
set -eu

version=${QUILLO_VERSION:-v0.7.0}
releases=${QUILLO_RELEASES:-https://github.com/quillolang/quillo/releases/download}
here=$(cd "$(dirname "$0")" && pwd)
bin="$here/.quillo/bin"
source_build="build it from source instead: https://github.com/quillolang/quillo#getting-started"

# The samples, in the order they are offered.
samples="hello spa ssr"
about() {
    case "$1" in
        hello) echo "a page, a component and a function both sides use" ;;
        spa) echo "a single-page app: tabs that change without reloading, what it holds kept between them" ;;
        ssr) echo "pages made on the server: a list, forms and SQLite, working with JavaScript off" ;;
    esac
}
is_sample() { case " $samples " in *" $1 "*) [ -n "$1" ] ;; *) false ;; esac; }

sample=${1:-}
if [ $# -gt 1 ] || { [ -n "$sample" ] && ! is_sample "$sample"; }; then
    echo "get-quillo: which sample? sh get-quillo.sh, or one of: $samples" >&2
    exit 2
fi
if [ -e "$here/main.qwe" ]; then
    if [ -n "$sample" ]; then
        echo "get-quillo: this folder has a main.qwe, so it starts from no sample; only quillo is fetched for it" >&2
        exit 1
    fi
elif [ ! -d "$here/samples" ]; then
    echo "get-quillo: there is no main.qwe here and no samples/ to start one from" >&2
    exit 1
else
    if [ -z "$sample" ] && [ -t 0 ]; then
        echo "Which sample app should this folder start from?"
        n=0
        for s in $samples; do n=$((n + 1)); printf '  %s  %-6s %s\n' "$n" "$s" "$(about "$s")"; done
        printf 'Number or name [1]: '
        read -r answer || answer=
        n=0
        for s in $samples; do n=$((n + 1)); [ "$answer" = "$n" ] && answer=$s; done
        sample=${answer:-hello}
        if ! is_sample "$sample"; then
            echo "get-quillo: no sample \"$sample\": one of $samples" >&2
            exit 2
        fi
    elif [ -z "$sample" ]; then
        sample=hello
        echo "get-quillo: no terminal to ask, so the hello sample (sh get-quillo.sh spa takes another)"
    fi
    # Nothing here is overwritten: a file the sample has, already here, stops it.
    for f in "$here/samples/$sample"/*; do
        if [ -e "$here/$(basename "$f")" ]; then
            echo "get-quillo: $(basename "$f") is here already; move it away to start from the $sample sample" >&2
            exit 1
        fi
    done
    cp -R "$here/samples/$sample/." "$here/"
    rm -rf "$here/samples"
    echo "get-quillo: this folder's program is the $sample sample now ($(cd "$here" && ls -d main.qwe */ 2>/dev/null | tr '\n' ' ')); samples/ is removed"
fi

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
        # The Linux builds of 0.7.0 are linked against glibc 2.17: CentOS 7, CloudLinux 7
        # and anything newer runs them. Alpine's musl cannot (0.6.0's needed 2.34).
        glibc=$(getconf GNU_LIBC_VERSION 2>/dev/null | sed -n 's/^glibc \([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
        if [ -z "$glibc" ]; then
            echo "get-quillo: Quillo's Linux builds need glibc, which this system does not have; $source_build" >&2
            exit 1
        fi
        set -- $glibc
        if [ "$1" -lt 2 ] || { [ "$1" -eq 2 ] && [ "$2" -lt 17 ]; }; then
            echo "get-quillo: Quillo's Linux builds need glibc 2.17 or later, and this system has $1.$2; $source_build" >&2
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

# run.sh, beside this script. One that is there already, perhaps edited, is kept.
write_run() {
    [ -e "$here/run.sh" ] && return 0
    cat > "$here/run.sh" <<'EOF'
#!/bin/sh
# Runs this folder's main.qwe with the quillo in .quillo/bin/, which
# get-quillo.sh put there, and puts there first when it is not:
#
#   ./run.sh --watch            the options are quillo run's: --port 8081, --reload
set -eu
here=$(cd "$(dirname "$0")" && pwd)
if [ ! -x "$here/.quillo/bin/quillo" ]; then sh "$here/get-quillo.sh"; fi
exec "$here/.quillo/bin/quillo" run "$here/main.qwe" "$@"
EOF
    chmod +x "$here/run.sh"
    echo "get-quillo: wrote run.sh; start the program with ./run.sh --watch"
}

if [ -x "$bin/quillo" ] && "$bin/quillo" version 2>/dev/null | grep -q "^quillo ${version#v} "; then
    echo "get-quillo: $("$bin/quillo" version) is already in .quillo/bin"
    write_run
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
write_run
