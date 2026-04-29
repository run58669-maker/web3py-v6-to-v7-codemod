from web3 import Web3
from web3.providers.websocket import LegacyWebSocketProvider, WebSocketProvider

w3_legacy = Web3(LegacyWebSocketProvider("ws://localhost:8546"))
w3_modern = Web3(WebSocketProvider("ws://localhost:8546"))

try:
    w3_legacy.eth.get_block(99999999)
except BlockNumberOutOfRange:
    pass

try:
    contract.events.Transfer()
except ABIEventNotFound:
    pass


def call_with_state(state: StateOverride):
    return w3_modern.eth.call({"to": "0x..."}, state_override=state)
