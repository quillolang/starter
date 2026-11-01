# A Quillo program to start from

Three sample [Quillo](https://quillolang.org) apps, laid out the way larger programs
are, in [Quillo UI](https://quillolang.org/components/)'s theme. Pick one, and it
becomes your program:

| Sample | What it is |
|---|---|
| `hello` | a page, a component that runs in the browser, and a function both sides use |
| `spa` | a single-page app: tabs that change without reloading the page, what the app holds kept between them, a note kept in the browser so it survives a reload, a task list from server fns, a 404 for a path that is no tab |
| `ssr` | pages made on the server: a list of notes in SQLite, a page for each, forms that redirect after posting and show what was wrong; no component, so it works with JavaScript off |

Each has a theme switch, System, Light or Dark. The choice is kept in a cookie, so the
server renders every page in it, with no flash of the other theme; System follows the
light or dark setting of the computer.

## Start

```sh
git clone --depth 1 --branch v0.6.0 https://github.com/quillolang/starter.git my-app
cd my-app
rm -rf .git && git init     # your own history: a clone would still push to quillolang/starter
sh get-quillo.sh            # asks which sample; or: sh get-quillo.sh spa
./run.sh --watch            # http://127.0.0.1:8080
```

On GitHub, **Use this template** makes the repository in one step; then clone yours and
run `get-quillo` in it.

`get-quillo.sh` copies the sample you pick into the folder and removes `samples/`. Then it
puts the release the samples are written for in `.quillo/bin/`, the build for your machine
(macOS, or Linux with glibc 2.34 or later), checked against its SHA-256, and writes
`run.sh`, which runs `main.qwe` with it and takes `quillo run`'s options. Once the folder
has a `main.qwe`, `get-quillo` leaves the program alone and only fetches quillo: a fresh
clone of your app runs it once, since `.quillo/` and `run.sh` are left out of git.

On Windows, in PowerShell, `get-quillo.ps1` does the same, and writes `run.cmd`:

```powershell
Remove-Item -Recurse -Force .git; git init
powershell -ExecutionPolicy Bypass -File get-quillo.ps1 spa
.\run.cmd --watch
```

With `quillo` already installed, copy a sample yourself and run it:

```sh
cp -R samples/spa/. . && rm -rf samples
quillo run --watch
```

Edit any file while it runs: `--watch` reloads the program and the page on save.

## What is here

```
samples/hello/, spa/, ssr/   the samples; get-quillo copies one here and removes the rest
  main.qwe                   each one's program: its routes, and the files it uses
  ui/theme.qwe               Quillo UI's theme: colours, type and shapes, light and dark
  ui/theme_switch.qwe        System, Light or Dark, kept in a cookie
get-quillo.sh                a sample, and the quillo release for this machine, into .quillo/bin/, and run.sh
get-quillo.ps1               the same, on Windows, with run.cmd
.github/workflows/check.yml  checks and serves the program on Linux, macOS and Windows
.github/starter-test.sh      the starter's own checks of each sample; an app can delete it
```

Each tag is a Quillo release (`v0.6.0`), and the samples are written for it. `main` may
use what only the next release has.

To restyle a sample, set Quillo UI's variables after its styles, in `ui/page.qwe`:
`:root { --ui-accent: #0a7d55; --ui-radius: 4px; }`. Its components are at
[quillolang.org/components](https://quillolang.org/components/); taking them file by file
needs the release after 0.6.

## Next

- The [user guide](https://github.com/quillolang/quillo/blob/main/USERGUIDE.md): the
  language, components, routes, databases and the standard library.
- [quillolang/examples](https://github.com/quillolang/examples): small programs, a file
  each: a to-do list, live notes, a single-page app, a virtual list of a million rows, and more.
- A to-do app laid out across folders, with a database, migrations, CSS and JavaScript:
  [`app/`](https://github.com/quillolang/quillo/tree/v0.6.0/app) in Quillo's own repository.
