# Auto-Protocol Designer

An autonomous multi-agent system that discovers causal questions from the
clinical literature and generates target trial emulation protocols — with
independent review loops driven by agent judgment, not hardcoded logic.

## Architecture

```
                 ┌──────────────────────────────┐
                 │     Coordinator Agent         │
                 │     (Claude Code session)     │
                 │                               │
                 │  Reads COORDINATOR.md         │
                 │  Launches sub-agents          │
                 │  Reads their output files     │
                 │  Decides: advance / revise /  │
                 │           backtrack           │
                 └──────┬───────────────┬────────┘
                        │               │
            ┌───────────┘               └───────────┐
            ▼                                       ▼
   ┌─────────────────┐                    ┌─────────────────┐
   │  Worker Agents   │                    │ Reviewer Agents  │
   │  (claude -p)     │                    │  (claude -p)     │
   │                  │                    │                  │
   │  Read WORKER.md  │                    │  Read REVIEW.md  │
   │  Search PubMed   │ ── files on ──→   │  Verify PMIDs    │
   │  Write protocols │    disk            │  Check methods   │
   │  Generate R code │                    │  Write critiques │
   └──────────────────┘                    └──────────────────┘
```

**No hardcoded state machine.** The coordinator agent decides when work is
good enough to advance, when it needs revision, and when to backtrack to an
earlier phase. It evaluates sub-agent output against objective acceptance
criteria defined in COORDINATOR.md, but the judgment and routing are the
agent's own.

**Independent review.** Every reviewer runs in a fresh Claude Code session
with no access to the worker's reasoning — only the output files. This
prevents anchoring and enables genuine error detection.

## How It Works

The coordinator runs as a long-lived Claude Code session. It launches
sub-agents (workers and reviewers) by calling `claude -p` in bash, reads
their output files, and decides what to do next.

A typical run looks like:

1. Coordinator launches **Discovery Worker** → searches PubMed, extracts
   PICO questions, identifies evidence gaps
2. Coordinator reads the output, checks acceptance criteria
3. Coordinator launches **Discovery Reviewer** → verifies PMIDs, checks
   PICO accuracy, does supplemental searches
4. Coordinator reads the review, decides: accept / revise / backtrack
5. If revise: re-launches worker with review notes. If accept: moves to
   feasibility. Repeat the pattern for each phase.

The coordinator logs every decision to `coordinator_log.md` and tracks
state in `agent_state.json` for transparency and debugging.

## Quick Start

```bash
# 1. Install prerequisites
npm install -g @anthropic-ai/claude-code
pip install mcp httpx lxml

# 2. Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 3. Run it
./run.sh "atrial fibrillation"

# With custom max turns per sub-agent (default 50)
./run.sh "atrial fibrillation" 75
```

## File Structure

```
AutoTTE/
├── CLAUDE.md              # Router — points agents to their instructions
├── COORDINATOR.md         # Coordinator agent instructions + acceptance criteria
├── WORKER.md              # Worker agent instructions + domain expertise
├── REVIEW.md              # Reviewer agent instructions + verification protocol
├── .mcp.json              # MCP server configuration (PubMed tools)
├── run.sh                 # Launch script
├── analysis_plan_template.R  # Reference R template
├── tools/
│   ├── pubmed_server.py   # MCP server: PubMed + dataset registry
│   └── stream_viewer.py   # Streaming output formatter
└── results/               # Agent outputs (created at runtime)
    └── atrial_fibrillation/
        ├── agent_state.json         # Coordinator state
        ├── coordinator_log.md       # Decision log
        ├── 01_literature_scan.md
        ├── 02_evidence_gaps.md
        ├── discovery_review.md
        ├── 03_feasibility.md
        ├── feasibility_review.md
        ├── protocols/
        │   ├── protocol_01.md
        │   ├── protocol_01_analysis.R
        │   ├── protocol_01_review.md
        │   └── ...
        └── summary.md
```

## Extending

- **Add datasets**: Edit `DATASET_REGISTRY` in `tools/pubmed_server.py`
- **Add tools**: New `@mcp.tool()` functions (e.g., ClinicalTrials.gov)
- **Adjust acceptance criteria**: Edit rubrics in `COORDINATOR.md`
- **Adjust review rigor**: Edit standards in `REVIEW.md`
- **Connect your CDW**: Add a CDW MCP server alongside PubMed in `.mcp.json`

## Design Principles

1. **Agent-driven orchestration.** The coordinator is an LLM, not a script.
   It can adapt to unexpected situations, make nuanced quality judgments,
   and route work based on content — not just exit codes.

2. **Independent review.** Reviewers get fresh context. They can't be
   anchored by the worker's reasoning or self-assessment.

3. **Objective criteria with subjective judgment.** COORDINATOR.md defines
   acceptance checklists, but the coordinator applies them with judgment —
   the same way a PI reviews a postdoc's work.

4. **Transparency.** Every decision is logged. The coordinator_log.md and
   agent_state.json create a full audit trail of the run.

5. **Graceful degradation.** Guardrails (max revisions, max backtracks)
   prevent infinite loops, but they're guidelines for the coordinator's
   judgment, not hardcoded limits.
