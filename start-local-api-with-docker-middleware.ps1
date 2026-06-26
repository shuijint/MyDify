param(
  [switch]$SkipDocker
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$DockerDir = Join-Path $Root 'docker'
$ApiDir = Join-Path $Root 'api'
$DockerEnv = Join-Path $DockerDir '.env'
$StorageRoot = Join-Path $DockerDir 'volumes\app\storage'

if (-not $SkipDocker) {
  docker info *> $null
  if ($LASTEXITCODE -ne 0) {
    throw 'Docker Engine is not ready. Start Docker Desktop first, then run this script again.'
  }

  Push-Location $DockerDir
  try {
    docker compose -f docker-compose.middleware.yaml up -d
  }
  finally {
    Pop-Location
  }
}

$secretLine = Select-String -Path $DockerEnv -Pattern '^SECRET_KEY=' | Select-Object -First 1
if (-not $secretLine) {
  throw 'SECRET_KEY not found in docker/.env'
}

$pluginDaemonKeyLine = Select-String -Path $DockerEnv -Pattern '^PLUGIN_DAEMON_KEY=' | Select-Object -First 1
if (-not $pluginDaemonKeyLine) {
  throw 'PLUGIN_DAEMON_KEY not found in docker/.env'
}

$pluginInnerKeyLine = Select-String -Path $DockerEnv -Pattern '^PLUGIN_DIFY_INNER_API_KEY=' | Select-Object -First 1
if (-not $pluginInnerKeyLine) {
  throw 'PLUGIN_DIFY_INNER_API_KEY not found in docker/.env'
}

$env:SECRET_KEY = $secretLine.Line.Substring('SECRET_KEY='.Length)
$env:EDITION = 'SELF_HOSTED'
$env:DEPLOY_ENV = 'DEVELOPMENT'

$env:DB_TYPE = 'postgresql'
$env:DB_USERNAME = 'postgres'
$env:DB_PASSWORD = 'difyai123456'
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '5433'
$env:DB_DATABASE = 'dify'

$env:REDIS_HOST = '127.0.0.1'
$env:REDIS_PORT = '6379'
$env:REDIS_PASSWORD = 'difyai123456'
$env:REDIS_DB = '0'
$env:CELERY_BROKER_URL = 'redis://:difyai123456@127.0.0.1:6379/1'
$env:CELERY_BACKEND = 'redis'
$env:BROKER_USE_SSL = 'false'

$env:CONSOLE_CORS_ALLOW_ORIGINS = '*'
$env:WEB_API_CORS_ALLOW_ORIGINS = '*'
$env:CONSOLE_WEB_URL = 'http://localhost:3000'
$env:CONSOLE_API_URL = 'http://localhost:5001'
$env:SERVICE_API_URL = 'http://localhost:5001'
$env:APP_API_URL = 'http://localhost:5001'
$env:APP_WEB_URL = 'http://localhost:3000'
$env:FILES_URL = 'http://localhost:5001'
$env:INTERNAL_FILES_URL = 'http://localhost:5001'

$env:STORAGE_TYPE = 'opendal'
$env:OPENDAL_SCHEME = 'fs'
$env:OPENDAL_FS_ROOT = $StorageRoot

$env:VECTOR_STORE = 'weaviate'
$env:WEAVIATE_ENDPOINT = 'http://localhost:8080'
$env:WEAVIATE_GRPC_ENDPOINT = 'grpc://localhost:50051'
$env:WEAVIATE_API_KEY = 'WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih'
$env:WEAVIATE_TOKENIZATION = 'word'

$env:PLUGIN_DAEMON_URL = 'http://localhost:5002'
$env:PLUGIN_DAEMON_KEY = $pluginDaemonKeyLine.Line.Substring('PLUGIN_DAEMON_KEY='.Length)
$env:INNER_API_KEY_FOR_PLUGIN = $pluginInnerKeyLine.Line.Substring('PLUGIN_DIFY_INNER_API_KEY='.Length)

$env:LOG_OUTPUT_FORMAT = 'text'
$env:LOG_FORMAT = '%(asctime)s.%(msecs)03d %(levelname)s [%(threadName)s] [%(filename)s:%(lineno)d] %(trace_id)s - %(message)s'

Push-Location $ApiDir
try {
  uv run --project . flask --app app run --host 0.0.0.0 --port 5001
}
finally {
  Pop-Location
}
