"""
Auto-Protocol Designer — State Machine Controller
===================================================
Orchestrates independent Claude Code agents through iterative review loops.

Each main phase (discovery, feasibility, protocol) cycles through:
    work → review → revise → re-review → ... until accepted

The controller is deliberately simple — it manages state transitions and
reads verdict files. All intelligence lives in the agents.

Usage:
    python tools/controller.py --area "atrial fibrillation" --max-turns 50
"""

import argparse
import json
import os
import re
import subprocess
import sys
import textwrap
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_REVISIONS_PER_PHASE = 3     # prevent infinite loops
STREAM_VIEWER = Path(__file__).parent / "stream_viewer.py"

# ANSI colors
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
RESET = "\033[0m"


# ---------------------------------------------------------------------------
# State Machine
# ---------------------------------------------------------------------------

# Phases and their allowed transitions
PHASES = [
    "discovery",
    "discovery_review",
    "feasibility",
    "feasibility_review",
    "protocol",
    "protocol_review",
    "summary",
    "done",
]


@dataclass
class AgentState:
    """Tracks the pipeline's progress through phases."""
    therapeutic_area: str
    results_dir: str
    current_phase: str = "discovery"
    revision_counts: dict = field(default_factory=lambda: {
        "discovery": 0,
        "feasibility": 0,
        "protocol": 0,
    })
    history: list = field(default_factory=list)  # log of all transitions
    total_agent_calls: int = 0

    def save(self):
        path = Path(self.results_dir) / "agent_state.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(asdict(self), indent=2))

    @classmethod
    def load(cls, path: str) -> "AgentState":
        data = json.loads(Path(path).read_text())
        return cls(**data)

    def log_transition(self, from_phase: str, to_phase: str, reason: str):
        self.history.append({
            "from": from_phase,
            "to": to_phase,
            "reason": reason,
            "timestamp": datetime.now().isoformat(),
            "agent_call": self.total_agent_calls,
        })


@dataclass
class Verdict:
    """Structured result from a review agent."""
    status: str         # "accept", "revise", "backtrack"
    phase_reviewed: str
    issues: list        # list of issue descriptions
    backtrack_to: str = ""  # only if status == "backtrack"
    summary: str = ""

    @classmethod
    def from_file(cls, path: Path) -> Optional["Verdict"]:
        """Parse a verdict JSON file written by a review agent."""
        if not path.exists():
            return None
        try:
            data = json.loads(path.read_text())
            return cls(**data)
        except (json.JSONDecodeError, TypeError):
            return None


# ---------------------------------------------------------------------------
# Agent Runner
# ---------------------------------------------------------------------------

def run_agent(
    prompt: str,
    results_dir: str,
    max_turns: int,
    allowed_tools: str,
    pass_name: str,
) -> bool:
    """Run a single Claude Code agent pass. Returns True if it completed."""

    print(f"\n{BOLD}{'━' * 60}{RESET}")
    print(f"{BOLD}  {pass_name}{RESET}")
    print(f"{BOLD}{'━' * 60}{RESET}\n")

    cmd = [
        "claude", "-p",
        "--verbose",
        "--max-turns", str(max_turns),
        "--output-format", "stream-json",
        "--allowedTools", allowed_tools,
    ]

    # Pipe prompt via stdin, stream output through viewer
    viewer_cmd = ["python3", str(STREAM_VIEWER)]

    claude_proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    )
    viewer_proc = subprocess.Popen(
        viewer_cmd,
        stdin=claude_proc.stdout,
        cwd=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    )

    claude_proc.stdin.write(prompt.encode())
    claude_proc.stdin.close()
    claude_proc.stdout.close()  # allow SIGPIPE

    viewer_proc.wait()
    return_code = claude_proc.wait()

    if return_code == 0:
        print(f"\n  {GREEN}✓ {pass_name} complete{RESET}\n")
    else:
        print(f"\n  {YELLOW}⚠ {pass_name} exited with code {return_code}{RESET}\n")

    return return_code == 0


# ---------------------------------------------------------------------------
# Phase Prompts
# ---------------------------------------------------------------------------

def get_work_prompt(phase: str, state: AgentState, revision_notes: str = "") -> str:
    """Generate the prompt for a work phase."""
    area = state.therapeutic_area
    rd = state.results_dir
    iteration = state.revision_counts.get(phase, 0)

    revision_context = ""
    if revision_notes:
        revision_context = f"""
IMPORTANT: This is revision #{iteration} of this phase. A reviewer found issues
with your previous work. Read the review notes carefully and address every issue.

Review notes are in the files described below. Fix the problems and regenerate
your output files.
"""

    prompts = {
        "discovery": f"""You are a clinical research methodologist. Your task is to search the
literature in the therapeutic area: "{area}"

Read CLAUDE.md for detailed instructions on your role and output format.
{revision_context}
{"Read " + rd + "/discovery_review_verdict.json and " + rd + "/discovery_review.md for specific issues to fix." if revision_notes else ""}

Steps:
1. Use search_pubmed to find recent RCTs (last 10 years) in this area.
   Try multiple queries to cover the landscape.
2. Use fetch_abstracts to retrieve abstracts for the most relevant PMIDs.
3. Use search_pubmed again for observational/cohort studies on similar questions.
4. Fetch those abstracts too.
5. For each study, extract the causal question in PICO format.
6. Identify evidence gaps: questions studied observationally but with
   limited or no RCT evidence.
7. Rank questions by evidence gap score (1-10).

Save to:
- {rd}/01_literature_scan.md
- {rd}/02_evidence_gaps.md

Include PMIDs for every claim. Do not fabricate PMIDs or study results.""",

        "feasibility": f"""You are a clinical data scientist assessing dataset feasibility for target
trial emulations in: "{area}"

Read CLAUDE.md for your role and output format.
{revision_context}
{"Read " + rd + "/feasibility_review_verdict.json and " + rd + "/feasibility_review.md for specific issues to fix." if revision_notes else ""}

Steps:
1. Read {rd}/02_evidence_gaps.md for the approved questions.
   {"Also read " + rd + "/discovery_review.md — only work with questions that passed review." if not revision_notes else ""}
2. For each approved question, use query_dataset_registry and get_dataset_details
   to find public datasets that could support a target trial emulation.
3. Assess: exposure variables, outcome capture, confounder availability,
   sample size, positivity concerns, time granularity for time-zero.
4. Use WebSearch if needed for dataset documentation specifics.

Save to {rd}/03_feasibility.md with:
- For each question: datasets considered, pros/cons
- Final list of feasible question-dataset pairs with confidence ratings
- Data gaps and what data would be needed""",

        "protocol": f"""You are a causal inference researcher writing target trial emulation protocols
following Hernán & Robins for: "{area}"

Read CLAUDE.md for detailed protocol format requirements.
{revision_context}
{"Read " + rd + "/protocol_review_verdict.json and the protocol_NN_review.md files for specific issues to fix." if revision_notes else ""}

Steps:
1. Read {rd}/03_feasibility.md for feasible question-dataset pairs.
2. For each feasible pair, generate a complete protocol:
   - {rd}/protocols/protocol_NN.md (full protocol)
   - {rd}/protocols/protocol_NN_analysis.R (R analysis script)

Each protocol must include all sections from CLAUDE.md. The R code must be
complete and runnable. Use analysis_plan_template.R as a structural reference.

Be precise about time zero. Think carefully about immortal time bias.
Specify the estimand (ATE vs ATT) and justify the choice.""",
    }

    return prompts[phase]


def get_review_prompt(phase: str, state: AgentState) -> str:
    """Generate the prompt for a review phase."""
    area = state.therapeutic_area
    rd = state.results_dir
    iteration = state.revision_counts.get(phase, 0)

    prompts = {
        "discovery": f"""You are an independent reviewer verifying clinical literature analysis.
Read REVIEW.md for your detailed review instructions.

Therapeutic area: "{area}"
This is review round #{iteration + 1} for the discovery phase.

Read these files:
- {rd}/01_literature_scan.md
- {rd}/02_evidence_gaps.md
{"- " + rd + "/discovery_review.md (your prior review — check if issues were fixed)" if iteration > 0 else ""}

VERIFICATION STEPS:

1. PMID VERIFICATION: For every PMID cited, use fetch_abstracts to retrieve
   the actual abstract. Check that the PMID exists and findings match.

2. PICO VERIFICATION: Check population, intervention, comparator, outcome
   accuracy against the actual abstracts.

3. GAP SCORE VERIFICATION: Do targeted search_pubmed queries to look for
   studies the agent may have missed. Are gap scores reasonable?

Save your detailed review to: {rd}/discovery_review.md

CRITICAL — ALSO save a machine-readable verdict to: {rd}/discovery_review_verdict.json
The verdict MUST be valid JSON in exactly this format:
{{
  "status": "accept" or "revise" or "backtrack",
  "phase_reviewed": "discovery",
  "issues": ["list of specific issues found"],
  "backtrack_to": "",
  "summary": "one paragraph overall assessment"
}}

Use "accept" only if all PMIDs verified and PICO extractions are accurate.
Use "revise" if there are fixable errors.
Use "backtrack" only if the approach is fundamentally flawed (unlikely here).""",

        "feasibility": f"""You are an independent reviewer verifying dataset feasibility assessments.
Read REVIEW.md for your detailed review instructions.

Therapeutic area: "{area}"
This is review round #{iteration + 1} for the feasibility phase.

Read:
- {rd}/03_feasibility.md
- {rd}/02_evidence_gaps.md (to verify the right questions were used)
- {rd}/discovery_review.md (to check only approved questions were included)
{"- " + rd + "/feasibility_review.md (your prior review — check if issues were fixed)" if iteration > 0 else ""}

VERIFICATION STEPS:

1. Did the agent use only questions that passed the discovery review?
2. For each dataset match, verify the claimed variables actually exist.
   Use get_dataset_details and WebSearch to check dataset documentation.
3. Are positivity concerns adequately addressed?
4. Is the time-zero feasibility assessment realistic?
5. Were important datasets overlooked?

Save your review to: {rd}/feasibility_review.md

CRITICAL — ALSO save a verdict to: {rd}/feasibility_review_verdict.json
{{
  "status": "accept" or "revise" or "backtrack",
  "phase_reviewed": "feasibility",
  "issues": ["list of specific issues"],
  "backtrack_to": "discovery" (if the questions themselves need reworking) or "",
  "summary": "one paragraph assessment"
}}

Use "backtrack" with backtrack_to="discovery" if the approved questions
themselves are problematic and need to be re-derived.""",

        "protocol": f"""You are an independent methodologist reviewing target trial emulation protocols.
Read REVIEW.md for your detailed review instructions.

Therapeutic area: "{area}"
This is review round #{iteration + 1} for the protocol phase.

Review every protocol in {rd}/protocols/ (both .md and .R files).
{"Also read prior review files (protocol_NN_review.md) to check if issues were fixed." if iteration > 0 else ""}

CHECK FOR:
1. IMMORTAL TIME BIAS — Is time zero correctly defined?
2. ELIGIBILITY/TREATMENT ALIGNMENT — Any look-ahead bias?
3. POSITIVITY VIOLATIONS — Deterministic treatment in subgroups?
4. ESTIMAND — ATE vs ATT justified?
5. CONFOUNDER SUFFICIENCY — Unmeasured confounding acknowledged?
6. R CODE — Correct WeightIt/cobalt usage, robust SEs, bootstrap CIs, E-values?

For each protocol, write: {rd}/protocols/protocol_NN_review.md
Score each: ACCEPT, REVISE, or REJECT.

CRITICAL — ALSO save an overall verdict to: {rd}/protocol_review_verdict.json
{{
  "status": "accept" or "revise" or "backtrack",
  "phase_reviewed": "protocol",
  "issues": ["list of specific issues across all protocols"],
  "backtrack_to": "feasibility" (if dataset choices are wrong) or "discovery" (if questions are wrong) or "",
  "summary": "one paragraph assessment"
}}

Use "accept" only if ALL protocols pass or the passing ones are sufficient.
Use "revise" if protocols have fixable issues.
Use "backtrack" if the dataset matches or questions themselves are flawed.""",
    }

    return prompts[phase]


def get_summary_prompt(state: AgentState) -> str:
    rd = state.results_dir
    history_str = json.dumps(state.history, indent=2)

    return f"""You are a senior research director writing an executive summary for
an automated target trial emulation project on: "{state.therapeutic_area}"

Read ALL files in {rd}/ including literature scans, reviews, feasibility,
protocols, protocol reviews, and any revision history.

Also, here is the pipeline execution history showing how the agent iterated:
{history_str}

Write {rd}/summary.md containing:

1. Overview: therapeutic area, papers scanned, questions identified
2. Pipeline Process: how many review cycles each phase went through,
   what issues were caught and fixed (this demonstrates the system's rigor)
3. Key Findings: most promising evidence gaps, ranked by importance/feasibility
4. Protocols Generated: for each, the question, dataset, approach, and
   final reviewer verdict
5. Data Gaps: important questions without feasible public data
6. Methodological Notes: recurring issues flagged by reviewers
7. Recommended Next Steps

Write in a clear, professional tone suitable for a research team lead.
Highlight where the review process caught and corrected errors — this is
a key selling point of the system."""


# ---------------------------------------------------------------------------
# State Machine Logic
# ---------------------------------------------------------------------------

def read_verdict(results_dir: str, phase: str) -> Verdict:
    """Read the verdict file for a given phase."""
    verdict_file = Path(results_dir) / f"{phase}_review_verdict.json"
    verdict = Verdict.from_file(verdict_file)
    if verdict is None:
        # If the review agent didn't produce a verdict, assume revise
        print(f"  {YELLOW}⚠ No verdict file found at {verdict_file}{RESET}")
        print(f"  {YELLOW}  Defaulting to 'revise' to be safe{RESET}")
        return Verdict(
            status="revise",
            phase_reviewed=phase,
            issues=["Review agent did not produce a verdict file"],
            summary="No verdict file produced",
        )
    return verdict


def next_phase(state: AgentState, verdict: Optional[Verdict] = None) -> str:
    """Determine the next phase based on current state and verdict."""
    phase = state.current_phase

    # Work phases always advance to their review
    if phase in ("discovery", "feasibility", "protocol"):
        return f"{phase}_review"

    # Review phases depend on the verdict
    if phase == "discovery_review":
        if verdict and verdict.status == "accept":
            return "feasibility"
        elif verdict and verdict.status == "backtrack":
            return "discovery"  # redo discovery from scratch
        else:
            return "discovery"  # revise

    if phase == "feasibility_review":
        if verdict and verdict.status == "accept":
            return "protocol"
        elif verdict and verdict.status == "backtrack":
            target = verdict.backtrack_to or "discovery"
            return target
        else:
            return "feasibility"

    if phase == "protocol_review":
        if verdict and verdict.status == "accept":
            return "summary"
        elif verdict and verdict.status == "backtrack":
            target = verdict.backtrack_to or "feasibility"
            return target
        else:
            return "protocol"

    if phase == "summary":
        return "done"

    return "done"


def run_pipeline(therapeutic_area: str, max_turns: int):
    """Main pipeline loop."""
    results_dir = f"results/{therapeutic_area.replace(' ', '_').lower()}"
    os.makedirs(f"{results_dir}/protocols", exist_ok=True)

    allowed_tools = (
        "mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts,"
        "mcp__pubmed__query_dataset_registry,mcp__pubmed__get_dataset_details,"
        "Bash,Read,Write,Edit,WebSearch,WebFetch"
    )

    state = AgentState(
        therapeutic_area=therapeutic_area,
        results_dir=results_dir,
    )
    state.save()

    print(f"\n{BOLD}{'═' * 60}{RESET}")
    print(f"{BOLD}  Auto-Protocol Designer{RESET}")
    print(f"{BOLD}  Therapeutic area: {therapeutic_area}{RESET}")
    print(f"{BOLD}  Results: {results_dir}/{RESET}")
    print(f"{BOLD}{'═' * 60}{RESET}")

    while state.current_phase != "done":
        phase = state.current_phase
        base_phase = phase.replace("_review", "")

        # ── Check revision limits ──
        if base_phase in state.revision_counts:
            if state.revision_counts[base_phase] > MAX_REVISIONS_PER_PHASE:
                print(f"\n  {YELLOW}⚠ Hit max revisions ({MAX_REVISIONS_PER_PHASE}) "
                      f"for {base_phase}. Accepting current results and moving on.{RESET}")
                state.log_transition(phase, next_phase(state, Verdict(
                    status="accept", phase_reviewed=base_phase,
                    issues=["Max revisions reached"], summary="Forced accept"
                )), "max revisions reached")
                # Force advance past the review
                if phase.endswith("_review"):
                    state.current_phase = next_phase(state, Verdict(
                        status="accept", phase_reviewed=base_phase,
                        issues=[], summary=""
                    ))
                else:
                    state.current_phase = f"{phase}_review"
                state.save()
                continue

        # ── Run the appropriate agent ──
        if phase.endswith("_review"):
            # Review phase
            prompt = get_review_prompt(base_phase, state)
            pass_name = f"Review: {base_phase} (round {state.revision_counts[base_phase] + 1})"
        elif phase == "summary":
            prompt = get_summary_prompt(state)
            pass_name = "Executive Summary"
        else:
            # Work phase
            is_revision = state.revision_counts[phase] > 0
            revision_notes = "yes" if is_revision else ""
            prompt = get_work_prompt(phase, state, revision_notes)
            pass_name = f"{phase.title()}" + (f" (revision {state.revision_counts[phase]})" if is_revision else "")

        state.total_agent_calls += 1
        run_agent(prompt, results_dir, max_turns, allowed_tools, pass_name)

        # ── Determine next phase ──
        old_phase = state.current_phase

        if phase.endswith("_review"):
            verdict = read_verdict(results_dir, base_phase)
            print(f"\n  {BOLD}Verdict: {verdict.status.upper()}{RESET}")
            if verdict.summary:
                wrapped = textwrap.fill(verdict.summary, width=70,
                                        initial_indent="  ", subsequent_indent="  ")
                print(f"{DIM}{wrapped}{RESET}")
            if verdict.issues:
                print(f"  {DIM}Issues: {len(verdict.issues)}{RESET}")

            new_phase = next_phase(state, verdict)

            # Track revisions
            if verdict.status in ("revise", "backtrack"):
                target = verdict.backtrack_to or base_phase if verdict.status == "backtrack" else base_phase
                state.revision_counts[target] = state.revision_counts.get(target, 0) + 1

            state.log_transition(old_phase, new_phase, f"{verdict.status}: {verdict.summary[:100]}")
        else:
            new_phase = next_phase(state)
            state.log_transition(old_phase, new_phase, "phase complete")

        state.current_phase = new_phase
        state.save()

    # ── Done ──
    print(f"\n{GREEN}{BOLD}{'═' * 60}{RESET}")
    print(f"{GREEN}{BOLD}  Pipeline Complete{RESET}")
    print(f"{GREEN}{BOLD}  Total agent calls: {state.total_agent_calls}{RESET}")
    print(f"{GREEN}{BOLD}  Results: {results_dir}/{RESET}")
    print(f"{GREEN}{BOLD}{'═' * 60}{RESET}\n")

    # Print transition history
    print(f"{DIM}Execution history:{RESET}")
    for h in state.history:
        arrow = "→"
        if "backtrack" in h.get("reason", "").lower():
            arrow = f"{RED}↩{RESET}"
        elif "revise" in h.get("reason", "").lower():
            arrow = f"{YELLOW}↻{RESET}"
        print(f"  {DIM}{h['from']}{RESET} {arrow} {h['to']}  {DIM}({h['reason'][:60]}){RESET}")


# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Auto-Protocol Designer Controller")
    parser.add_argument("--area", required=True, help="Therapeutic area")
    parser.add_argument("--max-turns", type=int, default=50, help="Max turns per agent pass")
    parser.add_argument("--resume", action="store_true", help="Resume from saved state")
    args = parser.parse_args()

    if args.resume:
        results_dir = f"results/{args.area.replace(' ', '_').lower()}"
        state_path = f"{results_dir}/agent_state.json"
        if Path(state_path).exists():
            state = AgentState.load(state_path)
            print(f"Resuming from phase: {state.current_phase}")
            # Continue the pipeline from current state
            # TODO: integrate with run_pipeline
        else:
            print(f"No saved state found at {state_path}")
            sys.exit(1)
    else:
        run_pipeline(args.area, args.max_turns)
