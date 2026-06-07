# macOS Open WebUI Stack

Portable Docker Compose stack for recreating the source `~/docker/openwebui` deployment on another machine without copying users, chats, credentials, API tokens, TLS assets, or database secrets.

The default target is macOS with OrbStack and LM Studio. The Compose file should also work with Docker Desktop or a Linux Docker host, provided `host.docker.internal` resolves back to the host inference runtime.

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
git clone https://github.com/IAmPreden/macos-openwebui-stack.git
cd macos-openwebui-stack
scripts/bootstrap.sh
```

Then open `http://localhost:3000` and create the first Open WebUI account.

If you are running this on the original source Mac, stop the existing stack first or change the ports because the source deployment already uses `3000`, `8888`, and `3002`.

## Required Local Setup

- OrbStack or Docker Desktop.
- Docker Compose v2.
- LM Studio with the local OpenAI-compatible server enabled if using the default inference setup.
- The models listed in [docs/inference.md](docs/inference.md), or your own replacement models.

See [docs/dependencies.md](docs/dependencies.md) for the full dependency list.

## Default URLs

- Open WebUI: `http://localhost:3000`
- SearXNG: `http://localhost:8888`
- Firecrawl API: `http://localhost:3002`
- LM Studio API from inside containers: `http://host.docker.internal:1234/v1`

## Generated Secrets

`scripts/bootstrap.sh` creates `.env` from `.env.example`, generates new values, and keeps `.env` out of git. It also creates `searxng/settings.yml` from `searxng/settings.yml.template`.

Generated values include:

- `WEBUI_SECRET_KEY`
- `SEARXNG_SECRET_KEY`
- `BULL_AUTH_KEY`
- `POSTGRES_PASSWORD`
- `FIRECRAWL_API_KEY`
- `LM_STUDIO_API_KEY`

The `LM_STUDIO_API_KEY` and `FIRECRAWL_API_KEY` values are local placeholders for services that are running without cloud authentication. They are generated anyway so Open WebUI fields are populated without reusing source-machine values.

## Settings Import

The Open WebUI settings payload is stored in `config/openwebui-settings.json`. During bootstrap, `scripts/apply-openwebui-settings.sh` copies it into the running Open WebUI container, merges it into `/app/backend/data/webui.db`, and restarts Open WebUI.

Run the importer again after editing `.env` model names or base URLs:

```sh
scripts/apply-openwebui-settings.sh
```

More detail is in [docs/openwebui-config.md](docs/openwebui-config.md).

## Publishing The GitHub Repo

This local workspace can be published after creating the GitHub repository. The GitHub connector available in this Codex session can inspect repos and write files, but it does not expose repository creation, and `gh` is not installed locally.

One terminal path is:

```sh
brew install gh
gh auth login
gh repo create IAmPreden/macos-openwebui-stack --private --source . --remote origin --push
```

Use `--public` instead of `--private` if this is intended to be public.
