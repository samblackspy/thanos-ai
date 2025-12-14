# Thanos AI

**The Self-Healing Open Source Maintainer**

Thanos AI is an autonomous system that monitors GitHub repositories, detects issues, and automatically generates fixes using AI-powered code generation. When a new issue is opened, Thanos AI springs into action—analyzing the problem, generating a fix, validating it through security and quality checks, and creating a pull request—all without human intervention.

## How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   GitHub    │────▶│    Brain    │────▶│    Hand     │────▶│    Guard    │
│   Webhook   │     │ (Together)  │     │   (Cline)   │     │  (Checks)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │                   │
                           ▼                   ▼                   ▼
                    Analyzes issue      Executes fix        Validates:
                    Creates strategy    in container        - Secret scan
                                                            - Pytest
                                                            - Pre-commit
                                                            
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
             ┌─────────────┐           ┌─────────────┐           ┌─────────────┐
             │  Create PR  │           │  AI Agent   │           │  Dashboard  │
             │  + Comment  │           │  Summary    │           │  (Vercel)   │
             └─────────────┘           └─────────────┘           └─────────────┘
```

### Architecture Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Orchestrator** | [Kestra](https://kestra.io) | Workflow orchestration with retry logic |
| **Brain** | Together AI / OpenAI | Analyzes issues and creates fix strategies |
| **Hand** | [Cline CLI](https://github.com/cline/cline) | Executes code changes headlessly in Docker |
| **Guard** | Shell scripts | Security scans, pytest, pre-commit validation |
| **AI Agent** | Kestra AI Plugin | Summarizes pipeline results and recommendations |
| **Dashboard** | Next.js + Vercel | Real-time pipeline monitoring UI |
| **Learning** | [Oumi](https://oumi.ai) | RL fine-tuning on successful fix pairs |
| **Code Review** | [CodeRabbit](https://coderabbit.ai) | AI-powered PR reviews |

### Pipeline Flow

1. **Issue Opened** → GitHub webhook triggers Kestra flow
2. **Brain Analysis** → AI analyzes issue, identifies files, creates strategy
3. **Hand Execution** → Cline CLI executes fix in isolated Docker container
4. **Guard Validation** → Secret scan, tests, linting checks
5. **Retry Logic** → If first attempt fails, retry with failure context
6. **PR Creation** → Creates pull request and comments on issue
7. **AI Summary** → Kestra AI Agent summarizes execution
8. **CodeRabbit Review** → Automated code review on PR

## Features

- **Fully Autonomous**: No human intervention required from issue to PR
- **Self-Healing**: Automatic retry with failure context for improved success
- **Secure**: Secret scanning prevents credential leaks in patches
- **Observable**: Real-time dashboard shows pipeline status
- **Learnable**: Oumi RL fine-tuning improves model over time
- **Extensible**: Modular Kestra flows for easy customization

## Tech Stack

- **Orchestration**: Kestra (Docker-based workflows)
- **AI Models**: Together AI (Llama), OpenAI (GPT-4o-mini)
- **Code Agent**: Cline CLI (headless mode)
- **Containers**: Docker + Docker Compose
- **Frontend**: Next.js 16, TailwindCSS, Vercel
- **Fine-tuning**: Oumi (DPO/SFT training)
- **Code Review**: CodeRabbit

---

## Local quickstart (Kestra + Cline runner)

### Prereqs
- Docker + Docker Compose
- API key for a Cline-supported provider (this scaffold uses `OPENAI_API_KEY`)

### 1) Start Kestra + Postgres

```bash
docker compose up --build
```

Open:

- http://localhost:8080

### 2) Configure Kestra secrets
Create these secrets in the Kestra UI (Namespace: `thanos` or global):

- `WEBHOOK_KEY`
- `OPENAI_API_KEY`
- `TOGETHER_API_KEY`
- `GITHUB_TOKEN` (optional; required for private repos)

### 3) Trigger the flow
Once the flow is loaded, Kestra will expose a webhook trigger URL.
In the UI:

- Flows → `thanos.issue_opened_intake` → Triggers → copy the webhook URL

For quick testing without GitHub, you can POST a GitHub-like payload (minimum fields: `action`, `repository`, `issue`).

## Project Structure

```
thanos-ai/
├── kestra/
│   └── flows/                    # Kestra workflow definitions
│       ├── main_thanos.issue_opened_intake.yml
│       ├── main_thanos.self_heal_attempt.yml
│       └── main_thanos.self_heal_pipeline.yml
├── dashboard/                    # Next.js monitoring dashboard
│   └── src/app/
│       ├── page.tsx              # Main dashboard UI
│       └── api/pipelines/        # Kestra API proxy
├── oumi/                         # RL fine-tuning
│   ├── configs/                  # Training configs
│   └── train_rl.py               # DPO training script
├── scripts/                      # Utility scripts
├── docker-compose.yml            # Kestra + Postgres setup
└── .coderabbit.yaml              # CodeRabbit config
```

## Links

- **Dashboard**: [thanos-ai-dashboard.vercel.app](https://dashboard-qzn2ght6t-samblackspys-projects.vercel.app)
- **GitHub**: [github.com/samblackspy/thanos-ai](https://github.com/samblackspy/thanos-ai)
- **Kestra**: http://localhost:8080 (local)

## Built For

**AssembleHack25** - WeMakeDev Hackathon

### Prize Categories

- **Kestra**: Orchestration with AI Agent, retry logic, webhook triggers
- **Oumi**: RL fine-tuning pipeline for code fixing models
- **Vercel**: Real-time monitoring dashboard
- **CodeRabbit**: Automated PR code reviews

---

*Thanos AI - Because even open source repos deserve a superhero.*
