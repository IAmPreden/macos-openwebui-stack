# Open WebUI Config Export

The source deployment used the Open WebUI SQLite database at:

```text
/app/backend/data/webui.db
```

That path lives in the Docker volume named `openwebui_open-webui` on the source machine.

The portable export in `config/openwebui-settings.json` comes from the single row in the `config` table. It is a sanitized merge payload, not a copied database.

## Included

- Document RAG settings.
- Embedding settings for the local OpenAI-compatible LM Studio endpoint.
- Reranker settings for the local OpenAI-compatible LM Studio endpoint.
- Web search settings using SearXNG.
- Web loader settings using self-hosted Firecrawl.
- Query task switches related to web search and retrieval.
- Default model metadata enabling web search.

## Excluded

- Users and authentication records.
- API keys and secret values.
- Chats, messages, reactions, folders, tags, and shared chats.
- Files, documents, knowledge collections, and vector DB data.
- Open WebUI model table rows and LM Studio-specific chat model configuration.
- OAuth sessions, API keys, automation history, calendars, notes, feedback, and other user-owned data.

The bootstrap importer deep-merges the payload into a fresh Open WebUI config row after the container has created its database. Placeholders are replaced from `.env`, so each deployment gets new local keys.
