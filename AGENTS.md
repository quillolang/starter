# Working on this program

This is a [Quillo](https://quillolang.org) program: `.qwe` files hold the server's routes,
the HTML, the components that run in the browser and the SQL. Quillo is new, so read
https://quillolang.org/v0.6.0/llms.txt before writing any: the guide and every builtin of
Quillo 0.6.0, the release this program is written for (`get-quillo.sh` fetches it).
https://quillolang.org/llms.txt describes Quillo's main, the next release, which has more
than 0.6.0 (marked *since 0.7* there): code from it may not run here.

## Commands

`sh get-quillo.sh` puts the quillo this program is written for in `.quillo/bin/`. Use
that one, not another on the PATH:

| To | Run |
|---|---|
| check the program, without running it | `.quillo/bin/quillo check` |
| serve it at http://127.0.0.1:8080, reloading on each save | `./run.sh --watch` |
| try an expression | `echo 'split("a,b", ",")' \| .quillo/bin/quillo repl` |

Run `quillo check` after every change, and fix what it reports before going on. It finds
syntax errors, wrong types, misspelled fields, names a file has not taken, JavaScript
habits that mean something else here, and markup the browser would break. When it asks
for an `import` line, add the line it gives.

## Layout

- `main.qwe` is the program: it opens the database, lists the files it uses (`use
  lib/tasks.qwe`) and holds the routes.
- `lib/` holds helpers and `server fn`s, `ui/` views and components.
- `migrations/NNN_name.sql` make the tables, each once, in order. To change a table, add
  a new file; never edit one that has run.
- Paths count from this folder in every file: `use lib/x.qwe` from `ui/a.qwe` too.
- Each file starts with a comment saying what it holds. Keep it true.

## Mistakes to avoid

- `0` and `""` are truthy: write `filled(name) ?? "anonymous"`, not `name || "anonymous"`,
  and `count != 0 && ...`, not `count && ...`.
- There is no `const`, `class`, `try`/`catch`, `throw`, `in`, `break`, `?.` or `===`.
  Errors are values: `return err("why")`, `f()?` passes one on, `f() ?? x` replaces it.
- Values are immutable: `xs = xs | push(x)`, `m = { ...m, k: v }`.
- Builtins take the list first: `map(xs, f)`, `reduce(xs, init, f)`, `max([a, b])`.
- SQL takes values as `?` or `:name`, never joined into the text.
- Do not add `package.json`, a bundler or a JavaScript framework: components already
  run in the browser.
