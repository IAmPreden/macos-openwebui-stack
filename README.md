# macOS Open WebUI

Portable Docker Compose stack for recreating the source `~/docker/openwebui` deployment on another machine without copying users, chats, credentials, API tokens, TLS assets, or database secrets.

The default target is macOS with OrbStack and oMLX. The Compose file should also work with Docker Desktop or a Linux Docker host, provided `host.docker.internal` resolves back to the host inference runtime.

## What This Carries

- Open WebUI, SearXNG, Firecrawl, Redis, RabbitMQ, Firecrawl Postgres, and Watchtower services.
- A SearXNG config template matching the source search settings.
- A sanitized Open WebUI config payload for Document RAG, web search, Firecrawl loading, and external reranking.
- Bootstrap scripts that generate fresh local secrets and import the sanitized settings into a new Open WebUI database.

## What This Does Not Carry

- Users, auth records, API keys, OAuth sessions, chats, messages, files, documents, knowledge collections, vector database data, TLS certs, or credentials.
- Open WebUI LLM provider/model rows. The deploying user chooses and configures their own inference platform.

## Quick Start

```sh
git clone https://github.com/NickUrquhart/macos-openwebui.git
cd macos-openwebui
scripts/bootstrap.sh
```

Then open `http://localhost:3000` and create the first Open WebUI account.

If you are running this on the original source Mac, stop the existing stack first or change the ports because the source deployment already uses `3000`, `8888`, and `3002`.

## Required Local Setup

- OrbStack or Docker Desktop.
- Docker Compose v2.
- oMLX with the local OpenAI-compatible server enabled if using the default inference setup.
- The models listed in [docs/inference.md](docs/inference.md), or your own replacement models.

See [docs/dependencies.md](docs/dependencies.md) for the full dependency list.

## Default URLs

- Open WebUI: `http://localhost:3000`
- SearXNG: `http://localhost:8888`
- Firecrawl API: `http://localhost:3002`
- oMLX API from inside containers: `http://host.docker.internal:8000/v1`

## Generated Secrets

`scripts/bootstrap.sh` creates `.env` from `.env.example`, generates new values, and keeps `.env` out of git. It also creates `searxng/settings.yml` from `searxng/settings.yml.template`.

Generated values include:

- `WEBUI_SECRET_KEY`
- `SEARXNG_SECRET_KEY`
- `BULL_AUTH_KEY`
- `POSTGRES_PASSWORD`
- `FIRECRAWL_API_KEY`

The default `OMLX_API_KEY` value is `not-needed` because the local oMLX server does not require a cloud API key. `FIRECRAWL_API_KEY` is generated as a local placeholder so Open WebUI fields are populated without reusing source-machine values.

## Settings Import

The Open WebUI settings payload is stored in `config/openwebui-settings.json`. During bootstrap, `scripts/apply-openwebui-settings.sh` copies it into the running Open WebUI container, merges it into `/app/backend/data/webui.db`, and restarts Open WebUI.

Run the importer again after editing `.env` model names or base URLs:

```sh
scripts/apply-openwebui-settings.sh
```

More detail is in [docs/openwebui-config.md](docs/openwebui-config.md).

## Repository

This repository is public:

https://github.com/NickUrquhart/macos-openwebui

Fork it, clone it, or transfer it to a corporate GitHub organization as needed. Runtime secrets are generated locally by `scripts/bootstrap.sh` and are not committed.
