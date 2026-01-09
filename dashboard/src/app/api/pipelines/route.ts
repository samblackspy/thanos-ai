import { NextResponse } from "next/server";

const KESTRA_URL = process.env.KESTRA_URL || "http://localhost:8080";
const KESTRA_AUTH = process.env.KESTRA_AUTH || "admin@kestra.io:Admin1234";
const FETCH_TIMEOUT_MS = 10000;

interface KPipelineExecution {
  id: string;
  state?: { current?: string; startDate?: string };
  inputs?: { payload?: { issue?: { number?: number; title?: string }; repository?: { full_name?: string } } };
  taskRunList?: Array<{ taskId?: string; state?: { current?: string }; outputs?: { outputs?: { exit_code?: number } } }>;
}

async function fetchWithTimeout(url: string, options: RequestInit, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    return response;
  } finally {
    clearTimeout(timeoutId);
  }
}

export async function GET() {
  try {
    const authHeader = `Basic ${Buffer.from(KESTRA_AUTH).toString("base64")}`;
    
    const response = await fetchWithTimeout(
      `${KESTRA_URL}/api/v1/main/executions?namespace=thanos&flowId=self_heal_pipeline&size=20`,
      {
        headers: {
          Authorization: authHeader,
          Accept: "application/json",
        },
        cache: "no-store",
      },
      FETCH_TIMEOUT_MS
    );

    if (!response.ok) {
      console.error(`Kestra API returned ${response.status}: ${response.statusText}`);
      return NextResponse.json(
        { error: `Kestra API error: ${response.status}`, details: response.statusText },
        { status: response.status }
      );
    }

    const data = await response.json();
    const executions = data.results || [];

    const pipelines = executions.map((exec: Record<string, unknown>) => {
      const state = (exec.state as Record<string, unknown>)?.current || "unknown";
      const inputs = exec.inputs as Record<string, unknown> || {};
      const payload = inputs.payload as Record<string, unknown> || {};
      const issue = payload.issue as Record<string, unknown> || {};
      const repo = payload.repository as Record<string, unknown> || {};

      const taskRuns = (exec.taskRunList as Array<Record<string, unknown>>) || [];
      const byTask: Record<string, Record<string, unknown>> = {};
      for (const tr of taskRuns) {
        const taskId = tr.taskId as string;
        if (taskId) byTask[taskId] = tr;
      }

      const attempt0 = byTask["attempt_0"];
      const attempt1 = byTask["attempt_1"];
      const guard = byTask["guard_checks"];

      let exitCode = null;
      let attempts = 0;
      if (attempt0) {
        const outs = (attempt0.outputs as Record<string, unknown>)?.outputs as Record<string, unknown> || {};
        exitCode = outs.exit_code;
        attempts = 1;
      }
      if (attempt1) {
        const outs = (attempt1.outputs as Record<string, unknown>)?.outputs as Record<string, unknown> || {};
        exitCode = outs.exit_code;
        attempts = 2;
      }

      let guardStatus = "pending";
      if (guard) {
        const gstate = (guard.state as Record<string, unknown>)?.current;
        guardStatus = gstate === "SUCCESS" ? "success" : gstate === "FAILED" ? "failed" : "running";
      }

      return {
        id: exec.id,
        issueNumber: issue.number || 0,
        issueTitle: (issue.title as string) || "Unknown issue",
        repo: (repo.full_name as string) || "unknown/repo",
        status: state === "SUCCESS" ? "success" : state === "FAILED" ? "failed" : state === "RUNNING" ? "running" : "pending",
        attempts,
        exitCode,
        guardStatus,
        createdAt: (exec.state as Record<string, unknown>)?.startDate || new Date().toISOString(),
      };
    });

    return NextResponse.json({ pipelines });
  } catch (error) {
    console.error("Failed to fetch from Kestra:", error);
    return NextResponse.json(
      { error: "Failed to connect to Kestra API", pipelines: [] },
      { status: 500 }
    );
  }
}
