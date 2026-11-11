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
//              `git worktree remove <dir>` after the land decision (gate +
//              cross-check + grade — the cross-check runs on the merged tree
//              in the trial worktree, so it must survive through it)
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
import { existsSync } from "node:fs";

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
      stdout: execFileSync("git", args, {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"],
        // Default maxBuffer (~1 MB) would throw on a pathological conflict
        // list (thousands of conflicted paths — the F13 megafile case) and
        // misclassify a conflict as a git failure (exit 2). 10 MB instead.
        maxBuffer: 10 * 1024 * 1024,
      }),
      stderr: "",
    };
  } catch (err) {
    const stdout = err.stdout ? err.stdout.toString("utf8") : "";
    const stderr = err.stderr ? err.stderr.toString("utf8") : "";
    if (allowNonZero && typeof err.status === "number") {
      return { code: err.status, stdout, stderr };
    }
    process.stderr.write(`git ${args.join(" ")} failed: ${stderr || err.message}\n`);
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
  // Exit 0 = clean, 1 = conflicts. Stdout line 1 = tree OID, then the
  // conflicted-file-info section, then (after a blank line) the
  // informational-messages section.
  const merged = git(["merge-tree", "--write-tree", `--merge-base=${base}`, a, b], { allowNonZero: true });
  if (merged.code !== 0 && merged.code !== 1) {
    process.stderr.write(`git merge-tree failed (exit ${merged.code})\n${merged.stdout}${merged.stderr}`);
    process.exit(2);
  }
  // Keep blank lines: the informational-messages section always starts with
  // a blank line separating it from the previous sections (git-merge-tree
  // docs; verified 2026-11-11 against git 2.43 output), so the first empty
  // line after the tree OID is the section separator. Filtering blank lines
  // out would erase that separator.
  const lines = merged.stdout.split("\n");
  const tree = lines[0] ?? "";
  // Accept SHA-1 (40 hex) or SHA-256 (64 hex) object IDs.
  if (!/^(?:[0-9a-f]{40}|[0-9a-f]{64})$/.test(tree)) {
    process.stderr.write(`unexpected merge-tree output (no tree OID on line 1):\n${merged.stdout}`);
    process.exit(2);
  }
  // Conflicted-file-info section: lines after the tree OID up to the first
  // blank line — or to end of output if there is no messages section (e.g.
  // --no-messages). Each line is "mode SP oid SP stage TAB path", e.g.
  // "100644 <oid> 1<TAB>file.txt" (no type field; the "mode SP type SP oid
  // TAB path" form is git ls-tree, not merge-tree). Section membership is
  // authoritative per the docs, so every non-empty line here is a conflict
  // entry — including an unfamiliar shape, which is kept rather than
  // dropped, so it can only refuse a gate, never be missed. Everything
  // from the blank line on is informational messages ("Auto-merging ...",
  // "CONFLICT ...") and must NOT count as conflicts.
  const blankAt = lines.findIndex((line, i) => i > 0 && line === "");
  const infoSection = blankAt === -1 ? lines.slice(1) : lines.slice(1, blankAt);
  const conflicts = infoSection.filter((line) => line.length > 0);
  const clean = merged.code === 0 && conflicts.length === 0;

  let worktreeDir = null;
  if (worktree) {
    if (!clean) {
      // --json callers must be able to tell "conflicted" from "refused":
      // emit the JSON result (clean: false) before exiting 1.
      if (json) {
        process.stdout.write(`${JSON.stringify({ base, a, b, tree, clean: false, conflicts, worktree: null })}\n`);
      }
      process.stderr.write("refusing --worktree on a conflicted merge (nothing clean to gate)\n");
      process.exit(1);
    }
    // A bare tree is not a commit-ish, so `git worktree add` cannot check it
    // out directly. Mint a THROWAWAY commit on top of the merged tree (never
    // pushed, never landed — its only purpose is to give the worktree
    // something to check out). Synthetic identity, documented here, so the
    // command works even where no git identity is configured.
    // Single parent (the merge base) is deliberate: the tree is what the
    // gate reads; this commit never lands, so merge provenance lives in the
    // run log + commit message, not in parentage.
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
    // A previous trial that crashed or was killed may have left the target
    // dir behind (registered or orphaned). `worktree add` fails if the dir
    // exists, which would block every later trial for the same name — so
    // handle it before adding: prune stale registrations; remove the
    // registered worktree ONLY if it is recognisably a trial worktree
    // (detached at a trial commit whose subject carries the "DO NOT LAND"
    // marker minted above — a worktree this script, or an earlier
    // trial-merge run, created). A registered worktree that is NOT
    // recognisably a trial worktree is never removed: fall through to the
    // suffixed dir instead. An unregistered orphan dir on disk is likewise
    // never deleted — the fallback dir is used instead. The dir actually
    // used is recorded in the result, so the caller gates the right tree.
    git(["worktree", "prune"], { allowNonZero: true });
    const listed = git(["worktree", "list", "--porcelain"], { allowNonZero: true });
    if (listed.code === 0 && listed.stdout.split("\n").some((line) => line === `worktree ${worktree}`)) {
      const subject = git(["-C", worktree, "log", "-1", "--format=%s"], { allowNonZero: true });
      if (subject.code === 0 && subject.stdout.includes("DO NOT LAND")) {
        git(["worktree", "remove", "--force", worktree], { allowNonZero: true });
      }
    }
    let worktreeTarget = worktree;
    if (existsSync(worktreeTarget)) {
      worktreeTarget = `${worktree}-${tree.slice(0, 12)}`;
    }
    if (existsSync(worktreeTarget)) {
      // Same-tree re-trial: the tree-suffixed dir is deterministic per
      // tree, so a crashed trial can leave THAT dir behind too and the
      // next trial would collide again. One more level — a per-process
      // suffix — so a repeat trial cannot collide.
      worktreeTarget = `${worktree}-${tree.slice(0, 12)}-${process.pid}`;
    }
    const added = git(["worktree", "add", "--detach", worktreeTarget, commit], { allowNonZero: true });
    if (added.code !== 0) {
      process.stderr.write(`git worktree add failed:\n${added.stdout}${added.stderr}`);
      process.exit(2);
    }
    worktreeDir = worktreeTarget;
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
