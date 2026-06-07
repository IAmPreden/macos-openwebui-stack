# Dependencies

This stack is intended for macOS first, especially an OrbStack-backed Docker setup, but the Compose file is Linux-friendly as long as Docker supports `host.docker.internal`.

## Required

- macOS on Apple Silicon or Intel.
- OrbStack, recommended, or Docker Desktop.
- Docker Compose v2, available as `docker compose`.
- LM Studio if using the default local inference setup.
- Git, for cloning and publishing the repo.
- `openssl` or `python3`, used by `scripts/bootstrap.sh` to generate fresh local secrets.

## Optional

- GitHub CLI `gh`, only needed if you want to create and push the GitHub repository from the terminal.
- Homebrew, useful for installing `gh` or other local tools.

## Services

- Open WebUI: `ghcr.io/open-webui/open-webui:main`
- SearXNG: `searxng/searxng:latest`
- Firecrawl API: `ghcr.io/firecrawl/firecrawl:latest`
- Firecrawl Playwright service: `ghcr.io/firecrawl/playwright-service:latest`
- Firecrawl Postgres: `ghcr.io/firecrawl/nuq-postgres:latest`
- Redis: `redis:alpine`
- RabbitMQ: `rabbitmq:3-management`
- Watchtower: `nickfedor/watchtower`

## Ports

- Open WebUI: `3000`
- SearXNG: `8888`
- Firecrawl API: `3002`, bound to `127.0.0.1`

Change these in `.env` before running `scripts/bootstrap.sh` if the target machine already uses the same ports.
