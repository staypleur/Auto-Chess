param([switch]$Setup)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not (Get-Command node -ErrorAction SilentlyContinue) -or -not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    throw 'Install Node.js 24 with npm, then open a new PowerShell window.'
}
function Invoke-Npm {
    param([string[]]$Arguments)
    & npm.cmd @Arguments
    if ($LASTEXITCODE -ne 0) { throw "npm step failed: $($Arguments -join ' ')" }
}
if (-not (Test-Path -LiteralPath '.env')) {
    Copy-Item -LiteralPath '.env.local.example' -Destination '.env'
    Write-Host 'Created .env. Fill Firebase values locally; see docs/LOCAL-KO.md.'
}
if ($Setup) {
    Invoke-Npm -Arguments @('ci')
    Invoke-Npm -Arguments @('run', 'assetpack')
}
Invoke-Npm -Arguments @('run', 'local:doctor')
Write-Host 'Open http://localhost:9000 after the server starts. Ctrl+C stops the server.'
Invoke-Npm -Arguments @('run', 'dev')
