#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env. Run scripts/bootstrap.sh first." >&2
  exit 1
fi

if [[ ! -f config/openwebui-settings.json ]]; then
  echo "Missing config/openwebui-settings.json" >&2
  exit 1
fi

compose() {
  docker compose --env-file "$ROOT_DIR/.env" "$@"
}

container_id=""
for _ in $(seq 1 120); do
  container_id="$(compose ps -q open-webui || true)"
  if [[ -n "$container_id" ]] && docker inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null | grep -q true; then
    break
  fi
  sleep 2
done

if [[ -z "$container_id" ]]; then
  echo "open-webui service is not running." >&2
  exit 1
fi

compose cp "$ROOT_DIR/config/openwebui-settings.json" open-webui:/tmp/openwebui-settings.json >/dev/null

compose exec -T open-webui python - <<'PY'
import datetime as dt
import json
import os
import sqlite3
import sys
import time

DB_PATH = "/app/backend/data/webui.db"
SETTINGS_PATH = "/tmp/openwebui-settings.json"

replacements = {
    "__LM_STUDIO_BASE_URL__": os.environ.get("LM_STUDIO_BASE_URL", "http://host.docker.internal:1234/v1"),
    "__LM_STUDIO_API_KEY__": os.environ.get("LM_STUDIO_API_KEY", "sk-local-placeholder"),
    "__LM_STUDIO_EMBEDDING_MODEL__": os.environ.get("LM_STUDIO_EMBEDDING_MODEL", "text-embedding-bge-m3"),
    "__LM_STUDIO_RERANKER_MODEL__": os.environ.get("LM_STUDIO_RERANKER_MODEL", "text-embedding-bge-reranker-v2-m3"),
    "__FIRECRAWL_API_URL__": os.environ.get("FIRECRAWL_API_BASE_URL", "http://firecrawl-api:3002"),
    "__FIRECRAWL_API_KEY__": os.environ.get("FIRECRAWL_API_KEY", "fc-local-placeholder"),
}

def replace_placeholders(value):
    if isinstance(value, dict):
        return {key: replace_placeholders(item) for key, item in value.items()}
    if isinstance(value, list):
        return [replace_placeholders(item) for item in value]
    if isinstance(value, str):
        return replacements.get(value, value)
    return value

def deep_merge(target, source):
    for key, value in source.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            deep_merge(target[key], value)
        else:
            target[key] = value
    return target

def unresolved_placeholders(value, path=""):
    found = []
    if isinstance(value, dict):
        for key, item in value.items():
            child_path = f"{path}.{key}" if path else key
            found.extend(unresolved_placeholders(item, child_path))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            found.extend(unresolved_placeholders(item, f"{path}[{index}]"))
    elif isinstance(value, str) and value.startswith("__") and value.endswith("__"):
        found.append((path, value))
    return found

with open(SETTINGS_PATH, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

if payload.get("schema") != 1:
    print("Unsupported settings payload schema.", file=sys.stderr)
    sys.exit(1)

merge_payload = replace_placeholders(payload["merge"])
unresolved = unresolved_placeholders(merge_payload)
if unresolved:
    for path, value in unresolved:
        print(f"Unresolved placeholder at {path}: {value}", file=sys.stderr)
    sys.exit(1)

for _ in range(120):
    if not os.path.exists(DB_PATH):
        time.sleep(2)
        continue
    try:
        con = sqlite3.connect(DB_PATH, timeout=30)
        con.execute("select 1 from sqlite_master where type='table' and name='config'").fetchone()
        break
    except sqlite3.Error:
        time.sleep(2)
else:
    print("Open WebUI database was not ready in time.", file=sys.stderr)
    sys.exit(1)

cur = con.cursor()
if cur.execute("select 1 from sqlite_master where type='table' and name='config'").fetchone() is None:
    print("Open WebUI config table does not exist yet.", file=sys.stderr)
    sys.exit(1)

row = cur.execute("select id, data, version from config order by id limit 1").fetchone()
now = dt.datetime.utcnow().isoformat(sep=" ")

if row is None:
    data = {}
    deep_merge(data, merge_payload)
    cur.execute(
        "insert into config (id, data, version, created_at, updated_at) values (?, ?, ?, ?, ?)",
        (1, json.dumps(data, separators=(",", ":")), 0, now, now),
    )
else:
    config_id, raw_data, version = row
    data = json.loads(raw_data or "{}")
    deep_merge(data, merge_payload)
    cur.execute(
        "update config set data = ?, version = ?, updated_at = ? where id = ?",
        (json.dumps(data, separators=(",", ":")), version if version is not None else 0, now, config_id),
    )

con.commit()
con.close()
print("Imported sanitized Open WebUI RAG, web search, and reranker settings.")
PY

compose restart open-webui >/dev/null
echo "Restarted open-webui after settings import."
