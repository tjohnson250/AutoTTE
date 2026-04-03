"""
Stream Viewer — Pretty-prints Claude Code stream-json output
=============================================================
Reads streaming JSON events from stdin and displays a clean,
readable progress log. Pairs with `claude -p --output-format stream-json`.
"""

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
RESET = "\033[0m"

def format_tool_use(tool_name: str, tool_input: dict) -> str:
    """Format a tool call for display."""
    # Shorten MCP tool names for readability
    short_name = tool_name.replace("mcp__pubmed__", "pubmed:")
    return f"{CYAN}🔧 {short_name}{RESET}"

def main():
    turn_count = 0
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            # Not JSON — just print it
            print(line)
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
                        print(f"\n{BOLD}[Turn {turn_count}]{RESET}")
                        # Wrap long text for readability
                        for para in text.split("\n"):
                            if para.strip():
                                print(textwrap.fill(para.strip(), width=88,
                                                     initial_indent="  ",
                                                     subsequent_indent="  "))

                elif block_type == "tool_use":
                    tool_name = block.get("name", "unknown")
                    tool_input = block.get("input", {})
                    label = format_tool_use(tool_name, tool_input)

                    # Show key details for known tools
                    if "search_pubmed" in tool_name:
                        query = tool_input.get("query", "")
                        print(f"  {label} query={DIM}{query[:80]}{RESET}")
                    elif "fetch_abstracts" in tool_name:
                        pmids = tool_input.get("pmids", [])
                        print(f"  {label} {len(pmids)} PMIDs")
                    elif "query_dataset_registry" in tool_name:
                        domain = tool_input.get("domain", "")
                        kw = tool_input.get("keyword", "")
                        print(f"  {label} domain={domain} keyword={kw}")
                    elif "get_dataset_details" in tool_name:
                        name = tool_input.get("name", "")
                        print(f"  {label} {name}")
                    elif tool_name == "Write":
                        path = tool_input.get("file_path", "")
                        print(f"  {label} {GREEN}→ {path}{RESET}")
                    elif tool_name == "Read":
                        path = tool_input.get("file_path", "")
                        print(f"  {label} ← {path}")
                    elif tool_name == "Bash":
                        cmd = tool_input.get("command", "")
                        print(f"  {label} $ {DIM}{cmd[:80]}{RESET}")
                    else:
                        print(f"  {label}")

        # ── Tool results ──
        elif event_type == "result":
            # Final result
            result_text = event.get("result", "")
            if result_text:
                print(f"\n{GREEN}{BOLD}═══ COMPLETE ═══{RESET}")
                print(result_text[:500])
                if len(result_text) > 500:
                    print(f"{DIM}  ... ({len(result_text)} chars total){RESET}")

        # ── System / error events ──
        elif event_type == "error":
            error = event.get("error", {})
            msg = error.get("message", str(error))
            print(f"  {RED}✗ Error: {msg}{RESET}")

        # Flush after each event so output appears immediately
        sys.stdout.flush()

if __name__ == "__main__":
    main()
