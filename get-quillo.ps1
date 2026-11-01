# Puts the quillo this program is written for in .quillo\bin\, the release's
# build for Windows, checked against the SHA-256 published beside it.
#
#   powershell -ExecutionPolicy Bypass -File get-quillo.ps1   then  .quillo\bin\quillo.exe run --watch
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
} finally {
    Remove-Item -Recurse -Force $tmp
}
