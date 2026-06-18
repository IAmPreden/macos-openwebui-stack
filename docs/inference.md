# Inference Setup

The default inference target is oMLX with its OpenAI-compatible server enabled.

The imported Open WebUI settings expect:

- Base URL: `http://host.docker.internal:8000/v1`
- Embedding model: `text-embedding-bge-m3`
- Reranker model: `text-embedding-bge-reranker-v2-m3`

oMLX listens on `http://localhost:8000/v1` on the Mac by default. Docker containers reach that host process through `http://host.docker.internal:8000/v1`.

The local oMLX server does not require a cloud API key for this setup, so `.env` defaults `OMLX_API_KEY` to `not-needed`.

## Installing oMLX

Use the native macOS app or Homebrew install from the [oMLX project](https://github.com/jundot/omlx). The project site is [omlx.ai](https://omlx.ai/).

```sh
brew tap jundot/omlx https://github.com/jundot/omlx
brew install omlx
omlx start
```

Or run it in the foreground with an explicit model directory:

```sh
omlx serve --model-dir ~/models
```

The oMLX admin dashboard is available at `http://localhost:8000/admin`, and its built-in chat UI is at `http://localhost:8000/admin/chat`.

## Models Observed On The Source Machine

These model identifiers were observed in the existing Open WebUI database and are documented so the next deployer knows what to download or expose in oMLX:

- Chat: `qwen3.6-35b-a3b-ud-mlx`
- Chat: `openai/gpt-oss-20b`
- Embeddings: `text-embedding-bge-m3`
- Reranker: `text-embedding-bge-reranker-v2-m3`
- Previously present hidden embeddings: `text-embedding-nomic-embed-text-v1.5`, `text-embedding-nomic-embed-text-v2-moe`

The repository does not import Open WebUI's LLM model table rows. The first admin user should add or refresh model/provider connections in Open WebUI after oMLX is running.

## Changing Inference Platform

For another OpenAI-compatible runtime, edit `.env`:

```sh
OMLX_BASE_URL=http://host.docker.internal:8000/v1
OMLX_API_KEY=not-needed
OMLX_EMBEDDING_MODEL=text-embedding-bge-m3
OMLX_RERANKER_MODEL=text-embedding-bge-reranker-v2-m3
```

Then run:

```sh
scripts/apply-openwebui-settings.sh
```

For non-OpenAI-compatible embedding or reranker providers, use Open WebUI's admin UI after bootstrap and update the RAG settings manually. The exported config intentionally focuses on RAG, web search, and reranking rather than locking the deployment to one LLM provider.
