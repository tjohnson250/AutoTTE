# Auto-Protocol Designer

An autonomous agent system that discovers causal questions from the clinical
literature and generates target trial emulation protocols, with independent
review loops at every stage.

## Architecture

```
                    ┌─────────────────────┐
                    │  controller.py      │
                    │  (state machine)    │
                    └────────┬────────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                  │
           ▼                 ▼                  ▼
    ┌─────────────┐  ┌─────────────┐   ┌─────────────┐
    │  Discovery  │  │ Feasibility │   │  Protocol   │
    │   Agent     │  │   Agent     │   │   Agent     │
    └──────┬──────┘  └──────┬──────┘   └──────┬──────┘
           │                │                  │
           ▼                ▼                  ▼
    ┌─────────────┐  ┌─────────────┐   ┌─────────────┐
    │  Discovery  │  │ Feasibility │   │  Protocol   │
    │  Reviewer   │  │  Reviewer   │   │  Reviewer   │
    └──────┬──────┘  └──────┬──────┘   └──────┬──────┘
           │                │                  │
           ▼                ▼                  ▼
       verdict.json     verdict.json       verdict.json
       ┌────────┐       ┌────────┐         ┌────────┐
       │accept? │       │accept? │         │accept? │
       │revise? ↻       │revise? ↻         │revise? ↻
       │back?───────────→back?─────────────→back?   │
       └────────┘       └────────┘         └────────┘
```

Each phase cycles: **work → review → revise → re-review → ...** until the
reviewer accepts. Reviewers can also trigger **backtracking** to an earlier
phase if they find fundamental problems.

Every agent invocation is an **independent Claude Code session** — the reviewer
has no access to the worker's reasoning, only its output files. This prevents
the reviewer from being anchored to the worker's assumptions.

## How It Works

1. **Discovery Agent** searches PubMed for RCTs and observational studies,
   extracts PICO questions, identifies evidence gaps.

2. **Discovery Reviewer** independently verifies every PMID by re-fetching
   abstracts, checks PICO accuracy, does supplemental searches for missed studies.
   Emits a verdict: accept, revise, or backtrack.

3. **Feasibility Agent** matches approved questions to public datasets
   (MIMIC-IV, NHANES, MEPS, etc.), assesses variable availability and
   positivity concerns.

4. **Feasibility Reviewer** verifies dataset claims, checks that only
   approved questions were used. Can backtrack to discovery if questions
   themselves are problematic.

5. **Protocol Agent** generates full target trial emulation protocols with
   R analysis plans following Hernán & Robins.

6. **Protocol Reviewer** checks for immortal time bias, positivity violations,
   estimand misspecification, and reviews R code. Can backtrack to feasibility
   or discovery.

7. **Summary Agent** writes an executive summary including the review history.

## Quick Start

```bash
# 1. Install prerequisites
npm install -g @anthropic-ai/claude-code
pip install mcp httpx lxml

# 2. Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 3. Run it
./run.sh "atrial fibrillation"

# With custom max turns per agent pass (default 50)
./run.sh "atrial fibrillation" 75

# Resume an interrupted run
./run.sh "atrial fibrillation" --resume
```

## File Structure

```
AutoTTE/
├── CLAUDE.md              # Agent instructions (domain expertise)
├── REVIEW.md              # Reviewer instructions (verification protocol)
├── .mcp.json              # MCP server configuration
├── run.sh                 # Launch script
├── analysis_plan_template.R  # Reference R template
├── tools/
│   ├── controller.py      # State machine orchestrator
│   ├── pubmed_server.py   # MCP server: PubMed + dataset registry
│   └── stream_viewer.py   # Streaming output formatter
└── results/               # Agent outputs (created at runtime)
    └── atrial_fibrillation/
        ├── agent_state.json            # Pipeline state (for resume)
        ├── 01_literature_scan.md
        ├── 02_evidence_gaps.md
        ├── discovery_review.md
        ├── discovery_review_verdict.json
        ├── 03_feasibility.md
        ├── feasibility_review.md
        ├── feasibility_review_verdict.json
        ├── protocols/
        │   ├── protocol_01.md
        │   ├── protocol_01_analysis.R
        │   ├── protocol_01_review.md
        │   └── ...
        ├── protocol_review_verdict.json
        └── summary.md
```

## Extending

- **Add datasets**: Edit `DATASET_REGISTRY` in `tools/pubmed_server.py`
- **Add tools**: New `@mcp.tool()` functions (e.g., ClinicalTrials.gov)
- **Adjust review rigor**: Edit thresholds in `REVIEW.md`
- **Change max revision cycles**: Edit `MAX_REVISIONS_PER_PHASE` in `controller.py`
- **Connect your CDW**: Add a CDW MCP server alongside PubMed
