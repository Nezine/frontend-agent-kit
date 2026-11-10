# Hermes — project skills for this repo

`skills/` under this directory are symlinks to the canonical skills in
`skills/` at the repo root (thin shims, never forks). A Hermes agent opening
this repo reads them as project skills.

- Project-local skills need one trust step: run `hermes skills trust` from
  the repo root (global `~/.hermes/skills/` needs none).
- Hermes can also read the shared dir via `skills.external_dirs` in
  `~/.hermes/config.yaml` pointing at `~/.agents/skills` — an OPTIONAL
  manual step. `./install.sh` does NOT set this up (it copies skills
  directly to `~/.hermes/skills/` for the global install instead), and
  the `config.yaml` schema is unverified — do not hand-edit it blindly
  or let a script merge into it. If you want the shared dir as well,
  add the key yourself and verify Hermes still starts:
  `skills: {external_dirs: ["~/.agents/skills"]}` (exact key shape
  UNVERIFIED — confirm against your Hermes version first).
- Impeccable hook (VERIFIED: Impeccable 4.8.2 changelog + README):
  `hermes plugins enable impeccable-design-hook` (once; `./install.sh`
  attempts it best-effort when Hermes is detected).
- The full kit (GSAP skills, Impeccable variants, reference data) is
  installed globally by `./install.sh`; this directory only mirrors the
  canonical `skills/` tree.
