#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

START_STACK=1
APPLY_SETTINGS=1
PULL_IMAGES=1

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [options]

Options:
  --no-start    Generate local config files but do not start Docker services.
  --no-import   Start services but do not import the sanitized Open WebUI settings.
  --no-pull     Skip docker compose pull.
  -h, --help    Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-start)
      START_STACK=0
      ;;
    --no-import)
      APPLY_SETTINGS=0
      ;;
    --no-pull)
      PULL_IMAGES=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

rand_hex() {
  local bytes="$1"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$bytes"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$bytes" <<'PY'
import secrets, sys
print(secrets.token_hex(int(sys.argv[1])))
PY
  else
    echo "Neither openssl nor python3 is available for secret generation." >&2
    exit 1
  fi
}

get_env_value() {
  local key="$1"
  [[ -f .env ]] || return 0
  awk -v key="$key" '
    index($0, key "=") == 1 {
      sub("^[^=]*=", "")
      value = $0
    }
    END { print value }
  ' .env
}

set_env_value() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { done = 0 }
    index($0, key "=") == 1 {
      print key "=" value
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        print key "=" value
      }
    }
  ' .env > "$tmp"
  mv "$tmp" .env
}

is_placeholder() {
  local value="${1:-}"
  [[ -z "$value" || "$value" == CHANGE_ME* || "$value" == __* ]]
}

ensure_value() {
  local key="$1"
  local default="$2"
  local current
  current="$(get_env_value "$key")"
  if is_placeholder "$current"; then
    set_env_value "$key" "$default"
  fi
}

ensure_secret() {
  local key="$1"
  local prefix="$2"
  local bytes="$3"
  local current
  current="$(get_env_value "$key")"
  if is_placeholder "$current"; then
    set_env_value "$key" "${prefix}$(rand_hex "$bytes")"
  fi
}

need_command docker
docker compose version >/dev/null
docker info >/dev/null

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

ensure_value COMPOSE_PROJECT_NAME macos-openwebui
ensure_value OPENWEBUI_PORT 3000
ensure_value SEARXNG_PORT 8888
ensure_value FIRECRAWL_PORT 3002
ensure_value OPENWEBUI_IMAGE_TAG main
ensure_value FIRECRAWL_IMAGE_TAG latest
ensure_value FIRECRAWL_PLAYWRIGHT_IMAGE_TAG latest
ensure_value FIRECRAWL_POSTGRES_IMAGE_TAG latest
ensure_value WEBUI_URL http://localhost:3000
ensure_value AIOHTTP_CLIENT_TIMEOUT 600
ensure_value ENABLE_RETRIEVAL_UNSCOPED_COLLECTIONS true
ensure_value BYPASS_RETRIEVAL_ACCESS_CONTROL true
ensure_value LM_STUDIO_BASE_URL http://host.docker.internal:1234/v1
ensure_value LM_STUDIO_EMBEDDING_MODEL text-embedding-bge-m3
ensure_value LM_STUDIO_RERANKER_MODEL text-embedding-bge-reranker-v2-m3
ensure_value FIRECRAWL_API_BASE_URL http://firecrawl-api:3002
ensure_value POSTGRES_DB postgres
ensure_value POSTGRES_USER postgres
ensure_value WATCHTOWER_SCHEDULE "0 0 3 * * 0"

ensure_secret WEBUI_SECRET_KEY "" 32
ensure_secret SEARXNG_SECRET_KEY "" 32
ensure_secret BULL_AUTH_KEY "" 32
ensure_secret POSTGRES_PASSWORD "" 24
ensure_secret FIRECRAWL_API_KEY "fc-local-" 24
ensure_secret LM_STUDIO_API_KEY "sk-local-" 24

chmod 600 .env

mkdir -p searxng
awk -v secret="$(get_env_value SEARXNG_SECRET_KEY)" '
  { gsub("__SEARXNG_SECRET_KEY__", secret); print }
' searxng/settings.yml.template > searxng/settings.yml
chmod 600 searxng/settings.yml

echo "Generated local .env and searxng/settings.yml"

if [[ "$START_STACK" -eq 0 ]]; then
  echo "Skipped Docker start because --no-start was supplied."
  exit 0
fi

if [[ "$PULL_IMAGES" -eq 1 ]]; then
  docker compose --env-file .env pull
fi

docker compose --env-file .env up -d

if [[ "$APPLY_SETTINGS" -eq 1 ]]; then
  "$ROOT_DIR/scripts/apply-openwebui-settings.sh"
else
  echo "Skipped Open WebUI settings import because --no-import was supplied."
fi

cat <<EOF

Stack is starting.

Open WebUI:  http://localhost:$(get_env_value OPENWEBUI_PORT)
SearXNG:     http://localhost:$(get_env_value SEARXNG_PORT)
Firecrawl:   http://localhost:$(get_env_value FIRECRAWL_PORT)

Create the first Open WebUI account in the browser. No users or chats were imported.
EOF
