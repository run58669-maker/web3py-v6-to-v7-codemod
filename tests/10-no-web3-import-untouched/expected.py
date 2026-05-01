# Negative test: a Python file that does NOT import web3 must be untouched
# even if it contains tokens that look like v6 names.
# This is the file-level analog of the substring test.

from typing import Any


def encodeABI(payload: Any) -> str:
    """Coincidental name in a non-web3 codebase."""
    return repr(payload)


# String literals with v6-looking names — untouched.
SCHEMA = {
    "fields": ["fromBlock", "toBlock"],
    "types": {"WebsocketProvider": "stub"},
}


def listen_to_websocket(stream):
    """A protocol shim, not a web3 method."""
    yield from stream
