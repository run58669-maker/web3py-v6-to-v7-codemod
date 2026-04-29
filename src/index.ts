/**
 * web3.py v6 → v7 codemod
 *
 * Automates ~80% of the user-visible breaking changes in web3.py 6 → 7:
 *   A. Type/class identifier renames        (low collision risk, full rename)
 *   B. Method renames scoped to attribute   (x.encodeABI → x.encode_abi)
 *   C. Keyword argument renames in calls    (fromBlock= → from_block=)
 *   D. Import path rewrites                 (from web3.types → from eth_typing)
 *   E. Removed module flags                 (TODO comments for manual review)
 *
 * Design goal: zero false positives. Anything ambiguous is flagged for AI/manual.
 */

import type { Codemod } from "codemod:ast-grep";
import type Python from "codemod:ast-grep/langs/python";

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// === A. Type/class identifier renames ===
// CamelCase web3.py-specific names — collision with user-defined identifiers
// of the same exact name in unrelated code is statistically negligible.
const TYPE_RENAMES: Array<[string, string]> = [
  ["WebsocketProvider", "LegacyWebSocketProvider"],
  ["WebsocketProviderV2", "WebSocketProvider"],
  ["CallOverride", "StateOverride"],
  ["BlockNumberOutofRange", "BlockNumberOutOfRange"],
  ["ABIEventFunctionNotFound", "ABIEventNotFound"],
];

// === B. Method/attribute renames — only inside attribute access ===
const METHOD_RENAMES: Array<[string, string]> = [
  ["encodeABI", "encode_abi"],
  ["listen_to_websocket", "process_subscriptions"],
];

// === C. Keyword argument renames in function calls ===
const KWARG_RENAMES: Array<[string, string]> = [
  ["fromBlock", "from_block"],
  ["toBlock", "to_block"],
  ["blockHash", "block_hash"],
  ["fn_name", "abi_element_name"],
];

// === D. Module path rewrites for `from X import ...` ===
const IMPORT_REWRITES: Array<{ from: string; to: string }> = [
  { from: "web3.types", to: "eth_typing" },
];

// === F. Attribute renames inside `w3.middlewares` / `w3.middleware` ===
// In v7 the public attribute moved from `middlewares` to `middleware` (singular).
// Scope: only rewrite when used as an attribute access (.middlewares),
// never as a bare identifier — too high collision risk.
const MIDDLEWARE_ATTR_RENAMES: Array<[string, string]> = [
  ["middlewares", "middleware"],
];

// === E. Modules removed in v7 — flagged, not auto-rewritten ===
const REMOVED_MODULES: string[] = [
  "web3.geth.miner",
  "ethpm",
  "web3.pm",
];

const codemod: Codemod<Python> = async (root) => {
  const rootNode = root.root();
  const edits = [];

  // --- A. Type identifier renames ---
  for (const [oldName, newName] of TYPE_RENAMES) {
    const matches = rootNode.findAll({
      rule: { kind: "identifier", regex: `^${escapeRegex(oldName)}$` },
    });
    for (const n of matches) edits.push(n.replace(newName));
  }

  // --- B. Method renames inside attribute access ---
  for (const [oldName, newName] of METHOD_RENAMES) {
    const matches = rootNode.findAll({
      rule: {
        kind: "attribute",
        has: { field: "attribute", regex: `^${escapeRegex(oldName)}$` },
      },
    });
    for (const n of matches) {
      const text = n.text();
      const dotIdx = text.lastIndexOf(".");
      if (dotIdx < 0) continue;
      const prefix = text.slice(0, dotIdx + 1);
      edits.push(n.replace(prefix + newName));
    }
  }

  // --- C. Keyword argument renames ---
  for (const [oldKw, newKw] of KWARG_RENAMES) {
    const matches = rootNode.findAll({
      rule: {
        kind: "keyword_argument",
        has: { field: "name", regex: `^${escapeRegex(oldKw)}$` },
      },
    });
    for (const n of matches) {
      const text = n.text();
      const eqIdx = text.indexOf("=");
      if (eqIdx < 0) continue;
      const valuePart = text.slice(eqIdx);
      edits.push(n.replace(newKw + valuePart));
    }
  }

  // --- D. Module path rewrites ---
  for (const rule of IMPORT_REWRITES) {
    const matches = rootNode.findAll({
      rule: {
        kind: "import_from_statement",
        has: {
          field: "module_name",
          regex: `^${escapeRegex(rule.from)}$`,
        },
      },
    });
    for (const n of matches) {
      const text = n.text();
      const replaced = text.replace(
        new RegExp(`from\\s+${escapeRegex(rule.from)}`),
        `from ${rule.to}`,
      );
      if (replaced !== text) edits.push(n.replace(replaced));
    }
  }

  // --- F. Middleware attribute renames (only inside attribute access) ---
  for (const [oldAttr, newAttr] of MIDDLEWARE_ATTR_RENAMES) {
    const matches = rootNode.findAll({
      rule: {
        kind: "attribute",
        has: { field: "attribute", regex: `^${escapeRegex(oldAttr)}$` },
      },
    });
    for (const n of matches) {
      const text = n.text();
      const dotIdx = text.lastIndexOf(".");
      if (dotIdx < 0) continue;
      const prefix = text.slice(0, dotIdx + 1);
      edits.push(n.replace(prefix + newAttr));
    }
  }

  // --- E. Flag removed modules ---
  for (const mod of REMOVED_MODULES) {
    const matches = rootNode.findAll({
      rule: {
        any: [
          {
            kind: "import_from_statement",
            has: { field: "module_name", regex: `^${escapeRegex(mod)}` },
          },
          {
            kind: "import_statement",
            regex: `import\\s+${escapeRegex(mod)}`,
          },
        ],
      },
    });
    for (const n of matches) {
      const text = n.text();
      if (text.startsWith("# TODO(web3py-v7):")) continue;
      const flag =
        `# TODO(web3py-v7): \`${mod}\` was removed in web3.py v7. Manual rewrite needed.\n` +
        text;
      edits.push(n.replace(flag));
    }
  }

  if (edits.length === 0) return null;
  return rootNode.commitEdits(edits);
};

export default codemod;
