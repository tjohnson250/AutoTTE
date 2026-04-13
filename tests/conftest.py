"""Test configuration — mock the mcp module so server code can be imported."""
import sys
from unittest.mock import MagicMock

# Mock the mcp module before any server imports.
# The mcp package is provided by Claude Code's runtime and isn't installed
# in the user's Python environment. We only test pure logic functions, not
# the MCP tool wrappers themselves.
#
# IMPORTANT: FastMCP.tool() must behave as an identity decorator so that
# inspect.signature() tests can see the real function signatures.  A plain
# MagicMock replaces the decorated function with a mock, hiding signatures.
if "mcp" not in sys.modules:
    def _identity_decorator(*_args, **_kwargs):
        """Return a pass-through decorator that leaves the function unchanged."""
        def _decorator(fn):
            return fn
        return _decorator

    mcp_mock = MagicMock()
    # Make FastMCP instances expose .tool() as an identity decorator.
    mcp_mock.server.fastmcp.FastMCP.return_value.tool = _identity_decorator
    sys.modules["mcp"] = mcp_mock
    sys.modules["mcp.server"] = mcp_mock.server
    sys.modules["mcp.server.fastmcp"] = mcp_mock.server.fastmcp
