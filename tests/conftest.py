"""Test configuration — mock the mcp module so server code can be imported."""
import sys
from unittest.mock import MagicMock

# Mock the mcp module before any server imports.
# The mcp package is provided by Claude Code's runtime and isn't installed
# in the user's Python environment. We only test pure logic functions, not
# the MCP tool wrappers themselves.
if "mcp" not in sys.modules:
    mcp_mock = MagicMock()
    sys.modules["mcp"] = mcp_mock
    sys.modules["mcp.server"] = mcp_mock.server
    sys.modules["mcp.server.fastmcp"] = mcp_mock.server.fastmcp
