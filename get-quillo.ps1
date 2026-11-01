# Starts this folder's program from a sample app, when it has no main.qwe yet,
# and puts the quillo it is written for in .quillo\bin\: the release's build for
# Windows, checked against the SHA-256 published beside it.
#
#   powershell -ExecutionPolicy Bypass -File get-quillo.ps1       asks which sample; then  .\run.cmd --watch
#   powershell -ExecutionPolicy Bypass -File get-quillo.ps1 spa   that sample: hello, spa or ssr (see samples\)
#
# The sample's files are copied here, and samples\ is removed. Once main.qwe is
# here, the folder's program is kept as it is: only quillo is fetched.
#
# It also writes run.cmd, which runs this folder's main.qwe with that quillo,
# unless there is a run.cmd already. (A .cmd, not a .ps1: it runs in cmd and in
# PowerShell alike, with no execution policy to get past.)
#
# $env:QUILLO_VERSION = "v0.7.0" takes another release; $env:QUILLO_RELEASES
# another place to download from.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = if ($env:QUILLO_VERSION) { $env:QUILLO_VERSION } else { "v0.6.0" }
$releases = if ($env:QUILLO_RELEASES) { $env:QUILLO_RELEASES } else { "https://github.com/quillolang/quillo/releases/download" }
$bin = Join-Path $PSScriptRoot ".quillo\bin"
$exe = Join-Path $bin "quillo.exe"

# run.cmd, beside this script. One that is there already, perhaps edited, is kept.
# No ( ) block in it: a folder such as "C:\Program Files (x86)\..." would end one.
function Write-Run {
    $run = Join-Path $PSScriptRoot "run.cmd"
    if (Test-Path $run) { return }
    $lines = @(
        '@echo off',
        'rem Runs this folder''s main.qwe with the quillo in .quillo\bin\, which',
        'rem get-quillo.ps1 put there, and puts there first when it is not:',
        'rem',
        'rem   run.cmd --watch            the options are quillo run''s: --port 8081, --reload',
        'if exist "%~dp0.quillo\bin\quillo.exe" goto run',
        'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get-quillo.ps1"',
        'if errorlevel 1 exit /b 1',
        ':run',
        '"%~dp0.quillo\bin\quillo.exe" run "%~dp0main.qwe" %*'
    )
    # CRLF: cmd looks for a goto's label line by line, and LF alone can make it miss.
    [IO.File]::WriteAllText($run, ($lines -join "`r`n") + "`r`n")
    Write-Host "get-quillo: wrote run.cmd; start the program with .\run.cmd --watch"
}

# The samples, in the order they are offered.
$samples = [ordered]@{
    hello = "a page, a component and a function both sides use"
    spa = "a single-page app: tabs that change without reloading, what it holds kept between them"
    ssr = "pages made on the server: a list, forms and SQLite, working with JavaScript off"
}
$sample = if ($args.Count -ge 1) { "$($args[0])".ToLower() } else { "" }
if ($args.Count -gt 1 -or ($sample -and -not $samples.Contains($sample))) {
    Write-Host "get-quillo: which sample? get-quillo.ps1, or one of: $($samples.Keys -join ' ')"
    exit 2
}
$from = Join-Path $PSScriptRoot "samples"
if (Test-Path (Join-Path $PSScriptRoot "main.qwe")) {
    if ($sample) {
        Write-Host "get-quillo: this folder has a main.qwe, so it starts from no sample; only quillo is fetched for it"
        exit 1
    }
} elseif (-not (Test-Path $from)) {
    Write-Host "get-quillo: there is no main.qwe here and no samples\ to start one from"
    exit 1
} else {
    if (-not $sample -and -not [Console]::IsInputRedirected) {
        Write-Host "Which sample app should this folder start from?"
        $keys = @($samples.Keys)
        for ($i = 0; $i -lt $keys.Count; $i++) { Write-Host ("  {0}  {1,-6} {2}" -f ($i + 1), $keys[$i], $samples[$keys[$i]]) }
        $answer = "$(Read-Host 'Number or name [1]')".Trim().ToLower()
        if ($answer -match '^[0-9]+$' -and [int]$answer -ge 1 -and [int]$answer -le $keys.Count) { $answer = $keys[[int]$answer - 1] }
        $sample = if ($answer) { $answer } else { "hello" }
        if (-not $samples.Contains($sample)) {
            Write-Host "get-quillo: no sample `"$sample`": one of $($keys -join ' ')"
            exit 2
        }
    } elseif (-not $sample) {
        $sample = "hello"
        Write-Host "get-quillo: no terminal to ask, so the hello sample (get-quillo.ps1 spa takes another)"
    }
    # Nothing here is overwritten: a file the sample has, already here, stops it.
    $src = Join-Path $from $sample
    foreach ($f in Get-ChildItem $src -Force) {
        if (Test-Path (Join-Path $PSScriptRoot $f.Name)) {
            Write-Host "get-quillo: $($f.Name) is here already; move it away to start from the $sample sample"
            exit 1
        }
    }
    Copy-Item -Recurse (Join-Path $src "*") $PSScriptRoot
    Remove-Item -Recurse -Force $from
    Write-Host "get-quillo: this folder's program is the $sample sample now; samples\ is removed"
}

# There is an x86-64 build only; Windows 11 on ARM runs it under emulation.
$cpu = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($cpu -ne "AMD64" -and $cpu -ne "ARM64") {
    Write-Host "get-quillo: Quillo $version has no build for Windows on $cpu; build it from source instead: https://github.com/quillolang/quillo#getting-started"
    exit 1
}

if (Test-Path $exe) {
    $have = & $exe version 2>$null
    if ($have -like "quillo $($version.TrimStart('v')) *") {
        Write-Host "get-quillo: $have is already in .quillo\bin"
        Write-Run
        exit 0
    }
}

$name = "quillo-$version-x86_64-pc-windows-msvc"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
New-Item -ItemType Directory $tmp | Out-Null
try {
    foreach ($f in "$name.zip", "$name.zip.sha256") {
        try {
            Invoke-WebRequest "$releases/$version/$f" -OutFile (Join-Path $tmp $f) -UseBasicParsing
        } catch {
            Write-Host "get-quillo: cannot download $releases/$version/$f (is $version a Quillo release?)"
            exit 1
        }
    }
    $want = ((Get-Content (Join-Path $tmp "$name.zip.sha256") -Raw).Trim() -split '\s+')[0].ToLower()
    $got = (Get-FileHash (Join-Path $tmp "$name.zip") -Algorithm SHA256).Hash.ToLower()
    if ($want -ne $got) {
        Write-Host "get-quillo: $name.zip does not match its SHA-256; nothing was installed"
        exit 1
    }
    Expand-Archive (Join-Path $tmp "$name.zip") -DestinationPath $tmp
    New-Item -ItemType Directory -Force $bin | Out-Null
    # A quillo.exe that is running cannot be replaced: stop it first.
    Move-Item -Force (Join-Path $tmp "$name\quillo.exe") $exe
    Write-Host "get-quillo: $(& $exe version), in .quillo\bin"
    Write-Run
} finally {
    Remove-Item -Recurse -Force $tmp
}
