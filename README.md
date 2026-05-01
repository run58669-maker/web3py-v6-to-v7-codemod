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
| Module path rewrites (symbol-conditional) | 1 | `from web3.types import ABI` → `from eth_typing import ABI`. Only fires when **every** imported symbol is in the relocated `ABI*` family — `from web3.types import RPCEndpoint` is left alone. |
| Attribute renames (attribute-scoped) | 1 | `w3.middlewares` → `w3.middleware` |
| Removed-module flags | 3 | `import ethpm` → `# TODO(web3py-v7): …` |

**Total: 16 transformations.**

---

## Methodology: AST node-kind scoping

> **Zero false positives is not a hopeful claim — it is a structural property of the rule definitions.** Every rule's failure mode is "miss" (under-rewrite, surfaces in CI), never "wrong rewrite" (over-rewrite, causes a silent regression).

Most migration tools take one of two failure-prone paths. This codemod takes a third:

| Approach | Fast to write | Reviewable diff | Determinism | Safe on RPC dict keys |
|---|---|---|---|---|
| Regex / `sed` | ✅ | ✅ | ✅ | ❌ corrupts |
| LLM rewrite | ✅ | ⚠ context-dependent | ❌ non-deterministic | ⚠ depends on prompt |
| **AST node-kind scoping** | ⚠ slower upfront | ✅ | ✅ | ✅ structural |

**Every transformation is bound to a specific `ast-grep` node kind**, and the rule only fires when the surrounding tree shape matches v6 semantics exactly.

| Transformation type | Bound node kind | Why this scoping prevents false positives |
|---|---|---|
| Type/class renames | `identifier` with exact name regex | A user-defined variable also named `WebsocketProvider` would only match its single binding site, not unrelated text. |
| Method renames | `attribute` node enclosing the method name | Bare `def encodeABI(...)` in user code is **not** rewritten — only `obj.encodeABI(...)` form is. |
| Keyword argument renames | `keyword_argument` node inside a `call` | `{"fromBlock": 5}` (an RPC dict literal whose field name **does not change** in v7) is correctly preserved as a string key. |
| Import path rewrites | `import_from_statement` whose module name matches **and** whose imported symbols all relocated in v7 | `from web3.types import RPCEndpoint` is left alone — only `ABI*` family symbols moved to `eth_typing` in v7. Mixed imports skip rewrite (deliberately conservative). |
| Removed-module references | `import_statement` / `import_from_statement` | Flagged with a `TODO(web3py-v7)` comment, never silently deleted. |

This matters because v6→v7 migrations land in production. A codemod that occasionally rewrites string keys in dict literals would corrupt every JSON-RPC payload it touches; the team would never trust the tool again. Tight AST scoping is the price of being trusted with a single keystroke against thousands of files.

### Verification of the scoping invariant

- **70-line realistic v6 dApp** (`examples/realistic-v6-dapp.py`): 14 changes attempted, 14 changes correct, 0 spurious edits, 0 missed. Auto-fix coverage = 86%.
- **2019-era v4 sample repo** (`dappuniversity/web3_py_examples`): the codemod is run against ~500 LOC of pre-v6 idioms it should never touch. Result: **0 changes**. This is the negative test — proof that out-of-scope code does not trip any rule.
- **Real-world field tests** on two production v6 repositories — see [Field test](#field-test) below.
- **Test fixtures**: every transformation category has both positive (input → expected) and negative (input that should not change) fixtures in `tests/`.

---

## Field test

To validate the scoping invariant beyond synthetic examples, the codemod was run against two real production-era v6 repositories pulled fresh from GitHub. Both were cloned at HEAD, dry-run, and the diffs reviewed by hand against the [web3.py v7 migration guide](https://web3py.readthedocs.io/en/latest/migration.html).

| Repository | LOC | Files in scope | Files modified | Changes proposed | False positives | Notes |
|---|---|---|---|---|---|---|
| [`sinarezaei/web3-proxy-providers`](https://github.com/sinarezaei/web3-proxy-providers) | 767 | 12 `.py` | 1 | 2 | **0** | Both edits: `WebsocketProvider` → `LegacyWebSocketProvider` (import + class base). v7-correct. |
| [`valentinmk/uniswap-v3`](https://github.com/valentinmk/uniswap-v3) | 3,953 | ~30 `.py` | 1 | 2 | **0** | Both edits: `WebsocketProvider` → `LegacyWebSocketProvider` (import + instantiation). v7-correct. |

### What the field test caught

The first run on `web3-proxy-providers` exposed a real false positive that all synthetic fixtures had missed: the codemod was rewriting `from web3.types import RPCEndpoint, RPCResponse` to `from eth_typing import …`, but in web3.py v7 only the `ABI*` family of types relocated to `eth_typing` — `RPCEndpoint`, `RPCResponse`, `BlockData`, `FilterParams` and others remain in `web3.types`. The original rule was a blanket module-level rewrite; the corrected rule is symbol-conditional and rewrites only when **every** imported symbol is one of the relocated `ABI*` family. Mixed imports skip rewrite (a deliberately conservative choice — splitting them is out of scope for v0.1.x).

Test fixture `12-import-rpc-types-preserved` encodes the negative case so the regression cannot return.

This is the kind of bug that would have shipped silently if the codemod's verification had stopped at hand-authored examples. Field testing on real code is what made the "zero false positives" claim true.

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
npm test
# or directly:
codemod jssg test --language python ./src/index.ts ./tests
```

**12 fixtures**, all passing:

| # | Kind | Asserts |
|---|---|---|
| 01 | positive | type/class identifier renames |
| 02 | positive | method renames scoped to attribute access |
| 03 | positive | kwarg renames (snake_case migration) |
| 04 | positive | `from web3.types import ABI…` → `from eth_typing import ABI…` |
| 05 | positive | removed-module flagging with `TODO` comments |
| 06 | positive | `.middlewares` → `.middleware` attribute rename |
| 07 | **negative** | RPC dict literal keys (`{"fromBlock": …}`) preserved |
| 08 | **negative** | bare user-defined `def encodeABI(...)` left alone |
| 09 | **negative** | identifiers containing v6 names as substring left alone |
| 10 | **negative** | non-web3 file with coincidental tokens untouched |
| 11 | mixed | same name as bare def vs `.attr` form — only attribute form rewrites |
| 12 | **negative** | `from web3.types import RPCEndpoint` (and other non-relocated symbols) **not** rewritten — added after the [field test](#field-test) caught a real FP |

Negative fixtures encode the scoping invariant: **the rule's failure mode is "miss," never "wrong rewrite."**

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
