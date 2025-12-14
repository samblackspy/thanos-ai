#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/kestra_webhook_run.sh --title "Test" --body "..." --poll
#
# Requires:
#   - .env file in repo root with WEBHOOK_KEY=<key>
# Optional env overrides:
#   - KESTRA_URL (default http://localhost:8080)
#   - KESTRA_TENANT (default main)
#   - KESTRA_USER (default admin@kestra.io)
#   - KESTRA_PASS (default Admin1234)
#   - NAMESPACE (default thanos)
#   - INTAKE_FLOW (default issue_opened_intake)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

KESTRA_URL=${KESTRA_URL:-http://localhost:8080}
KESTRA_TENANT=${KESTRA_TENANT:-main}
KESTRA_USER=${KESTRA_USER:-admin@kestra.io}
KESTRA_PASS=${KESTRA_PASS:-Admin1234}

NAMESPACE=${NAMESPACE:-thanos}
INTAKE_FLOW=${INTAKE_FLOW:-issue_opened_intake}

TITLE=${TITLE:-"Test: webhook"}
BODY=${BODY:-"Test run"}
REPO_FULL_NAME=${REPO_FULL_NAME:-"samblackspy/thanos-ai"}
REPO_CLONE_URL=${REPO_CLONE_URL:-"https://github.com/samblackspy/thanos-ai.git"}
ISSUE_NUMBER=${ISSUE_NUMBER:-1}
GITHUB_EVENT=${GITHUB_EVENT:-issues}

POLL=0
VERIFY_ARTIFACTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="$2"; shift 2 ;;
    --body)
      BODY="$2"; shift 2 ;;
    --repo)
      REPO_FULL_NAME="$2"; shift 2 ;;
    --clone-url)
      REPO_CLONE_URL="$2"; shift 2 ;;
    --issue-number)
      ISSUE_NUMBER="$2"; shift 2 ;;
    --github-event)
      GITHUB_EVENT="$2"; shift 2 ;;
    --poll)
      POLL=1; shift ;;
    --verify-artifacts)
      VERIFY_ARTIFACTS=1; shift ;;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${REPO_ROOT}/.env"
  set +a
fi

if [[ -z "${WEBHOOK_KEY:-}" ]]; then
  echo "Missing WEBHOOK_KEY. Add it to ${REPO_ROOT}/.env" >&2
  exit 1
fi

start_ts=$(python3 - <<'PY'
import datetime
print(datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z')
PY
)

payload_file=$(mktemp)
cat > "$payload_file" <<JSON
{
  "action": "opened",
  "repository": {
    "full_name": "${REPO_FULL_NAME}",
    "clone_url": "${REPO_CLONE_URL}"
  },
  "issue": {
    "number": ${ISSUE_NUMBER},
    "title": "${TITLE}",
    "body": "${BODY}"
  }
}
JSON

resp_file=$(mktemp)
webhook_url="${KESTRA_URL}/api/v1/executions/webhook/${NAMESPACE}/${INTAKE_FLOW}/${WEBHOOK_KEY}"

http_code=$(curl -sS -o "$resp_file" -w "%{http_code}" -X POST \
  "$webhook_url" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ${GITHUB_EVENT}" \
  --data-binary "@${payload_file}")

rm -f "$payload_file"

if [[ "$http_code" != "200" ]]; then
  echo "Webhook failed http=${http_code}" >&2
  head -c 800 "$resp_file" >&2; echo >&2
  rm -f "$resp_file"
  exit 1
fi

intake_id=$(python3 - <<PY
import json
j=json.load(open("$resp_file"))
print(j.get("id", ""))
PY
)

echo "webhook_http=${http_code}"
echo "intake_execution_id=${intake_id}"
rm -f "$resp_file"

if [[ "$POLL" -eq 0 && "$VERIFY_ARTIFACTS" -eq 0 ]]; then
  exit 0
fi

export KESTRA_URL KESTRA_TENANT NAMESPACE KESTRA_USER KESTRA_PASS
export START_TS="$start_ts"
export INTAKE_EXECUTION_ID="$intake_id"

# Find the most recent self_heal_attempt execution started after START_TS.
# We use state histories timestamps since some Kestra responses omit startDate.
python3 - <<'PY'
import base64
import datetime
import json
import os
import ssl
import time
import urllib.request

kestra_url = os.environ.get('KESTRA_URL', 'http://localhost:8080')
tenant = os.environ.get('KESTRA_TENANT', 'main')
namespace = os.environ.get('NAMESPACE', 'thanos')
start_ts = os.environ.get('START_TS')
user = os.environ.get('KESTRA_USER', 'admin@kestra.io')
passwd = os.environ.get('KESTRA_PASS', 'Admin1234')
intake_execution_id = os.environ.get('INTAKE_EXECUTION_ID')

ctx = ssl.create_default_context()
auth = base64.b64encode(f"{user}:{passwd}".encode()).decode()

def get_json(path: str):
    req = urllib.request.Request(kestra_url + path)
    req.add_header('Authorization', 'Basic ' + auth)
    with urllib.request.urlopen(req, context=ctx, timeout=20) as resp:
        return json.loads(resp.read().decode('utf-8'))

def parse_dt(s):
    if not s:
        return None
    try:
        return datetime.datetime.fromisoformat(s.replace('Z', '+00:00'))
    except Exception:
        return None

start_dt = parse_dt(start_ts)

def execution_start_dt(ex: dict):
    st = ex.get('state') or {}
    dt = parse_dt(st.get('startDate'))
    if dt:
        return dt
    hist = st.get('histories') or []
    if hist and isinstance(hist, list):
        dt = parse_dt(hist[0].get('date'))
        if dt:
            return dt
    return None

def wait_execution(execution_id: str):
    ex = None
    for _ in range(120):
        ex = get_json(f"/api/v1/{tenant}/executions/{execution_id}")
        state = (ex.get('state') or {}).get('current')
        if state not in ('CREATED', 'QUEUED', 'RUNNING'):
            return ex
        time.sleep(1)
    return ex


def find_subflow_execution_id(ex: dict, task_id: str):
    for tr in (ex.get('taskRunList') or []):
        if tr.get('taskId') != task_id:
            continue
        outs = tr.get('outputs') or {}
        if not isinstance(outs, dict):
            continue
        for k in ('executionId', 'execution_id', 'subflowExecutionId', 'subflow_execution_id'):
            v = outs.get(k)
            if v:
                return v
    return None


def wait_latest(flow_id: str):
    latest = None
    for _ in range(90):
        search = get_json(f"/api/v1/{tenant}/executions/search?namespace={namespace}&flowId={flow_id}&size=20")
        results = search.get('results') or []

        candidates = []
        for r in results:
            eid = r.get('id')
            if not eid:
                continue
            try:
                ex = get_json(f"/api/v1/{tenant}/executions/{eid}")
            except Exception:
                continue
            dt = execution_start_dt(ex)
            if start_dt and dt and dt < start_dt:
                continue
            candidates.append((dt or datetime.datetime.min.replace(tzinfo=datetime.timezone.utc), ex))

        candidates.sort(key=lambda t: t[0], reverse=True)
        if candidates:
            latest = candidates[0][1]
            state = (latest.get('state') or {}).get('current')
            if state not in ('CREATED', 'QUEUED', 'RUNNING'):
                return latest

        time.sleep(2)

    return latest


pipeline = None
if intake_execution_id:
    intake = wait_execution(intake_execution_id)
    sub_id = find_subflow_execution_id(intake, 'start_pipeline')
    if sub_id:
        pipeline = wait_execution(sub_id)

if not pipeline:
    pipeline = wait_latest('self_heal_pipeline')

if pipeline:
    print('pipeline_execution_id=' + (pipeline.get('id') or ''))
    print('pipeline_state=' + ((pipeline.get('state') or {}).get('current') or ''))

    by_task = {tr.get('taskId'): tr for tr in (pipeline.get('taskRunList') or []) if tr.get('taskId')}

    for tid in ('attempt_0', 'attempt_1'):
        tr = by_task.get(tid)
        if not tr:
            continue
        outs = tr.get('outputs') or {}
        if isinstance(outs, dict):
            sub = outs.get('outputs') or {}
            if isinstance(sub, dict) and 'exit_code' in sub:
                print(f'{tid}_exit_code=' + str(sub.get('exit_code')))

    gc = by_task.get('guard_checks')
    if gc:
        outs = gc.get('outputs') or {}
        of = outs.get('outputFiles') or {}
        if isinstance(of, dict):
            print('guard_output_files=' + ','.join(of.keys()))
    else:
        print('guard_checks=missing')

attempt = wait_latest('self_heal_attempt')
if attempt:
    print('attempt_execution_id=' + (attempt.get('id') or ''))
    print('attempt_state=' + ((attempt.get('state') or {}).get('current') or ''))
    by_task = {tr.get('taskId'): tr for tr in (attempt.get('taskRunList') or []) if tr.get('taskId')}
    bs = by_task.get('brain_strategy')
    if bs:
        outs = bs.get('outputs') or {}
        code = outs.get('code')
        print('brain_strategy_code=' + str(code))
    hc = by_task.get('hand_cline')
    if hc:
        outs = hc.get('outputs') or {}
        of = outs.get('outputFiles') or {}
        if isinstance(of, dict):
            print('hand_cline_output_files=' + ','.join(of.keys()))
PY

exit 0
