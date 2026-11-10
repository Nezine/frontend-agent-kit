# Cursor — no plugin manifest shipped (deliberate)

Cursor reads `~/.agents/skills/` natively, which is exactly where
`./install.sh` installs this kit. No `.cursor-plugin/` marketplace manifest
is shipped, because its exact schema was not verified against a primary
Cursor source in phase 1 (CHƯA ĐỌC) — a guessed manifest risks a silent
install failure, and the file-copy path already works.

If a future re-check verifies the Cursor plugin format, add the manifest
here mirroring `.claude-plugin/plugin.json` (one plugin, skills pointing at
`./skills/`).
