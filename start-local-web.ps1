param(
  [int]$Port = 3000
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebDir = Join-Path $Root 'web'

$env:DIFY_LIGHT_DEV = '1'

Push-Location $WebDir
try {
  npm run dev:vinext -- --host localhost --port $Port
}
finally {
  Pop-Location
}
