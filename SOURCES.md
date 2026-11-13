# Nguồn và giấy phép

Các thư mục `vendor/` là bản sao cố định của nguồn công khai, không phải do repo này tự viết. Giữ nguyên giấy phép của từng nguồn trong thư mục tương ứng. Mỗi pin ghi cả **tag VÀ commit** (tag là tên gọi, commit là bằng chứng) — hai thứ này phải khớp nhau; nếu lệch, commit thắng và pin phải được kiểm tra lại.

<!-- PIN: impeccable | repo=pbakaus/impeccable | tag=skill-v4.8.2 | commit=035c8f319edd019936525a062fe99e83ca8d12c6 | engine=0.1.21 -->
<!-- PIN: gsap | repo=greensock/gsap-skills | tag= | commit=aed9cfd3277740755f6bfc1155c7aa645403b760 -->
<!-- PIN: ui-ux-pro-max | repo=nextlevelbuilder/ui-ux-pro-max-skill | tag=v2.15.0 | commit=a38d04c3d5c298c851dbe5e6ee1965ee3de42cb5 -->
<!-- PIN: taste | repo=Leonxlnx/taste-skill | tag=v2.5.1 | commit=f6b76575f949707b4e3c37cd86cb44b0b98643e8 -->
<!-- PIN: threeui | repo=MengTo/threeui | tag= | commit=68802d5428071ada5c20db8094b1649e6bb770ed | package=@designcodeio/threeui@1.2.0 -->
<!-- SPEC PIN: dtcg-format | TR=2025.10 | date=2025-10-28 | url=https://www.designtokens.org/TR/2025.10/format/ | mirror=https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/ -->

| Thành phần | Nguồn | Phiên bản / commit | Giấy phép |
|---|---|---|---|
| Design Tokens Format Module 2025.10 (input contract của converter Figma → tokens.css) | [designtokens.org/TR/2025.10/format](https://www.designtokens.org/TR/2025.10/format/) | Final Community Group Report 2025-10-28 (TR 2025.10); "considered stable", "intended for implementation" — KHÔNG phải W3C Standard, không nằm trên Standards Track | Spec text only — không vendor copy trong repo này; không reprint dài, chỉ trích điều khoản cần thiết |
|---|---|---|---|
| Impeccable, một bản canonical + biến thể sinh lúc cài | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | tag `skill-v4.8.2`, commit `035c8f319edd019936525a062fe99e83ca8d12c6`, engine `0.1.21` | Apache 2.0; `vendor/impeccable/LICENSE`, `NOTICE.md` |
| 8 skill GSAP | [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | commit `aed9cfd3277740755f6bfc1155c7aa645403b760` (2026-04-21, HEAD của main lúc chốt pin) | MIT; `vendor/gsap/LICENSE` |
| Kho dữ liệu UI UX Pro Max | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | tag `v2.15.0`, commit `a38d04c3d5c298c851dbe5e6ee1965ee3de42cb5` | MIT (skill + dữ liệu — xem ghi chú giấy phép bên dưới); `vendor/ui-ux-pro-max/LICENSE` |
| Taste 2.5.1, full tree | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | tag `v2.5.1`, commit `f6b76575f949707b4e3c37cd86cb44b0b98643e8` | MIT; `vendor/taste/LICENSE` |
| `threeui` skill | Skill hướng dẫn do bộ này viết; tham chiếu [MengTo/threeui](https://github.com/MengTo/threeui) | Package `@designcodeio/threeui@1.2.0` (npm), repo HEAD `68802d5428071ada5c20db8094b1649e6bb770ed` lúc kiểm chứng | MIT của repo này (package theo MIT của upstream) |
| Hai skill tra cứu, script cài và tài liệu | Viết cho bộ này | Bản trong repo | MIT của repo này |
| 6 skill hackathon (backend-kit, mobile-58-kit, hackathon-security, networking-fetch, demo-rehearsal, networking-offline) | Viết cho bộ này (team skill-integration, 2026-11-13; install.sh-only) | Bản trong repo | MIT của repo này |
| 6 skill hackathon (networking-demo-preflight, maestro-smoke, evidence-capture, convex-official, supabase-official, expo-data-fetching) | Viết cho bộ này (team skill-integration, 2026-11-13; install.sh-only) | Bản trong repo | MIT của repo này |

## garden-skills — cited, not vendored (P1, 2026-11-10)

The P1 staged workflow (Design Read dials, Markdown design-system
declaration, v0 draft checkpoint, anti-cliché blocklist, anchored
style recipes) is adapted from garden-skills `web-design-engineer`
([ConardLi/garden-skills](https://github.com/conardli/garden-skills),
commit `08150e75`, MIT). The skill's SKILL.md was read in full
2026-11-10 (752 lines, main at that commit) and its README catalog
was read the same day.

**No garden-skills content is vendored verbatim in this repo, so no
pin is added here.** The Design Read dials are categorical (Low / Med
/ High with anchors), not the upstream 1–10 numbers; the anti-cliché
items in `skills/frontend-kit/references/anti-cliche.md` are
kit-authored restatements; the 7 files in
`skills/frontend-kit/references/style-recipes/` are kit-authored
adaptations (the upstream recipe files themselves are CHƯA ĐỌC). If
any garden-skills content is ever vendored verbatim, pin the release
`.zip` + SHA-256 here first, per the kit's pinning discipline — never
`main`.

Repo này không chứa mã component ThreeUI, package GSAP, các model AI, token hay cấu hình cá nhân. Khi dùng ThreeUI trong một project, cài package chính thức theo nhu cầu và giấy phép của package đó.

## Kiểm chứng pin (ngày kiểm chứng: 2026-11-10)

- **Impeccable 4.8.2 / engine 0.1.21 — VERIFIED.** Tag `skill-v4.8.2` peel ra commit `035c8f319edd019936525a062fe99e83ca8d12c6` (tag object `3a2a4a38d58d1aa7e76d00f66c4e83666ad78fe5`, tagged 2026-11-09T19:55:24Z; merge 2026-11-09T19:53:48Z). Engine tag `engine-v0.1.21` peel ra commit `fe45455d36ed14c85ece25c9b868344e55713352` (tagged 2026-11-09T03:33:56Z). Tại tag này `ENGINE_VERSION` và `skill/scripts/VERSION` đều đọc `0.1.21`; changelog (impeccable.style/changelog, đọc 2026-11-10): CLI v4.8.2, 2026-11-09 — "Engine 0.1.21 brings `impeccable agents` and the fixes in skill v4.8.2". Registry 62 rule đếm lại từ `crates/live/assets/antipatterns.json` tại tag (không đổi so với 4.8.1): file 392 dòng, JSON list dài 62 (31 `slop` / 31 `quality`; severity 16 advisory / 2 error / 44 không ghi — tức warning-default; id duy nhất); README dòng thô 29: "62 deterministic rules". Bản canonical `vendor/impeccable/skill/` là cây `skill/` của upstream tại tag — mọi file khớp hash blob upstream, trừ `skill/scripts/impeccable.cmd`: blob là LF, bản vendored là CRLF, đúng quy tắc `.gitattributes` của chính upstream (`*.cmd text eol=crlf` — checkout nào cũng ra CRLF), nội dung ngoài line ending giống hệt. `scripts/generate-host-variants.sh` sinh biến thể per-host lúc cài và đã được đối chiếu byte-identical với cây `.agents/` / `.claude/` / `.opencode/` / `.gemini/` do chính upstream sinh ra tại tag này — cây `agents` giống hệt toàn bộ, 3 cây còn lại chỉ khác đúng một điểm cố ý: `version:` nằm trong `metadata:` thay vì top-level (top-level `version:` không phải field của spec và làm hỏng đóng gói plugin Claude). Bốn file transformer của upstream (`scripts/lib/transformers/factory.js`, `providers.js`, `utils.js`, `skill-categories.js`) giống hệt giữa 4.8.1 và 4.8.2 nên generator không cần sửa cho lần re-pin này.
- **GSAP — VERIFIED byte-identical.** Cả 8 `SKILL.md` trong `vendor/gsap/` giống hệt upstream tại commit `aed9cfd` (kích thước: gsap-core 14792 B, gsap-frameworks 10621 B, gsap-performance 4139 B, gsap-plugins 21579 B, gsap-react 6565 B, gsap-scrolltrigger 18390 B, gsap-timeline 4394 B, gsap-utils 12093 B). Upstream không tag release skill — pin bằng commit.
- **Pro Max v2.15.0 — VERIFIED.** Tag `v2.15.0` peel ra commit `a38d04c3d5c298c851dbe5e6ee1965ee3de42cb5` (2026-08-14). Cây vendored là `.claude/skills/ui-ux-pro-max/` tại tag (70 file); `SKILL.md` tại tag giống hệt bản v1 đã vendor (chỉ dữ liệu đổi: `catalog-summary.json` + 3 CSV `stacks/` + 4 script). **Sửa nhãn cũ:** v1 ghi "2.13.0" nhưng cây thực chất là main @ `477bcb28` (sau 2.13.0); pin này là theo tag thật. Lưu ý: `skill.json` của upstream vẫn ghi `"version": "2.13.0"` ngay cả tại tag v2.15.0 — tag mới là chuẩn, không phải `skill.json`.
- **Taste 2.5.1 — VERIFIED.** Tag `v2.5.1` peel ra commit `f6b76575f949707b4e3c37cd86cb44b0b98643e8` (merge 2026-11-07); khớp với clone 2.5.1 có sẵn trên máy. Cây vendored là toàn bộ tree tại tag (1664 file, ~40 MB: `skills/` + `scripts/` + `library/` + `assets/` + `examples/` + `tests/`), byte-identical với cả clone upstream mới lẫn clone local. `presets.json` (`skills/taste-skill/assets/diagrams/presets.json`): **27 preset có tên — đếm các key của object `presets`, không đếm key top-level** (top-level chỉ có 2 key `about` + `presets`; đếm 2 key đó là lỗi QC cũ, đã bị bác). `SKILL.md` 381 dòng, `CHANGELOG.md` 299 dòng.
- **ThreeUI — VERIFIED (kiểm chứng lại lúc build).** Repo [MengTo/threeui](https://github.com/MengTo/threeui) tồn tại (HEAD `68802d5428071ada5c20db8094b1649e6bb770ed`); package npm `@designcodeio/threeui@1.2.0` tồn tại (MIT, `main` `./lib-dist/index.js`, exports gồm `./components/*`, `./assets/*`, `./style.css` — khớp các claim trong `skills/threeui/SKILL.md`: import subpath component, `style.css`, assets ở `lib-dist/assets/`); `https://threeui.com/` trả HTTP 200. Claim "Pro source riêng, cần tài khoản entitled qua CLI chính thức" chưa kiểm chứng độc lập — giữ nguyên như lời của skill, không nâng lên VERIFIED.
- **DTCG Format Module 2025.10 — VERIFIED (P15, 2026-11-10).** Final Community Group Report 2025-10-28, đọc tại https://www.designtokens.org/TR/2025.10/format/ (W3C mirror https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/). "This specification is considered stable" và "intended for implementation"; KHÔNG phải W3C Standard, không nằm trên Standards Track. `$value` là property bắt buộc duy nhất; object-valued color (`colorSpace`/`components`/`alpha`/`hex`), dimension (`{value, unit: px|rem}`), duration (`{value, unit: ms|s}`); type kế thừa từ group `$type` gần nhất, "Tools MUST NOT attempt to guess the type"; tools MUST báo lỗi với invalid syntax, unresolvable paths, invalid token references, circular references, type mismatches; `$deprecated` MAY đánh dấu token/group deprecated; `$extensions` là object cho tool/vendor data. KHÔNG BAO GIỜ trích URL draft `tr.designtokens.org` — URL TR trên đây là pin.

## Impeccable: skill ↔ engine phải đi cùng nhau (lockstep)

Registry 62 rule của `detect` nằm trong ENGINE, không nằm trong skill. Nâng skill lên mà không nâng engine thì `detect` áp nhầm registry — lặng lẽ, không báo lỗi. Vì vậy:

- Pin của Impeccable luôn là một cặp: skill tag + engine version (`skill-v4.8.2` + `0.1.21`). Hai số này phải khớp với `skill/scripts/VERSION` trong cây vendored và với entry changelog tương ứng.
- `verify.sh` phải kiểm tra engine đã cài với engine mà skill yêu cầu, và fail to khi lệch.
- Không bao giờ re-pin chỉ skill hoặc chỉ engine. `vendor-update.sh` từ chối nâng engine mà không có skill tag đi kèm.

## Giấy phép Pro Max — đã giải quyết (2026-11-10)

Nửa CC-BY-NC-4.0 trước đây chưa rõ nay đã xác định: nó thuộc về **gói CLI installer, không thuộc skill/dữ liệu mà kit vendor**.

- Skill + dữ liệu là **MIT**: root `LICENSE` (MIT, © 2024 Next Level Builder), root `README.md` dòng 657–659 — "## License — This project is licensed under the MIT License (LICENSE)", `skill.json` dòng 7 `"license": "MIT"`, `cli/package.json` dòng 49 `"license": "MIT"`.
- CC-BY-NC-4.0 chỉ xuất hiện ở một chỗ duy nhất trong cây upstream: `cli/README.md` dòng 99–101 ("## License / CC-BY-NC-4.0") — README của gói npm `ui-ux-pro-max-cli`. (Các số dòng / nội dung `skill.json` ở trên là của cây upstream tại tag — `skill.json` không nằm trong cây vendored của kit, chỉ có `SKILL.md` + data + references + scripts — nên kiểm chứng lại tại upstream khi re-pin.)
- Kit KHÔNG vendor `cli/` — chỉ vendor `.claude/skills/ui-ux-pro-max/` (SKILL.md + data + references + scripts). Không có gì trong `vendor/ui-ux-pro-max/` thuộc CC-BY-NC-4.0.

## Kit patch trên cây vendored (phải áp lại mỗi lần re-pin)

- **Pro Max:** 11 tham chiếu `${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/scripts/search.py` trong `SKILL.md` (dòng upstream 42, 78, 85, 93, 116, 131, 137, 160, 180, 183, 186) đã được thay bằng `<skill-dir>/scripts/search.py`, với `<skill-dir>` là thư mục chứa `SKILL.md`. Biến upstream chỉ resolve khi cài dạng Claude plugin; trong môi trường sạch / host khác nó gãy. `vendor-update.sh` áp lại patch này tự động và fail nếu còn sót tham chiếu nào.
- **Impeccable:** không patch nội dung upstream. Biến thể per-host được *sinh* bởi `scripts/generate-host-variants.sh`; điểm khác duy nhất so với output của chính upstream là `version:` nằm trong `metadata:` (xem mục kiểm chứng Impeccable).
- **Impeccable — lệch degraded-mode của kit (grader rule):** bản canonical dưới `vendor/impeccable/skill/` giữ nguyên verbatim, nhưng các bản sinh bởi `scripts/generate-host-variants.sh` KHÔNG giữ nguyên fallback degraded của upstream: preamble của `reference/degraded/*.md` cấm tự chấm trong cùng context (reviewer chỉ review, không edit — parent áp fix; bản cũ bảo inline reviewer "carry out the production steps yourself" trong khi body bảo "You edit nothing"), và transform trong generator strip/replace luôn MỌI chỉ dẫn cho phép tự chấm trong cùng context nằm trong `reference/critique.md` (quyền inline ở Hard Invariants, carve-out native "Run Assessment A alone in this context … complete native method", carve-out "skipped detector … or the platform is native", dòng Native ở report header, cộng với yêu cầu banner + tự critique tuần tự, kể cả 3 dòng banner của Codex gate và bullet provenance ở report header) và `reference/new-work.md` ("Score the plates", "Critique the render … fix material gaps", comp-diff "as the critique", "verify the mode did its job", cộng với fresh in-thread pass của finish reviewer + Verdict Pass fallback từ `degraded/finish-reviewer.md`), thay bằng pointer tới grader rule của kit — chỉ chấm qua independent judge (`judge-subagent` / `muse-manager` / `other-model`), không có judge thì grade là đúng `"gate green, vision not available"`. Codex agent `.toml` cũng mang GRADING preamble trong `developer_instructions` (`.toml` không thấy `reference/degraded/*.md`). Generator fail to nếu câu upstream mà transform nhắm tới bị thiếu (re-pin đổi wording) hoặc self-check ngữ nghĩa (grep toàn bộ file sinh theo pattern tự chấm trong cùng context, xem header script) còn bắt được câu nào ngoài dòng cấm của chính kit. Danh sách đầy đủ từng chỉ dẫn (giữ / thay / xóa có ghi quyết định) ở `build-notes/w-fix2-generator.md`.

## Nhịp re-pin (cadence) và cách re-pin

- Kiểm tra drift: `./scripts/check-versions.sh` (chỉ cảnh báo, không bao giờ tự nâng cấp lúc cài đặt). Chạy mỗi khi chuẩn bị release, hoặc ít nhất mỗi tháng — upstream moves hàng tháng.
- Re-pin: `./vendor-update.sh <component> <tag-hoặc-commit>` (xem script để biết chi tiết từng component). Script tự: resolve tag → commit (fail nếu không resolve được, không bao giờ đoán hash), thay cây vendored, cập nhật marker PIN trong file này + `SOURCE.txt` tương ứng, áp lại kit patch, refresh `vendor/SHA256SUMS`.
- Sau re-pin: chạy `./scripts/check-versions.sh`, `./verify.sh`, và với Impeccable thì chạy lại `scripts/generate-host-variants.sh --all` để chắc chắn transform vẫn khớp output của upstream; review `git diff` rồi mới commit. Không commit, không push tự động.

## SHA-256 manifest

`vendor/SHA256SUMS` là manifest SHA-256 của toàn bộ cây `vendor/` (định dạng `sha256sum`, đường dẫn tương đối từ repo root, tự loại chính nó). Refresh bằng `vendor-update.sh` hoặc: `cd <repo-root> && find vendor -type f ! -name SHA256SUMS -exec sha256sum {} + | sort -k2 > vendor/SHA256SUMS`. Dùng để phát hiện file vendored bị sửa tay ngoài quy trình re-pin.
