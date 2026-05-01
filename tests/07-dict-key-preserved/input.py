# Negative test: RPC dict literal keys must NOT be rewritten.
# `fromBlock`, `toBlock`, `blockHash` as STRING KEYS are JSON-RPC field names
# that web3.py v7 still emits to the wire — only Python-level keyword arguments
# in `create_filter(...)` etc. switched to snake_case.
from web3 import Web3

w3 = Web3()


def fetch_logs(addr, since):
    return w3.eth.get_logs(
        {
            "fromBlock": since,
            "toBlock": "latest",
            "blockHash": None,
            "address": addr,
        }
    )


def serialize_filter_payload(since):
    payload = {"fromBlock": since, "toBlock": "latest"}
    return payload
