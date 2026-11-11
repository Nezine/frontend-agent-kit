# CI gate fixture

Minimal static page the CI workflow runs `scripts/gate/gate.sh` against
after `./install.sh` + `./verify.sh --strict`. It is a probe build, not a
full loop grade: the point is exercising the gate end to end on a
project-shaped target (taste lock in `design/tokens.css`, one built page).

The page is deliberately boring so the gate passes deterministically:

- No `<section>` elements (no visual-marker requirement).
- No gradients, no emoji (anti-cliché clean).
- No `package.json` (dependency / CVE / licence legs are N/A).
- No server/deployment config, no `fetch`/API calls (CSP + rate-limit
  legs are N/A).
- Tokens follow the lint contract (T1 kebab-case, T3 `--color-on-bg`
  paired with `--color-bg`, T4 colour roles alias primitives, T2 no
  primitive use in the page CSS).

If the gate fails on this fixture, the fixture is wrong or the gate
regressed — either way CI goes red and the failure is investigated,
not waived.
