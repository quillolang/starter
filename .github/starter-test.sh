#!/bin/bash
# The starter's own checks of a sample, once get-quillo has made it this folder's
# program and it is served at $BASE (http://127.0.0.1:8080):
#
#   bash .github/starter-test.sh spa
#
# The workflow runs it in quillolang/starter only. An app made from the starter
# changes the pages it checks, and can delete this file.
set -uo pipefail
# Git Bash on Windows rewrites arguments that look like paths before curl sees
# them: back=/notes/2 into a Windows path, //evil.example into /evil.example.
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'
sample=$1
base=${BASE:-http://127.0.0.1:8080}
failed=0

pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; failed=$((failed + 1)); }
has() { case "$2" in *"$3"*) pass "$1" ;; *) fail "$1: no $3" ;; esac; }
lacks() { case "$2" in *"$3"*) fail "$1: has $3" ;; *) pass "$1" ;; esac; }
is() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1: $2, not $3"; fi; }
get() { curl -s "$@"; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
# The status, the Location and the theme cookie of an answer, on one line.
head_of() { curl -s -o /dev/null -D - "$@" | tr -d '\r' | grep -iE '^(HTTP/|location:|set-cookie: theme=)' | sed -E 's/^HTTP\/[0-9.]+ ([0-9]+).*/\1/; s/^location: /-> /I; s/^set-cookie: (theme=[^;]*).*/\1/I' | tr '\n' ' ' | sed 's/ $//'; }
rpc() { curl -s -H 'Content-Type: application/json' -d "$2" "$base/_quillo/rpc/$1"; }

# Every sample: Quillo UI's theme, and the switch, kept in a cookie the server reads.
page=$(get "$base/")
has "the theme's variables are on the page" "$page" "--ui-accent:"
has "<body class=\"ui-root\">" "$page" '<body class="ui-root">'
has "the switch is on the page" "$page" 'aria-label="Theme"'
has "a description for search engines (Lighthouse's SEO)" "$page" '<meta name="description" content="'
has "no theme kept: <html> follows the system" "$page" '<html lang="en">'
has "no theme kept: System is pressed" "$page" 'aria-pressed="true">System'
has "dark kept: <html class=\"ui-dark\">" "$(get -H 'Cookie: theme=dark' "$base/")" '<html class="ui-dark" lang="en">'
has "light kept: <html class=\"ui-light\">" "$(get -H 'Cookie: theme=light' "$base/")" '<html class="ui-light" lang="en">'
has "dark kept: Dark is pressed" "$(get -H 'Cookie: theme=dark' "$base/")" 'aria-pressed="true">Dark'
has "system kept: <html> follows the system" "$(get -H 'Cookie: theme=system' "$base/")" '<html lang="en">'
has "a cookie that is no theme: the system's" "$(get -H 'Cookie: theme=%3Cb%3E' "$base/")" '<html lang="en">'

if [ "$sample" = hello ] || [ "$sample" = spa ]; then
    # The switch is a component; it keeps the choice through a server fn.
    is "save_theme dark" "$(curl -s -D - -o /dev/null -H 'Content-Type: application/json' -d '["dark"]' "$base/_quillo/rpc/save_theme" | tr -d '\r' | grep -io 'set-cookie: theme=[^;]*;')" "set-cookie: theme=dark;"
    is "save_theme system: kept as a value, not deleted" "$(rpc save_theme '["system"]')" '{"ok":"system"}'
    is "save_theme of no theme: system" "$(rpc save_theme '["purple"]')" '{"ok":"system"}'
    lacks "the cookie is not Secure, so it holds on plain HTTP" "$(curl -s -D - -o /dev/null -H 'Content-Type: application/json' -d '["dark"]' "$base/_quillo/rpc/save_theme")" "Secure"
    is "save_theme from another site: refused" "$(code -H 'Origin: https://evil.example' -H 'Content-Type: application/json' -d '["dark"]' "$base/_quillo/rpc/save_theme")" 403
fi

case "$sample" in
hello)
    has "the Counter component" "$page" 'data-c="Counter"'
    has "its description" "$page" 'content="A Quillo program to start from: a page'
    is "/hello/Ana" "$(get "$base/hello/Ana")" "Hello, Ana!"
    ;;
spa)
    has "the App component" "$page" 'data-c="App"'
    has "Home is the tab" "$page" '<a href="/" aria-current="page">'
    for tab in tasks notes settings; do
        is "/$tab answers" "$(code "$base/$tab")" 200
        has "/$tab: its tab is current" "$(get "$base/$tab")" "<a href=\"/$tab\" aria-current=\"page\">"
    done
    has "each tab its own description: Tasks" "$(get "$base/tasks")" 'content="A task list kept in SQLite'
    has "each tab its own description: Notes" "$(get "$base/notes")" 'content="A note kept in SQLite as you type'
    has "a path that is no tab: a description too" "$(get "$base/nope")" 'content="There is no tab at this address."'
    is "a path that is no tab: 404" "$(code "$base/nope")" 404
    is "a tab's path, one deeper: 404" "$(code "$base/tasks/1")" 404
    has "a task added" "$(rpc add_task '["Water the plants"]')" '"text":"Water the plants","done":0}]}'
    is "an empty task: the reason" "$(rpc add_task '["   "]')" '{"err":"a task needs some text"}'
    rpc add_task '["<img src=x onerror=alert(1)>"]' >/dev/null
    tasks=$(get "$base/tasks")
    has "a task's markup is shown as text" "$tasks" "&lt;img src=x onerror=alert(1)&gt;"
    lacks "and never as markup" "$tasks" "<img src=x"
    has "toggled" "$(rpc toggle_task '[1]')" '"id":1,"text":"Open the Notes tab, write something, reload","done":1}'
    # The note, in the database: saved by a server fn, in the page the server makes.
    has "a new database: the note is empty" "$(get "$base/notes")" 'aria-label="Note"></textarea>'
    is "a note saved" "$(rpc save_note '["Kept in SQLite <b>as text</b>"]')" '{"ok":"Kept in SQLite <b>as text</b>"}'
    has "the server puts it in the page" "$(get "$base/notes")" '>Kept in SQLite &lt;b&gt;as text&lt;/b&gt;</textarea>'
    is "load_note gives it" "$(rpc load_note '[]')" '{"ok":"Kept in SQLite <b>as text</b>"}'
    long=$(printf 'x%.0s' $(seq 1 20001))
    is "a note over 20,000 characters: refused" "$(rpc save_note "[\"$long\"]")" '{"err":"keep the note under 20,000 characters"}'
    is "and the note kept as it was" "$(rpc load_note '[]')" '{"ok":"Kept in SQLite <b>as text</b>"}'
    ;;
ssr)
    lacks "no component: the pages need no JavaScript" "$page" "<quillo-island"
    has "the first note, from the migration" "$page" ">Welcome</a>"
    added=$(head_of -d 'title=From the test&body=Two%0Alines' "$base/notes")
    case "$added" in "303 -> /notes/"*) pass "a note posted: 303 to its page" ;; *) fail "a note posted: $added" ;; esac
    note=${added#"303 -> "}
    has "its page" "$(get "$base$note")" "<h2>From the test</h2>"
    has "its description: its text, on one line" "$(get "$base$note")" '<meta name="description" content="Two lines"'
    is "a blank title: 422" "$(code -d 'title=%20%20&body=kept' "$base/notes")" 422
    has "and the reason, with what was typed" "$(get -d 'title=%20%20&body=kept%20text' "$base/notes")" "a note needs a title"
    has "what was typed is kept" "$(get -d 'title=%20%20&body=kept%20text' "$base/notes")" ">kept text</textarea>"
    is "a title over 120 characters: 422" "$(code --data-urlencode "title=$(printf 'x%.0s' $(seq 1 121))" -d body= "$base/notes")" 422
    is "a form without its body field: 400" "$(code -d 'title=x' "$base/notes")" 400
    head_of --data-urlencode 'title=<script>alert(1)</script>' -d body= "$base/notes" >/dev/null
    list=$(get "$base/")
    has "a title's markup is shown as text" "$list" "&lt;script&gt;alert(1)&lt;/script&gt;"
    lacks "and never as markup" "$list" "<script>alert(1)"
    is "no such note: 404" "$(code "$base/notes/99999")" 404
    is "a note's id that is no number: 404" "$(code "$base/notes/abc")" 404
    is "the theme form: back where it was" "$(head_of -d "theme=dark&back=$note" "$base/theme")" "303 -> $note theme=dark"
    is "the theme form: System is kept as a value" "$(head_of -d 'theme=system&back=/' "$base/theme")" "303 -> / theme=system"
    is "the theme form: no theme is System" "$(head_of -d 'theme=purple&back=/' "$base/theme")" "303 -> / theme=system"
    for back in '//evil.example' 'https://evil.example' '/\evil.example' 'javascript:alert(1)' ''; do
        is "back=$back: home, never another site" "$(head_of --data-urlencode "back=$back" -d theme=light "$base/theme")" "303 -> / theme=light"
    done
    is "the theme form from another site: refused" "$(code -H 'Origin: https://evil.example' -d 'theme=dark&back=/' "$base/theme")" 403
    is "deleted: back to the list" "$(head_of -X POST "$base$note/delete")" "303 -> /"
    is "and gone" "$(code "$base$note")" 404
    ;;
*)
    fail "no sample $sample"
    ;;
esac

if [ "$failed" -gt 0 ]; then
    echo "$failed failed"
    exit 1
fi
echo "all passed"
