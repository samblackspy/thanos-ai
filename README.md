# thanos-ai

## Local quickstart (Kestra + Cline runner)

### Prereqs
- Docker + Docker Compose
- API key for a Cline-supported provider (this scaffold uses `OPENROUTER_API_KEY`)

### 1) Start Kestra + Postgres

```bash
docker compose up --build
```

Open:

- http://localhost:8080

### 2) Configure Kestra secrets
Create these secrets in the Kestra UI (Namespace: `thanos` or global):

- `WEBHOOK_KEY`
- `OPENROUTER_API_KEY`
- `GITHUB_TOKEN` (optional; required for private repos)

### 3) Trigger the flow
Once the flow is loaded, Kestra will expose a webhook trigger URL.
In the UI:

- Flows → `thanos.issue_opened_intake` → Triggers → copy the webhook URL

For quick testing without GitHub, you can POST a GitHub-like payload (minimum fields: `action`, `repository`, `issue`).
