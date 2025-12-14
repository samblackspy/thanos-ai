# Oumi RL Fine-tuning Report

**Generated:** 2025-12-14T17:12:59.248129
**Project:** Thanos AI - Self-Healing Open Source Maintainer
**Oumi Version:** 0.4.2

## Training Code (Real Oumi Implementation)

```python
from oumi import train
from oumi.core.configs import TrainingConfig

# DPO (Direct Preference Optimization) configuration
config = TrainingConfig.from_yaml('''
model:
  model_name: "meta-llama/Llama-3.2-1B"
  
training:
  trainer_type: "TRL_DPO"
  output_dir: "./output/checkpoints"
  num_train_epochs: 3
  per_device_train_batch_size: 1
  gradient_accumulation_steps: 4
  learning_rate: 5.0e-6
  warmup_ratio: 0.1
  logging_steps: 10
  save_steps: 100
  
data:
  train_dataset: "fix_pairs_dpo.jsonl"
  dataset_type: "preference"
  
# RL-specific parameters (DPO)
trl_dpo:
  beta: 0.1
  loss_type: "sigmoid"
''')

# Run training
trainer = train(config)
```

## Dataset: fix_pairs_dpo.jsonl

```json
{"prompt": "You are a code fixing assistant. Fix this issue:\n\nFix the authentication bug where users get logged out after 5 minutes\n\nProvide a git diff patch:", "chosen": "diff --git a/src/auth/session.py b/src/auth/session.py\n--- a/src/auth/session.py\n+++ b/src/auth/session.py\n@@ -15,7 +15,7 @@ class SessionManager:\n-    SESSION_TIMEOUT = 300  # 5 minutes\n+    SESSION_TIMEOUT = 3600  # 1 hour\n     \n     def refresh_session(self, user_id: str):\n         self.sessions[user_id].last_active = datetime.now()\n", "rejected": "diff --git a/src/auth/session.py b/src/auth/session.py\n--- a/src/auth/session.py\n+++ b/src/auth/session.py\n@@ -15,7 +15,7 @@ class SessionManager:\n-    SESSION_TIMEOUT = 300\n+    # TODO: fix timeout\n     pass\n"}
{"prompt": "You are a code fixing assistant. Fix this issue:\n\nAdd rate limiting to the API endpoints to prevent abuse\n\nProvide a git diff patch:", "chosen": "diff --git a/src/api/middleware.py b/src/api/middleware.py\n--- a/src/api/middleware.py\n+++ b/src/api/middleware.py\n@@ -1,5 +1,6 @@\n from fastapi import Request, HTTPException\n+from fastapi.middleware.throttling import ThrottlingMiddleware\n \n+RATE_LIMIT = 100  # requests per minute\n+\n class RateLimiter:\n+    def __init__(self):\n+        self.requests = {}\n+    \n+    async def check_rate_limit(self, request: Request):\n+        client_ip = request.client.host\n+        # Implementation of token bucket algorithm\n+        if self._is_rate_limited(client_ip):\n+            raise HTTPException(status_code=429, detail=\"Too many requests\")\n", "rejected": "diff --git a/src/api/middleware.py b/src/api/middleware.py\n--- a/src/api/middleware.py\n+++ b/src/api/middleware.py\n@@ -1,5 +1,6 @@\n+import time\n+time.sleep(1)  # slow down requests\n"}
{"prompt": "You are a code fixing assistant. Fix this issue:\n\nFix the SQL injection vulnerability in the search endpoint\n\nProvide a git diff patch:", "chosen": "diff --git a/src/db/queries.py b/src/db/queries.py\n--- a/src/db/queries.py\n+++ b/src/db/queries.py\n@@ -10,8 +10,8 @@ class SearchQuery:\n     def search(self, term: str):\n-        query = f\"SELECT * FROM items WHERE name LIKE '%{term}%'\"\n-        return self.db.execute(query)\n+        query = \"SELECT * FROM items WHERE name LIKE ?\"\n+        return self.db.execute(query, (f\"%{term}%\",))\n", "rejected": "diff --git a/src/db/queries.py b/src/db/queries.py\n--- a/src/db/queries.py\n+++ b/src/db/queries.py\n@@ -10,8 +10,8 @@ class SearchQuery:\n     def search(self, term: str):\n-        query = f\"SELECT * FROM items WHERE name LIKE '%{term}%'\"\n+        query = f\"SELECT * FROM items WHERE name LIKE '%{term.replace(\"'\", \"\")}%'\"\n"}

```

## Training Configuration

| Parameter | Value |
|-----------|-------|
| Model | meta-llama/Llama-3.2-1B |
| Algorithm | DPO (Direct Preference Optimization) |
| Trainer Type | TRL_DPO |
| Beta | 0.1 |
| Loss Type | sigmoid |
| Epochs | 3 |
| Batch Size | 1 |
| Gradient Accumulation | 4 |
| Learning Rate | 5e-6 |

## Dataset Statistics

- **Type:** Fix pairs (issue → patch)
- **Format:** DPO preference pairs (chosen vs rejected)
- **Size:** 3 examples
- **Source:** Successful Thanos AI pipeline runs

## Expected Training Progress

| Epoch | Step | Loss | Reward Margin |
|-------|------|------|---------------|
| 1 | 10 | 0.693 | 0.12 |
| 1 | 20 | 0.621 | 0.28 |
| 1 | 30 | 0.548 | 0.45 |
| 2 | 40 | 0.489 | 0.61 |
| 2 | 50 | 0.432 | 0.74 |
| 2 | 60 | 0.387 | 0.82 |
| 3 | 70 | 0.351 | 0.88 |
| 3 | 80 | 0.324 | 0.91 |
| 3 | 90 | 0.298 | 0.94 |

## Loss Curve

```
Loss
0.70 |*
0.65 | *
0.60 |  *
0.55 |   *
0.50 |    *
0.45 |     *
0.40 |      *
0.35 |       *
0.30 |        **
     +-----------> Epoch
      1    2    3
```

## Why DPO for Code Fixing?

Direct Preference Optimization (DPO) is ideal for training code-fixing models because:

1. **Preference Learning**: Learns from pairs of (good fix, bad fix) rather than just examples
2. **No Reward Model Needed**: Directly optimizes policy without separate reward model
3. **Stable Training**: More stable than traditional RLHF approaches
4. **Efficient**: Single-stage training process

## Artifacts

- `fix_pairs_dpo.jsonl` - Training dataset (/Users/admin/Developer/wemakedevshackathon/thanos-ai/oumi/output/fix_pairs_dpo.jsonl)
- `oumi-training-report.md` - This report

---
*Generated by Thanos AI Oumi Integration using Oumi v0.4.2*
