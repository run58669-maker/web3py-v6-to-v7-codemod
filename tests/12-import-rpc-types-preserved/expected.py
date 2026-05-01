# Negative test: web3.types -> eth_typing rewrite must be SYMBOL-CONDITIONAL.
# Only ABI* family relocated in v7. Other symbols (RPCEndpoint, RPCResponse,
# BlockData, FilterParams, ...) remain in web3.types and MUST NOT be rewritten.
from web3.types import RPCEndpoint, RPCResponse
from web3.types import BlockData
from web3.types import FilterParams as Filter

# Mixed imports must also be skipped — splitting them is out of scope, but
# corrupting the ones that DID NOT move is unacceptable.
from web3.types import ABI, RPCEndpoint
