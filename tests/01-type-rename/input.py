from web3 import Web3
from web3.providers.websocket import WebsocketProvider, WebsocketProviderV2

w3_legacy = Web3(WebsocketProvider("ws://localhost:8546"))
w3_modern = Web3(WebsocketProviderV2("ws://localhost:8546"))

try:
    w3_legacy.eth.get_block(99999999)
except BlockNumberOutofRange:
    pass

try:
    contract.events.Transfer()
except ABIEventFunctionNotFound:
    pass


def call_with_state(state: CallOverride):
    return w3_modern.eth.call({"to": "0x..."}, state_override=state)
