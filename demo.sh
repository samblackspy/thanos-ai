#!/bin/bash
# =============================================================================
# Thanos AI - The Self-Healing Open Source Maintainer
# Demo Reproduction Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     THANOS AI - The Self-Healing Open Source Maintainer       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# STEP 1: Start Infrastructure
# =============================================================================
step1_start_infrastructure() {
    echo -e "${YELLOW}▶ STEP 1: Starting Infrastructure${NC}"
    echo "Starting Kestra + Postgres + Cline Runner..."
    
    docker compose up -d
    
    echo "Waiting for Kestra to be ready..."
    sleep 15
    
    # Check Kestra is running
    until curl -s http://localhost:8080/api/v1/flows > /dev/null 2>&1; do
        echo "Waiting for Kestra..."
        sleep 5
    done
    
    echo -e "${GREEN}✓ Infrastructure ready${NC}"
    echo "  - Kestra UI: http://localhost:8080"
    echo "  - Credentials: admin@kestra.io / Admin1234"
    echo ""
}

# =============================================================================
# STEP 2: Verify Flows are Loaded
# =============================================================================
step2_verify_flows() {
    echo -e "${YELLOW}▶ STEP 2: Verifying Kestra Flows${NC}"
    
    flows=$(curl -s -u "admin@kestra.io:Admin1234" http://localhost:8080/api/v1/flows/thanos | python3 -c "import sys,json; d=json.load(sys.stdin); print([f['id'] for f in d])")
    
    echo "Loaded flows: $flows"
    echo -e "${GREEN}✓ Flows verified${NC}"
    echo ""
}

# =============================================================================
# STEP 3: Create a Bug in the Codebase
# =============================================================================
step3_create_bug() {
    echo -e "${YELLOW}▶ STEP 3: Creating a Bug in the Codebase${NC}"
    
    # Introduce typos in StatusBadge component
    sed -i '' 's/const config = {/const confg = {/' dashboard/src/app/page.tsx
    sed -i '' 's/label: "Running"/label: "Runnng"/' dashboard/src/app/page.tsx
    sed -i '' 's/label: "Success"/label: "Sucess"/' dashboard/src/app/page.tsx
    sed -i '' 's/label: "Failed"/label: "Faild"/' dashboard/src/app/page.tsx
    sed -i '' 's/label: "Pending"/label: "Pendng"/' dashboard/src/app/page.tsx
    sed -i '' 's/} = config\[status\]/} = confg[status]/' dashboard/src/app/page.tsx
    
    git add dashboard/src/app/page.tsx
    git commit -m "bug: introduce typos for demo"
    git push
    
    echo -e "${GREEN}✓ Bug created and pushed to GitHub${NC}"
    echo ""
}

# =============================================================================
# STEP 4: Trigger Self-Healing Pipeline
# =============================================================================
step4_trigger_pipeline() {
    echo -e "${YELLOW}▶ STEP 4: Triggering Self-Healing Pipeline${NC}"
    
    EXECUTION_ID=$(curl -s -u "admin@kestra.io:Admin1234" \
        -X POST "http://localhost:8080/api/v1/executions/trigger/thanos/self_heal_pipeline" \
        -H "Content-Type: multipart/form-data" \
        -F 'payload={"action":"opened","repository":{"full_name":"samblackspy/thanos-ai","clone_url":"https://github.com/samblackspy/thanos-ai.git"},"issue":{"number":99,"title":"Fix typos in StatusBadge","body":"In dashboard/src/app/page.tsx, fix these typos: confg to config, Runnng to Running, Sucess to Success, Faild to Failed, Pendng to Pending"}}' \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
    
    echo "Execution ID: $EXECUTION_ID"
    echo -e "${GREEN}✓ Pipeline triggered${NC}"
    echo ""
    
    export EXECUTION_ID
}

# =============================================================================
# STEP 5: Monitor Pipeline Execution
# =============================================================================
step5_monitor_pipeline() {
    echo -e "${YELLOW}▶ STEP 5: Monitoring Pipeline Execution${NC}"
    
    while true; do
        STATUS=$(curl -s -u "admin@kestra.io:Admin1234" \
            "http://localhost:8080/api/v1/executions/search?namespace=thanos&flowId=self_heal_pipeline&size=1" \
            | python3 -c "import sys,json; d=json.load(sys.stdin); e=d.get('results',[])[0] if d.get('results') else {}; print(e.get('state',{}).get('current','UNKNOWN'))")
        
        echo "Pipeline status: $STATUS"
        
        if [ "$STATUS" = "SUCCESS" ]; then
            echo -e "${GREEN}✓ Pipeline completed successfully!${NC}"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            echo -e "${RED}✗ Pipeline failed${NC}"
            break
        fi
        
        sleep 10
    done
    echo ""
}

# =============================================================================
# STEP 6: Verify PR Created
# =============================================================================
step6_verify_pr() {
    echo -e "${YELLOW}▶ STEP 6: Verifying PR Creation${NC}"
    
    git fetch origin
    
    echo "Remote branches:"
    git branch -r | grep fix || echo "No fix branches yet"
    
    echo ""
    echo "Open PRs:"
    curl -s "https://api.github.com/repos/samblackspy/thanos-ai/pulls?state=open" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'PR #{p[\"number\"]}: {p[\"title\"]}') for p in d[:5]]"
    
    echo -e "${GREEN}✓ PR verification complete${NC}"
    echo ""
}

# =============================================================================
# STEP 7: Show Dashboard
# =============================================================================
step7_show_dashboard() {
    echo -e "${YELLOW}▶ STEP 7: Dashboard${NC}"
    echo ""
    echo "Dashboard URL: https://thanosai.vercel.app"
    echo ""
    echo -e "${GREEN}✓ Open dashboard in browser to see pipeline executions${NC}"
    echo ""
}

# =============================================================================
# QUICK DEMO COMMANDS (Copy-Paste Ready)
# =============================================================================
print_quick_commands() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}QUICK DEMO COMMANDS (Copy-Paste Ready)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}# 1. Start infrastructure${NC}"
    echo "docker compose up -d"
    echo ""
    
    echo -e "${YELLOW}# 2. Check Kestra flows${NC}"
    echo 'curl -s -u "admin@kestra.io:Admin1234" http://localhost:8080/api/v1/flows/thanos | python3 -c "import sys,json; print([f[\"id\"] for f in json.load(sys.stdin)])"'
    echo ""
    
    echo -e "${YELLOW}# 3. Trigger pipeline (simulated GitHub issue)${NC}"
    cat << 'EOF'
curl -s -u "admin@kestra.io:Admin1234" \
  -X POST "http://localhost:8080/api/v1/executions/trigger/thanos/self_heal_pipeline" \
  -H "Content-Type: multipart/form-data" \
  -F 'payload={"action":"opened","repository":{"full_name":"samblackspy/thanos-ai","clone_url":"https://github.com/samblackspy/thanos-ai.git"},"issue":{"number":99,"title":"Fix typos in StatusBadge","body":"Fix typos: confg to config, Runnng to Running, Sucess to Success"}}'
EOF
    echo ""
    
    echo -e "${YELLOW}# 4. Check pipeline status${NC}"
    echo 'curl -s -u "admin@kestra.io:Admin1234" "http://localhost:8080/api/v1/executions/search?namespace=thanos&flowId=self_heal_pipeline&size=1" | python3 -c "import sys,json; d=json.load(sys.stdin); e=d.get(\"results\",[])[0]; print(f\"Status: {e[\"state\"][\"current\"]}\")"'
    echo ""
    
    echo -e "${YELLOW}# 5. Check for fix branches${NC}"
    echo "git fetch origin && git branch -r | grep fix"
    echo ""
    
    echo -e "${YELLOW}# 6. Check open PRs${NC}"
    echo 'curl -s "https://api.github.com/repos/samblackspy/thanos-ai/pulls?state=open" | python3 -c "import sys,json; [print(f\"PR #{p[\\\"number\\\"]}: {p[\\\"title\\\"]}\") for p in json.load(sys.stdin)]"'
    echo ""
    
    echo -e "${YELLOW}# 7. Open Kestra UI${NC}"
    echo "open http://localhost:8080"
    echo ""
    
    echo -e "${YELLOW}# 8. Open Dashboard${NC}"
    echo "open https://thanosai.vercel.app"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-help}" in
    start)
        step1_start_infrastructure
        step2_verify_flows
        ;;
    bug)
        step3_create_bug
        ;;
    trigger)
        step4_trigger_pipeline
        ;;
    monitor)
        step5_monitor_pipeline
        ;;
    verify)
        step6_verify_pr
        step7_show_dashboard
        ;;
    full)
        step1_start_infrastructure
        step2_verify_flows
        step3_create_bug
        step4_trigger_pipeline
        step5_monitor_pipeline
        step6_verify_pr
        step7_show_dashboard
        ;;
    commands)
        print_quick_commands
        ;;
    *)
        echo "Thanos AI Demo Script"
        echo ""
        echo "Usage: ./demo.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start     - Start infrastructure (Docker, Kestra)"
        echo "  bug       - Create a bug in the codebase"
        echo "  trigger   - Trigger the self-healing pipeline"
        echo "  monitor   - Monitor pipeline execution"
        echo "  verify    - Verify PR was created"
        echo "  full      - Run full demo end-to-end"
        echo "  commands  - Print quick copy-paste commands"
        echo ""
        echo "For video demo, run: ./demo.sh commands"
        ;;
esac

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Thanos AI - The Self-Healing Open Source Maintainer${NC}"
echo -e "${BLUE}https://github.com/samblackspy/thanos-ai${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
