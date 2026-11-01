# A Quillo program to start from

The smallest [Quillo](https://quillolang.org) program laid out the way larger ones are:
a page, a component that runs in the browser, and a function both sides use.

## Start

```sh
git clone --depth 1 --branch v0.6.0 https://github.com/quillolang/starter.git my-app
cd my-app
rm -rf .git && git init     # your own history: a clone would still push to quillolang/starter
```

On GitHub, **Use this template** does the same in one step.

If `quillo version` answers, run it:

```sh
quillo run --watch          # http://127.0.0.1:8080
```

If not, `get-quillo.sh` puts the release this program is written for in `.quillo/bin/`,
the build for your machine, checked against its SHA-256. It also writes `run.sh`, which
runs `main.qwe` with that quillo, and takes `quillo run`'s options:

```sh
sh get-quillo.sh            # macOS, and Linux with glibc 2.34 or later
./run.sh --watch
```

On Windows, in PowerShell, `get-quillo.ps1` does the same, and writes `run.cmd`:

```powershell
Remove-Item -Recurse -Force .git; git init
powershell -ExecutionPolicy Bypass -File get-quillo.ps1
.\run.cmd --watch
```

Both are left out of git, as the binary is: a fresh clone runs `get-quillo` once.

Edit any file while it runs: `--watch` reloads the program and the page on save.

## What is here

```
main.qwe                     the program: the files it uses and its routes
lib/greet.qwe                a function, for the server and the browser
ui/page.qwe                  the frame every page uses, and a component
get-quillo.sh                the quillo release for this machine, into .quillo/bin/, and run.sh
get-quillo.ps1               the same, on Windows, and run.cmd
.github/workflows/check.yml  checks and serves the program on Linux, macOS and Windows
```

Each tag is a Quillo release (`v0.6.0`), and the program is written for it. `main`
may use what only the next release has.

## Next

- The [user guide](https://github.com/quillolang/quillo/blob/main/USERGUIDE.md): the
  language, components, routes, databases and the standard library.
- [quillolang/examples](https://github.com/quillolang/examples): small programs, a file
  each: a to-do list, live notes, a single-page app, a virtual list of a million rows, and more.
- A to-do app laid out across folders, with a database, migrations, CSS and JavaScript:
  [`app/`](https://github.com/quillolang/quillo/tree/v0.6.0/app) in Quillo's own repository.
