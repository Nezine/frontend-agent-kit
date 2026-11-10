#!/usr/bin/env node
// trial-merge.mjs — trial-merge two buffet branches WITHOUT touching any branch.
//
// Buffet mode (BUFFET-MODE.md §5, P21): before the coordinator lands two
// agents' branches, it trial-merges the pair and gates on the MERGED tree —
// per-branch green is not green. This script performs the trial merge only;
// gating (impeccable detect + Playwright screenshots) runs on the checked-out
// merged tree, see --worktree.
//
// Usage:
//   node scripts/trial-merge.mjs --base <ref> --a <ref> --b <ref> [--worktree <dir>] [--json]
//   --base     merge base (usually `git merge-base <a> <b>`; pass it explicitly
//              so the trial is deterministic and reproducible in the run log)
//   --a, --b   the two branches to trial-merge (e.g. buffet/mie buffet/migga)
//   --worktree if given, check the merged tree out into a DETACHED worktree
//              at <dir> for gating; the worktree is removed with
//              `git worktree remove <dir>` after the gate
//   --json     print the result as one JSON object (for the run log)
//
// Exit codes: 0 = clean merge (no conflicts); 1 = conflicts (do NOT land —
//   hand the pair to the neutral merger, BUFFET-MODE.md §5); 2 = usage error
//   or a git failure (refs missing, not a repo, merge-tree itself errored).
//
// The trial merge writes exactly one tree object into .git/objects
// (`git merge-tree --write-tree`); it never moves a branch, never touches the
// working tree, never commits. The written tree is unreferenced and harmless
// (pruned by a later `git gc`); record its OID in the run log so the gate run
// is traceable to the exact merged tree.

import { execFileSync } from "node:child_process";

function usage(exitCode) {
  process.stderr.write(
    "usage: node scripts/trial-merge.mjs --base <ref> --a <ref> --b <ref> [--worktree <dir>] [--json]\n",
  );
  process.exit(exitCode);
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--json") {
      out.json = true;
    } else if (arg === "--base" || arg === "--a" || arg === "--b" || arg === "--worktree") {
      const value = argv[++i];
      if (value === undefined || value.startsWith("--")) usage(2);
      out[arg.slice(2)] = value;
    } else {
      usage(2);
    }
  }
  if (!out.base || !out.a || !out.b) usage(2);
  return out;
}

function git(args, { allowNonZero = false } = {}) {
  try {
    return {
      code: 0,
      stdout: execFileSync("git", args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
    };
  } catch (err) {
    if (allowNonZero && typeof err.status === "number") {
      return { code: err.status, stdout: err.stdout ? err.stdout.toString("utf8") : "" };
    }
    process.stderr.write(`git ${args.join(" ")} failed: ${err.stderr || err.message}\n`);
    process.exit(2);
  }
}

function main() {
  const { base, a, b, worktree, json } = parseArgs(process.argv.slice(2));

  // Resolve refs first so a typo fails here, not inside merge-tree.
  for (const ref of [base, a, b]) {
    const resolved = git(["rev-parse", "--verify", "--quiet", `${ref}^{commit}`], { allowNonZero: true });
    if (resolved.code !== 0) {
      process.stderr.write(`unknown ref: ${ref}\n`);
      process.exit(2);
    }
  }

  // --write-tree: merge in memory, write only the resulting tree object.
  // Exit 0 = clean, 1 = conflicts. Stdout line 1 = tree OID; the rest (if any)
  // is the conflicted-file-info section.
  const merged = git(["merge-tree", "--write-tree", `--merge-base=${base}`, a, b], { allowNonZero: true });
  if (merged.code !== 0 && merged.code !== 1) {
    process.stderr.write(`git merge-tree failed (exit ${merged.code})\n${merged.stdout}`);
    process.exit(2);
  }
  const lines = merged.stdout.split("\n").filter((line) => line.length > 0);
  const tree = lines[0] ?? "";
  if (!/^[0-9a-f]{40}$/.test(tree)) {
    process.stderr.write(`unexpected merge-tree output (no tree OID on line 1):\n${merged.stdout}`);
    process.exit(2);
  }
  // Conflicted-file-info lines follow the tree OID, in "mode SP type SP oid TAB path"
  // form (see git-merge-tree docs); anything after line 1 counts as a conflict.
  const conflicts = lines.slice(1);
  const clean = merged.code === 0 && conflicts.length === 0;

  let worktreeDir = null;
  if (worktree) {
    if (!clean) {
      process.stderr.write("refusing --worktree on a conflicted merge (nothing clean to gate)\n");
      process.exit(1);
    }
    // A bare tree is not a commit-ish, so `git worktree add` cannot check it
    // out directly. Mint a THROWAWAY commit on top of the merged tree (never
    // pushed, never landed — its only purpose is to give the worktree
    // something to check out). Synthetic identity, documented here, so the
    // command works even where no git identity is configured.
    const trialCommit = git([
      "-c",
      "user.name=trial-merge",
      "-c",
      "user.email=trial-merge@frontend-agent-kit.local",
      "commit-tree",
      tree,
      "-p",
      base,
      "-m",
      `trial merge of ${a} + ${b} (base ${base}) — DO NOT LAND, DO NOT PUSH`,
    ]);
    const commit = trialCommit.stdout.trim();
    const added = git(["worktree", "add", "--detach", worktree, commit], { allowNonZero: true });
    if (added.code !== 0) {
      process.stderr.write(`git worktree add failed:\n${added.stdout}`);
      process.exit(2);
    }
    worktreeDir = worktree;
  }

  const result = { base, a, b, tree, clean, conflicts, worktree: worktreeDir };
  if (json) {
    process.stdout.write(`${JSON.stringify(result)}\n`);
  } else if (clean) {
    process.stdout.write(`CLEAN merge ${a} + ${b} (base ${base}) -> tree ${tree}\n`);
    if (worktreeDir) process.stdout.write(`worktree: ${worktreeDir} (remove with: git worktree remove ${worktreeDir})\n`);
  } else {
    process.stdout.write(`CONFLICT ${a} + ${b} (base ${base}) -> tree ${tree}\n`);
    for (const line of conflicts) process.stdout.write(`  ${line}\n`);
    process.stdout.write("do NOT land — hand the pair to the neutral merger (BUFFET-MODE.md §5)\n");
  }
  process.exit(clean ? 0 : 1);
}

main();
