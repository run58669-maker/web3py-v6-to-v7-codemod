# Negative test: a user-defined function or variable that happens to have the
# same bare name as a web3.py method (e.g. `encodeABI`) must NOT be rewritten.
# Method-rename rules require an enclosing `attribute` node.

def encodeABI(name, args):
    """User's own helper, unrelated to web3.py."""
    return f"<encoded {name} {args}>"


result = encodeABI("transfer", [1, 2])

# Same goes for `listen_to_websocket` defined as a plain function.
def listen_to_websocket(ws):
    return ws.recv()


msg = listen_to_websocket(None)
