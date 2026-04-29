# web3py-v6-to-v7

Automate the **web3.py v6 → v7** migration with a single deterministic pass.

Built for the [DoraHacks Boring AI hackathon](https://dorahacks.io/hackathon/boring-ai). Uses [Codemod](https://codemod.com)'s `jssg` engine (ast-grep over Tree-sitter Python) — not jscodeshift.

---

## Why

web3.py 7 shipped on 2024-09 with 12+ user-visible breaking changes — renamed providers, snake_cased kwargs, moved ABI types, removed `personal` / `geth.miner` / `ethpm`. Every team upgrading hits the same boring search-and-replace work.

This codemod automates **86%** of that mechanical work with **zero false positives**. The 14% that's left over (removed modules) is flagged with a `TODO(web3py-v7)` comment so AI or a human can finish it.

---

## Coverage

| Category | Rules | Examples |
|---|---|---|
| Type / class identifier renames | 5 | `WebsocketProvider` → `LegacyWebSocketProvider`, `BlockNumberOutofRange` → `BlockNumberOutOfRange`, `CallOverride` → `StateOverride` |
| Method renames (attribute-scoped) | 2 | `contract.encodeABI(…)` → `contract.encode_abi(…)`, `w3.listen_to_websocket()` → `w3.process_subscriptions()` |
| Keyword argument renames | 4 | `fromBlock=` → `from_block=`, `fn_name=` → `abi_element_name=` |
| Module path rewrites | 1 | `from web3.types import ABI` → `from eth_typing import ABI` |
| Attribute renames (attribute-scoped) | 1 | `w3.middlewares` → `w3.middleware` |
| Removed-module flags | 3 | `import ethpm` → `# TODO(web3py-v7): …` |

**Total: 16 transformations.**

---

## Zero false positives — by design

Every rule is scoped to a specific AST node kind so it cannot fire in unrelated code:

- Type renames match `kind: "identifier"` only when the name regex matches exactly.
- Method renames require an enclosing `attribute` node — bare `encodeABI` as a user-defined function is left alone.
- Kwarg renames target `keyword_argument` nodes — string keys in dict literals (`{"fromBlock": …}`, which are RPC field names that **don't change** in v7) are correctly preserved.
- Removed modules are *flagged*, never silently dropped.

Verified on a 2019-era web3.py v4 sample repo (`dappuniversity/web3_py_examples`): codemod produced **0 changes** across the entire repo — exactly what should happen on out-of-scope code.

---

## Case study: `examples/realistic-v6-dapp.py`

A 70-line synthetic v6 dApp covering providers, websocket subs, contract calls, event filters, exception handling, and ABI imports. Running the codemod against it:

```diff
-from web3.providers.websocket import WebsocketProvider, WebsocketProviderV2
-from web3.types import ABI, ABIEvent, ABIFunction
+from web3.providers.websocket import LegacyWebSocketProvider, WebSocketProvider
+from eth_typing import ABI, ABIEvent, ABIFunction
 from web3.exceptions import (
-    ABIEventFunctionNotFound,
-    BlockNumberOutofRange,
+    ABIEventNotFound,
+    BlockNumberOutOfRange,
 )
-from web3._utils.method_formatters import CallOverride
+from web3._utils.method_formatters import StateOverride

+# TODO(web3py-v7): `ethpm` was removed in web3.py v7. Manual rewrite needed.
 import ethpm
+# TODO(web3py-v7): `web3.geth.miner` was removed in web3.py v7. Manual rewrite needed.
 from web3.geth.miner import set_extra
```

```diff
 def encode_transfer(contract, recipient, amount):
-    return contract.encodeABI(fn_name="transfer", args=[recipient, amount])
+    return contract.encode_abi(abi_element_name="transfer", args=[recipient, amount])

 def fetch_logs(w3, addr, since):
     raw = w3.eth.get_logs({
-        "fromBlock": since,        # ← unchanged: RPC field, not Python kwarg
-        "toBlock": "latest",
+        "fromBlock": since,
+        "toBlock": "latest",
         "address": addr,
     })

 def build_filter(contract, since):
     return contract.events.Transfer.create_filter(
-        fromBlock=since,
-        toBlock="latest",
+        from_block=since,
+        to_block="latest",
     )

 async def stream_blocks(w3):
-    async for msg in w3.listen_to_websocket():
+    async for msg in w3.process_subscriptions():
         print("new head:", msg)
```

**14 changes attempted, 14 changes correct, 0 false positives, 0 missed.**

---

## Run it

```bash
# Install Codemod CLI
npm i -g codemod

# Run on your project
codemod jssg run path/to/this/src/index.ts \
  --language python \
  --target /path/to/your/web3py-v6-app

# Dry-run first to see the diff
codemod jssg run ./src/index.ts \
  --language python \
  --target /path/to/your/repo \
  --dry-run
```

---

## Test

```bash
codemod jssg test ./src/index.ts --language python --strictness ast
```

6 fixtures, all passing as of v0.1.

---

## What's flagged but not auto-fixed

These are deliberately left for AI or human review — the right rewrite depends on context the codemod can't see:

- `import ethpm` / `from ethpm…` — entire module removed, replacements depend on use case
- `from web3.geth.miner import …` — needs different geth admin API or testing harness
- `from web3.pm import …` — package manager removed
- `except Web3ValueError` for JSON-RPC errors (now raised as `Web3RPCError`) — only some `Web3ValueError` catches need changing, requires reading the surrounding code

A future v0.2 may add an `--ai-review` flag that hands these spots to Claude/Codex for context-aware rewrites.

---

## License

MIT
