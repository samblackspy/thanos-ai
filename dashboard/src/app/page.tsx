import { Activity, GitBranch, Shield, Zap, CheckCircle2, XCircle, Clock, ExternalLink } from "lucide-react";

type PipelineStatus = "running" | "success" | "failed" | "pending";

interface Pipeline {
  id: string;
  issueNumber: number;
  issueTitle: string;
  repo: string;
  status: PipelineStatus;
  attempts: number;
  guardStatus: PipelineStatus;
  createdAt: string;
  prUrl?: string;
}

const mockPipelines: Pipeline[] = [
  {
    id: "1za3kq4zbae4H0hragEsj3",
    issueNumber: 42,
    issueTitle: "Fix authentication bug in login flow",
    repo: "samblackspy/thanos-ai",
    status: "success",
    attempts: 1,
    guardStatus: "success",
    createdAt: "2024-12-14T10:30:00Z",
    prUrl: "https://github.com/samblackspy/thanos-ai/pull/43",
  },
  {
    id: "5ZM39zoiNcm0IVnCWOQcGF",
    issueNumber: 41,
    issueTitle: "Add rate limiting to API endpoints",
    repo: "samblackspy/thanos-ai",
    status: "running",
    attempts: 0,
    guardStatus: "pending",
    createdAt: "2024-12-14T11:00:00Z",
  },
  {
    id: "8XY12abc3def4ghi5jkl6m",
    issueNumber: 40,
    issueTitle: "Refactor database connection pooling",
    repo: "samblackspy/thanos-ai",
    status: "failed",
    attempts: 2,
    guardStatus: "failed",
    createdAt: "2024-12-14T09:15:00Z",
  },
];

function StatusBadge({ status }: { status: PipelineStatus }) {
  const config = {
    running: { icon: Clock, color: "text-blue-500 bg-blue-500/10", label: "Running" },
    success: { icon: CheckCircle2, color: "text-green-500 bg-green-500/10", label: "Success" },
    failed: { icon: XCircle, color: "text-red-500 bg-red-500/10", label: "Failed" },
    pending: { icon: Clock, color: "text-zinc-400 bg-zinc-400/10", label: "Pending" },
  };
  const { icon: Icon, color, label } = config[status];
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${color}`}>
      <Icon className="w-3.5 h-3.5" />
      {label}
    </span>
  );
}

function PipelineCard({ pipeline }: { pipeline: Pipeline }) {
  return (
    <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-5 hover:border-zinc-300 dark:hover:border-zinc-700 transition-colors">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-zinc-500">#{pipeline.issueNumber}</span>
          <StatusBadge status={pipeline.status} />
        </div>
        <span className="text-xs text-zinc-400">
          {new Date(pipeline.createdAt).toLocaleTimeString()}
        </span>
      </div>
      
      <h3 className="font-semibold text-zinc-900 dark:text-zinc-100 mb-2 line-clamp-1">
        {pipeline.issueTitle}
      </h3>
      
      <p className="text-sm text-zinc-500 mb-4">{pipeline.repo}</p>
      
      <div className="flex items-center gap-4 text-sm">
        <div className="flex items-center gap-1.5 text-zinc-500">
          <Zap className="w-4 h-4" />
          <span>Attempt {pipeline.attempts + 1}</span>
        </div>
        <div className="flex items-center gap-1.5">
          <Shield className="w-4 h-4" />
          <StatusBadge status={pipeline.guardStatus} />
        </div>
      </div>
      
      {pipeline.prUrl && (
        <a
          href={pipeline.prUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-4 inline-flex items-center gap-1.5 text-sm text-purple-600 dark:text-purple-400 hover:underline"
        >
          <GitBranch className="w-4 h-4" />
          View PR
          <ExternalLink className="w-3 h-3" />
        </a>
      )}
    </div>
  );
}

export default function Home() {
  const stats = {
    total: mockPipelines.length,
    success: mockPipelines.filter((p) => p.status === "success").length,
    running: mockPipelines.filter((p) => p.status === "running").length,
    failed: mockPipelines.filter((p) => p.status === "failed").length,
  };

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-black">
      <header className="border-b border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-950">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-600 to-pink-600 flex items-center justify-center">
              <Activity className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-xl text-zinc-900 dark:text-white">Thanos AI</h1>
              <p className="text-xs text-zinc-500">Self-Healing Maintainer</p>
            </div>
          </div>
          <a
            href="https://github.com/samblackspy/thanos-ai"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-zinc-500 hover:text-zinc-900 dark:hover:text-white transition-colors"
          >
            GitHub
          </a>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-8">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-4">
            <p className="text-sm text-zinc-500 mb-1">Total Pipelines</p>
            <p className="text-2xl font-bold text-zinc-900 dark:text-white">{stats.total}</p>
          </div>
          <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-4">
            <p className="text-sm text-zinc-500 mb-1">Success</p>
            <p className="text-2xl font-bold text-green-500">{stats.success}</p>
          </div>
          <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-4">
            <p className="text-sm text-zinc-500 mb-1">Running</p>
            <p className="text-2xl font-bold text-blue-500">{stats.running}</p>
          </div>
          <div className="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-4">
            <p className="text-sm text-zinc-500 mb-1">Failed</p>
            <p className="text-2xl font-bold text-red-500">{stats.failed}</p>
          </div>
        </div>

        <h2 className="text-lg font-semibold text-zinc-900 dark:text-white mb-4">Recent Pipelines</h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {mockPipelines.map((pipeline) => (
            <PipelineCard key={pipeline.id} pipeline={pipeline} />
          ))}
        </div>
      </main>

      <footer className="border-t border-zinc-200 dark:border-zinc-800 mt-12">
        <div className="max-w-6xl mx-auto px-6 py-6 text-center text-sm text-zinc-500">
          Built for AssembleHack25 | Powered by Cline, Kestra, Oumi, Vercel, CodeRabbit
        </div>
      </footer>
    </div>
  );
}
