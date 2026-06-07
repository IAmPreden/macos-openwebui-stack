# Inference Setup

The default inference target is LM Studio with its OpenAI-compatible server enabled.

The imported Open WebUI settings expect:

- Base URL: `http://host.docker.internal:1234/v1`
- Embedding model: `text-embedding-bge-m3`
- Reranker model: `text-embedding-bge-reranker-v2-m3`

LM Studio usually accepts any API key for local OpenAI-compatible requests. The bootstrap script generates a fresh dummy value as `LM_STUDIO_API_KEY`; it is not copied from the source machine.

## Models Observed On The Source Machine

These model identifiers were observed in the existing Open WebUI database and are documented so the next deployer knows what to download or expose in LM Studio:

- Chat: `qwen3.6-35b-a3b-ud-mlx`
- Chat: `openai/gpt-oss-20b`
- Embeddings: `text-embedding-bge-m3`
- Reranker: `text-embedding-bge-reranker-v2-m3`
- Previously present hidden embeddings: `text-embedding-nomic-embed-text-v1.5`, `text-embedding-nomic-embed-text-v2-moe`

The repository does not import Open WebUI's LLM model table rows. The first admin user should add or refresh model/provider connections in Open WebUI after LM Studio is running.

## Changing Inference Platform

For another OpenAI-compatible runtime, edit `.env`:

```sh
LM_STUDIO_BASE_URL=http://host.docker.internal:1234/v1
LM_STUDIO_API_KEY=replace-with-runtime-key-or-dummy-local-key
LM_STUDIO_EMBEDDING_MODEL=text-embedding-bge-m3
LM_STUDIO_RERANKER_MODEL=text-embedding-bge-reranker-v2-m3
```

Then run:

```sh
scripts/apply-openwebui-settings.sh
```

For non-OpenAI-compatible embedding or reranker providers, use Open WebUI's admin UI after bootstrap and update the RAG settings manually. The exported config intentionally focuses on RAG, web search, and reranking rather than locking the deployment to one LLM provider.
