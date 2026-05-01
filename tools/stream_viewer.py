"""
Stream Viewer -- Pretty-prints Claude Code stream-json output
=============================================================
Reads streaming JSON events from stdin and displays a clean,
readable progress log. Pairs with `claude -p --output-format stream-json`.

Supports nesting: when the coordinator launches sub-agents that also
pipe through stream_viewer.py, the sub-agent output appears indented
and labeled so you can tell which agent is active.

Renders the agent's extended-thinking content (reasoning) inline,
visually distinguished from regular agent text. Toggle with
--show-thinking / --hide-thinking (default: show).

NOTE on the upstream regression: Claude Code v2.1.8+ does not emit
`thinking` content blocks via --output-format stream-json
(GitHub issue anthropics/claude-code#20127). To see thinking on those
versions, downgrade with: `npm install -g @anthropic-ai/claude-code@2.1.7`.
This viewer's thinking handler is forward-compatible: it'll start
showing reasoning automatically once the upstream regression is fixed.

Usage:
    claude -p --output-format stream-json ... 2>&1 | python3 tools/stream_viewer.py
    claude -p --output-format stream-json ... 2>&1 | python3 tools/stream_viewer.py --label "Worker"
    claude -p --output-format stream-json ... 2>&1 | python3 tools/stream_viewer.py --hide-thinking
"""

import argparse
import json
import sys
import textwrap

# ANSI colors
DIM = "\033[2m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
RESET = "\033[0m"


def format_tool_use(tool_name: str) -> str:
    """Format a tool call for display."""
    short_name = tool_name.replace("mcp__pubmed__", "pubmed:")
    return f"{CYAN}🔧 {short_name}{RESET}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--label", default="", help="Label prefix for this agent level")
    thinking_group = parser.add_mutually_exclusive_group()
    thinking_group.add_argument(
        "--show-thinking", dest="show_thinking", action="store_true",
        default=True,
        help="Render extended-thinking content blocks inline (default).",
    )
    thinking_group.add_argument(
        "--hide-thinking", dest="show_thinking", action="store_false",
        help="Suppress extended-thinking blocks (useful for very long pipelines).",
    )
    args = parser.parse_args()

    prefix = f"{MAGENTA}[{args.label}]{RESET} " if args.label else ""
    turn_count = 0

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        # Pass through non-JSON lines (e.g., banners from sub-agents)
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            print(f"{prefix}{line}")
            sys.stdout.flush()
            continue

        event_type = event.get("type", "")

        # ── Agent messages (thinking / responding) ──
        if event_type == "assistant":
            turn_count += 1
            message = event.get("message", {})
            for block in message.get("content", []):
                block_type = block.get("type", "")

                if block_type == "text":
                    text = block.get("text", "")
                    if text.strip():
                        print(f"\n{prefix}{BOLD}[Turn {turn_count}]{RESET}")
                        for para in text.split("\n"):
                            if para.strip():
                                wrapped = textwrap.fill(
                                    para.strip(), width=88,
                                    initial_indent=f"{prefix}  ",
                                    subsequent_indent=f"{prefix}  ",
                                )
                                print(wrapped)

                elif block_type == "thinking":
                    # Extended-thinking content (reasoning). Block shape:
                    #   {"type": "thinking", "thinking": "...", "signature": "..."}
                    # Rendered with a leading "|" gutter and dimmed text so
                    # it's visually distinguishable from the agent's actual
                    # prose response above. Suppressed by --hide-thinking.
                    if not args.show_thinking:
                        continue
                    text = block.get("thinking", "")
                    if text.strip():
                        print(f"\n{prefix}{DIM}[Turn {turn_count} thinking]{RESET}")
                        for para in text.split("\n"):
                            if para.strip():
                                wrapped = textwrap.fill(
                                    para.strip(), width=88,
                                    initial_indent=f"{prefix}  {DIM}|{RESET} {DIM}",
                                    subsequent_indent=f"{prefix}  {DIM}|{RESET} {DIM}",
                                )
                                # Append RESET at end of each line so dim
                                # styling doesn't bleed past the wrap.
                                for line in wrapped.split("\n"):
                                    print(f"{line}{RESET}")

                elif block_type == "tool_use":
                    tool_name = block.get("name", "unknown")
                    tool_input = block.get("input", {})
                    label = format_tool_use(tool_name)

                    if "search_pubmed" in tool_name:
                        query = tool_input.get("query", "")
                        print(f"{prefix}  {label} query={DIM}{query[:80]}{RESET}")
                    elif "fetch_abstracts" in tool_name:
                        pmids = tool_input.get("pmids", [])
                        print(f"{prefix}  {label} {len(pmids)} PMIDs")
                    elif "query_dataset_registry" in tool_name:
                        domain = tool_input.get("domain", "")
                        kw = tool_input.get("keyword", "")
                        print(f"{prefix}  {label} domain={domain} keyword={kw}")
                    elif "get_dataset_details" in tool_name:
                        name = tool_input.get("name", "")
                        print(f"{prefix}  {label} {name}")
                    elif tool_name == "Write":
                        path = tool_input.get("file_path", "")
                        print(f"{prefix}  {label} {GREEN}→ {path}{RESET}")
                    elif tool_name == "Read":
                        path = tool_input.get("file_path", "")
                        print(f"{prefix}  {label} ← {path}")
                    elif tool_name == "Edit":
                        path = tool_input.get("file_path", "")
                        print(f"{prefix}  {label} ✏️  {path}")
                    elif tool_name == "Bash":
                        cmd = tool_input.get("command", "")
                        # Detect sub-agent launches
                        if "claude -p" in cmd:
                            print(f"\n{prefix}  {YELLOW}{BOLD}▶ Launching sub-agent...{RESET}")
                        else:
                            print(f"{prefix}  {label} $ {DIM}{cmd[:100]}{RESET}")
                    else:
                        print(f"{prefix}  {label}")

        # ── Tool results ──
        elif event_type == "result":
            result_text = event.get("result", "")
            if result_text:
                print(f"\n{prefix}{GREEN}{BOLD}═══ AGENT COMPLETE ═══{RESET}")
                # Show a brief summary, not the full output
                lines = result_text.strip().split("\n")
                for l in lines[:10]:
                    print(f"{prefix}  {l}")
                if len(lines) > 10:
                    print(f"{prefix}  {DIM}... ({len(lines)} lines total){RESET}")

        # ── System / error events ──
        elif event_type == "error":
            error = event.get("error", {})
            msg = error.get("message", str(error))
            print(f"{prefix}  {RED}✗ Error: {msg}{RESET}")

        sys.stdout.flush()


if __name__ == "__main__":
    main()
