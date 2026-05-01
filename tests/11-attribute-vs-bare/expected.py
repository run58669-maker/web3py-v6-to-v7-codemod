# Mixed test: same name as method-rename target, used both as an attribute
# (must rewrite) and as a bare reference (must NOT rewrite).
from web3 import Web3

w3 = Web3()


def encodeABI(payload):
    """Bare definition — left alone."""
    return repr(payload)


# Attribute call form — rewrites to .encode_abi(...)
def call_via_attr(contract, recipient, amount):
    return contract.encode_abi(abi_element_name="transfer", args=[recipient, amount])


# Bare call to user's own helper — left alone.
def call_via_bare(payload):
    return encodeABI(payload)


# Subscription stream uses attribute form — rewrites to .process_subscriptions()
async def stream(w3):
    async for msg in w3.process_subscriptions():
        yield msg
