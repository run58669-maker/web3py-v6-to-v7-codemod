"""
Realistic web3.py v6 dApp example — used to demonstrate the
web3-py-v6-to-v7 codemod on something resembling real-world usage.

Covers: providers, contract calls, event filters, exception handling,
typed parameters, websocket subscriptions, and ABI imports.
"""
from web3 import Web3
from web3.providers.websocket import WebsocketProvider, WebsocketProviderV2
from web3.types import ABI, ABIEvent, ABIFunction
from web3.exceptions import (
    ABIEventFunctionNotFound,
    BlockNumberOutofRange,
)
from web3._utils.method_formatters import CallOverride

import ethpm  # legacy package manager
from web3.geth.miner import set_extra  # deprecated mining API


def make_legacy_client(url: str) -> Web3:
    return Web3(WebsocketProvider(url))


def make_modern_client(url: str) -> Web3:
    return Web3(WebsocketProviderV2(url))


async def stream_blocks(w3: Web3) -> None:
    await w3.eth.subscribe("newHeads")
    async for msg in w3.listen_to_websocket():
        print("new head:", msg)


def encode_transfer(contract, recipient: str, amount: int) -> bytes:
    return contract.encodeABI(fn_name="transfer", args=[recipient, amount])


def fetch_logs(w3: Web3, contract, addr: str, since: int):
    raw = w3.eth.get_logs({
        "fromBlock": since,
        "toBlock": "latest",
        "address": addr,
    })
    return raw


def build_filter(contract, since: int):
    return contract.events.Transfer.create_filter(
        fromBlock=since,
        toBlock="latest",
    )


def fetch_single_block_logs(w3: Web3, block_hash: str):
    return w3.eth.get_logs({"blockHash": block_hash})


def call_with_override(w3: Web3, tx: dict, state: CallOverride):
    return w3.eth.call(tx, state_override=state)


def safe_get_block(w3: Web3, num: int):
    try:
        return w3.eth.get_block(num)
    except BlockNumberOutofRange:
        return None


def safe_event_lookup(contract, name: str):
    try:
        return getattr(contract.events, name)
    except ABIEventFunctionNotFound:
        return None


def typed_handler(abi: ABI, event_abi: ABIEvent, fn_abi: ABIFunction) -> None:
    pass


def main() -> None:
    w3 = make_modern_client("ws://localhost:8546")
    contract_abi: ABI = []
    print("ready", w3.is_connected())


if __name__ == "__main__":
    main()
