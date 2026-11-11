# Frontend Agent Kit

Bộ skill UI/UX dùng chung cho **Claude Code, Codex, OpenCode, Gemini CLI, GitHub Copilot, Hermes Agent, Muse Code, CommandCode (`cmd`) và Cursor** trên Linux. Cài global một lần, dùng trong mọi project.

> **Built for daily use.** The flow first: drop the repo link → the agent installs the kit for itself → vague brief ("make it look good, ref kiểu Apple/Anthropic") → build → your feedback. **Acceptance test: vague brief → 60% slop-free output → your feedback.** Host breadth matters, but where a trade-off appears, usability wins over a marginal host's compatibility.

> **Đọc kỹ trước khi hứa hẹn — giới hạn trung thực của v2:**
>
> - **Repo-link self-install (dán link repo, agent tự cài cho chính nó) hoạt động với Muse Code và các CLI host khác — KHÔNG hoạt động với Muse app (chat).** Với Muse app, không tồn tại đường cài đặt skill nào: chỉ có **paste packet** (dán nội dung vào từng cuộc trò chuyện, không lưu lại được). Đây là CLAIMED có độ tin cậy cao — 5 nguồn thứ ba độc lập cùng kết luận, **Meta primary chưa được đọc** (xem `research/worker-self-install.md` §7.7). Nếu bạn dùng Muse app hàng ngày, hãy dùng `templates/install/muse-app-pack.md` và đừng kỳ vọng mức 60% như các host CLI.
> - **Linux-first.** macOS/Windows là công việc mở (open work) — `install.sh` v1 từ chối non-Linux và chưa có gì trong nghiên cứu này kiểm chứng các đường đó.
> - **img2threejs chỉ là opt-in.** Lệnh MCP của JP là sai — không tồn tại MCP server nào cho img2threejs. Đừng chạy `claude mcp add img2threejs …` (xem § "Những gì KHÔNG có trong gói").
> - **Figma chỉ làm được khi có người bấm OAuth.** Không có bước Figma nào chạy unattended được.

## Cài nhanh (người dùng)

Cần `git`, `bash`, `python3` và kết nối mạng cho lần tải engine Impeccable đầu tiên. Các host cần được cài riêng trước.

```bash
git clone https://github.com/phamTuan207/frontend-agent-kit.git
cd frontend-agent-kit
./install.sh
./verify.sh
```

Sau đó **mở phiên mới** của host bạn dùng. Script sao lưu bản skill cùng tên đã có vào `~/.local/share/frontend-agent-kit/backups/` trước khi thay. Nếu mạng chưa sẵn, dùng `./install.sh --no-warm`; Impeccable sẽ tải engine khi gọi lần đầu.

## For AI agents — paste this with the repo link

> **Dán nguyên đoạn dưới đây cùng với link repo** (`https://github.com/phamTuan207/frontend-agent-kit`) **vào agent của bạn:**
>
> ```
> Install the frontend-agent-kit for yourself from https://github.com/phamTuan207/frontend-agent-kit.
> Read AGENTS.md in the repo first and follow it exactly.
> Clone the repo (or `git pull --ff-only` if you already have it), run `./install.sh`,
> then `./verify.sh`. Detect which hosts are installed on this machine
> (Claude Code, Codex, OpenCode, Gemini CLI, Copilot, Hermes, CommandCode, Muse Code, Cursor)
> and confirm each skill is listed by that host AFTER a new session — use that host's
> skill-list command, and `/reload-skills` or a restart if the skills directory did not
> exist when the session started.
>
> IMPORTANT — the restart/re-verify rule: skills, MCP servers and plugins load at
> session start almost everywhere. Testing in the SAME session you installed in is the
> #1 false-failure mode. You MUST restart (or reload) and re-verify in the NEW session
> before concluding anything is missing.
>
> If a step needs my browser sign-in or a key (Figma, any OAuth), stop and tell me
> exactly what to click — do not proceed past it, do not invent credentials, do not
> paste secrets into chat.
>
> When done, report in this format:
> - Install path per skill (full paths)
> - Per host: skills listed after restart (yes/no, with the exact list command used)
> - Impeccable engine version reported by the launcher
> - Hook/MCP status per host (wired / pending with exact command / not supported)
> - Anything still pending, with the exact human action needed
> ```

Per-host paste-prompt variants (cùng nội dung trên, đã điều chỉnh lệnh xác nhận theo từng host) nằm ở [`templates/install/`](templates/install/). Nếu agent của bạn là **Muse app**, đừng dùng prompt trên — dùng [`templates/install/muse-app-pack.md`](templates/install/muse-app-pack.md) (paste packet, đường duy nhất tồn tại cho app).

## Dùng gì khi nào?

**Sổ tay đầy đủ:** [HUONG-DAN.md](HUONG-DAN.md) — bảng chọn từng skill, thứ tự orchestrator-first, prompt mẫu và cách kiểm tra kết quả.

| Nhu cầu | Gọi skill |
|---|---|
| Thiết kế/xây/review giao diện (mọi loại brief) | **`frontend-kit`** (orchestrator) làm hướng chính — nó tự gọi các skill dưới đây theo vòng lặp taste-locked |
| Thiết kế/xây/review giao diện, gọi trực tiếp | **Impeccable** |
| Đặt hướng thẩm mỹ trước khi build (plan-first + counterfactual check) | **`frontend-design`** — skill gốc của Anthropic, kit vendor nguyên văn; xem lưu ý trùng tên ở § "Phạm vi gói" |
| Chuyển động, timeline, hiệu ứng theo cuộn | Skill **GSAP** phù hợp |
| Component ThreeUI có 3D/shader | **threeui** |
| Xem thêm style, bảng màu, font | **ui-ux-pro-max-reference** (lookup) |
| Hướng thẩm mỹ mặc định cho landing page/portfolio/redesign | **taste-reference** — từ v2 là taste layer mặc định, không còn chỉ-khi-được-yêu-cầu |

**Quy trình mặc định (v2):** brief (kể cả brief mơ hồ) → `frontend-kit` đọc brief → **taste lock** (chọn hướng tham chiếu, khóa `tokens.css` trước khi viết HTML) → build → **gate xác định** (`impeccable detect` + gate scripts) → **chấm bằng mắt** (Playwright screenshot 1440/768/390) → sửa top 2 lỗi dưới dạng token diff → tối đa 3 vòng → human gate. Nếu brief chưa rõ hướng: sinh **5 variant chỉ-khác-CSS** (Editorial / Dark / Warm brutalist / Glassy / Minimal — hướng từng variant: `skills/frontend-kit/references/variant-briefs.md`), người dùng chọn một — lựa chọn đó chính là feedback, không tranh luận hướng bằng lời. Câu hỏi human gate có sẵn ở `skills/frontend-kit/references/human-gate-pack.md`.

**Kiến trúc này đã là hình dáng đúng — không cần tái cấu trúc vì tooling:** vòng lặp của kit (skills + markdown + chạy theo lịch/kích hoạt) đã là đúng hình dáng "skills, markdown files, cron jobs" mà Alexandr Wang mô tả cho agent loop ở YC Startup School 2026 — xem `skills/frontend-kit/references/metric-locked-loop.md` §4. Đó là validation cho kiến trúc hiện có, không phải lý do thêm orchestration nặng nề; độ chặt nằm ở metric/gate, không nằm ở tooling. Lưu ý ranh giới ghi công: `GOAL.md` / thư mục `skills/` / cron của kit là **cách triển khai của riêng kit** cho ý "slash goal" mà Wang nhắc tới — tên file và lệnh cron là của kit, không phải spec của Wang (trong transcript không có "GOAL.md", "skills/ directory" hay lệnh cron "agent /goal").

### Gói chuyên gia (expert pack)

Khi lượt chấm cần chuyên môn sâu theo domain, judge hoặc orchestrator gọi **chuyên gia độc lập** — mỗi chuyên gia là một file brief ở `skills/frontend-kit/experts/`, được spawn như fresh sub-agent (cùng luật độc lập với judge: fresh context + no production history, không bao giờ là builder). 10 domain: **typography, colour, layout, motion (motion/interaction), accessibility, copy (copy/UX-writing), imagery, design-systems, performance, responsive**. Mỗi brief có: vai trò, tiêu chí chấm cụ thể (kiểm chứng được trên render), thang 1–5 kèm một dòng bằng chứng mỗi điểm, format output (bảng điểm + top defects + verdict), và luật độc lập. Verdict của chuyên gia là **second opinion cho judge** — judge giữ điểm 4 trục cuối cùng; tối đa 2 chuyên gia mỗi vòng, không gọi khi gate còn đỏ. Chi tiết luật gọi: `skills/frontend-kit/references/expert-pack.md`. Muse app không gọi được chuyên gia (không có sub-agent) — ở đó bạn là judge.

**Grader rule (non-negotiable): the builder NEVER grades its own work.** The grade step MUST dispatch to an independent judge: (a) an independently-trained expert judge sub-agent with NO production history of the build it grades; (b) Muse (the manager agent) grading directly; or (c) a different agent/model from the builder. A builder self-grade is FORBIDDEN, not merely discouraged. Any score without a named independent grader label is INVALID. The judge may call a specialist second opinion from the expert pack (`skills/frontend-kit/experts/` — typography, colour, layout, motion, accessibility, copy, imagery, design systems, performance, responsive) when its grade is uncertain on a domain; see `skills/frontend-kit/references/expert-pack.md`.

Ví dụ: “Dùng `frontend-kit` thiết kế landing page cho ứng dụng học ngoại ngữ; ref kiểu Apple/Anthropic. Khóa taste trước, build, chạy gate rồi chấm bằng screenshot thật.”

### Cách gọi trên từng ứng dụng

| Ứng dụng | Cài | Xác nhận đã nạp (sau phiên mới) |
|---|---|---|
| **Claude Code** | `./install.sh` (copy `~/.claude/skills/` ONLY — `~/.agents/skills/` is NOT written for a Claude-only install; it appears only when another host sharing that dir is also installed); hoặc `/plugin marketplace add phamTuan207/frontend-agent-kit` rồi `/plugin install frontend-agent-kit@frontend-agent-kit` | `/skills` |
| **Codex** | `./install.sh` (copy `~/.agents/skills/` + hedge `~/.codex/skills/` — xem lưu ý dưới) | `$` / `/skills`; plugin mới cần `/new` |
| **OpenCode** | `./install.sh` (copy `~/.config/opencode/skills/` + `~/.agents/skills/`); lệnh `/impeccable` và `/frontend-kit` đi kèm | Khởi động lại, skill xuất hiện trong session; `/impeccable` phản hồi |
| **Gemini CLI** | `./install.sh` (copy `~/.gemini/skills/` + `~/.agents/skills/`); hoặc `gemini skills install https://github.com/phamTuan207/frontend-agent-kit.git --consent` | `/skills list` |
| **GitHub Copilot** | `./install.sh` (copy `~/.copilot/skills/` + ghi `.github/copilot-instructions.md` — Copilot KHÔNG đọc file skill Claude/Cursor; file `.github/copilot-instructions.md` mới là artefact Copilot thực sự đọc, bản copy trong `~/.copilot/skills/` một mình không phải là bản cài Copilot hoạt động được) | Chỉ hoạt động ở VS Code agent mode / Copilot CLI / cloud agent — không phải inline completion hay plain chat |
| **Hermes Agent** | `./install.sh` (copy `~/.hermes/skills/` + `~/.agents/skills/`; hoặc trỏ `skills.external_dirs` tới `~/.agents/skills`) | `hermes skills list` |
| **Muse (agent)** | `./install.sh --hosts=muse` (copy `~/workspace/custom-skills/` ONLY) — host `muse` là Muse agent runtime có quyền workspace, không phải Muse Code; `~/workspace/custom-skills/` là đường cài làm việc được của runtime này (VERIFIED: runtime này nạp custom skill từ đó) | Liệt kê skill trong session mới |
| **Muse Code** | Không có giá trị `--hosts` riêng — dùng chung `~/.agents/skills/` (đọc native, không cần adapter), thư mục này được ghi khi cài bất kỳ host nào dùng chung nó (codex/opencode/gemini/hermes/cmd) hoặc khi không detect được host nào (fallback cài mọi host). KHÔNG phải host `muse` — host đó cài vào `~/workspace/custom-skills/`, không vào `~/.agents/skills/` | Liệt kê skill trong session mới |
| **CommandCode (`cmd`)** | `./install.sh` (copy `~/.agents/skills/`); hoặc `cmd skills add <repo>` | `cmd skills list --debug` (CHƯA ĐỌC — chưa được kiểm chứng) |
| **Cursor** | Không có giá trị `--hosts` riêng — dùng chung `~/.agents/skills/` (đọc native), như Muse Code ở trên | Liệt kê skill trong session mới |

**Lưu ý Codex:** hai nguồn primary mâu thuẫn nhau về thư mục skill của Codex — OpenAI docs + impeccable README nói `~/.agents/skills/`, GSAP README nói `~/.codex/skills/`. `install.sh` cài vào **cả hai** cho tới khi mâu thuẫn được giải quyết bằng clean-env test. (CLAIMED là mâu thuẫn chưa giải quyết; xem `research/worker-self-install.md` §10.2.)

**Một lệnh nhanh theo host:**

- **Claude Code:** `/plugin marketplace add phamTuan207/frontend-agent-kit` → `/plugin install frontend-agent-kit@frontend-agent-kit`
- **Codex:** `codex plugin marketplace add phamTuan207/frontend-agent-kit` → `codex plugin add frontend-agent-kit@frontend-agent-kit` (sau đó `/new`; nếu `add` lỗi, thử `install` — xem `templates/install/codex.md`)
- **Gemini CLI:** `gemini skills install https://github.com/phamTuan207/frontend-agent-kit.git --consent` (cần bấm consent trên UI khi kích hoạt lần đầu)
- **Các host còn lại:** `./install.sh` là đường chính.

**Lưu ý đường plugin:** Plugin route delivers only the 6 canonical skills in `./skills/`; GSAP skills, Impeccable variants, reference data and OpenCode commands are install.sh-only. (Câu chữ theo `.claude-plugin/plugin.json` / `.codex-plugin/plugin.json`.) Muốn đủ 15 skill + dữ liệu tham chiếu + các lệnh OpenCode `/impeccable` và `/frontend-kit`, chạy `./install.sh`.

**Lưu ý Cursor:** Cursor đọc `~/.agents/skills/` native — không có plugin manifest nào được ship (`.cursor-plugin/` chỉ chứa README giải thích lý do); `./install.sh` là đường cài duy nhất.

## Phạm vi gói

Gói chứa **15 skill**: orchestrator `frontend-kit` (mới, v2), judge độc lập `frontend-judge` (mới, v2 — chấm 1–5, xem `skills/frontend-judge/`), Impeccable 4.8.2 (engine 0.1.21), 8 skill GSAP chính thức, `threeui`, `ui-ux-pro-max-reference` (re-pin 2.15.0), `taste-reference` (taste-skill 2.5.1 — thin wrapper; full pipeline in the installed taste tree) và `frontend-design` (skill gốc của Anthropic, kit vendor nguyên văn — xem `skills/frontend-design/SOURCE.md`). OpenCode có thêm lệnh `/impeccable`. Dữ liệu Pro Max 2.15.0 và Taste 2.5.1 được giữ riêng ở `~/.local/share/agent-design-references/`.

**Lưu ý trùng tên `frontend-design`:** kit giữ nguyên tên thư mục upstream (`frontend-design`, frontmatter `name` trùng tên thư mục theo đúng spec) nên bản kit trùng tên với skill chính thức của Anthropic. Cài song song là thừa — kit đã vendor đúng skill đó nguyên văn (commit `2c5958e`, kiểm chứng 2026-11-10). Nếu cả hai cùng được cài, hai bản sẽ collide theo thư mục/tên trên host key theo tên; bản kit thắng vì là bản đã pin (cùng nội dung), và bạn nên gỡ bản chính thức thừa thay vì gỡ bản kit.

Chi tiết nguồn, phiên bản và giấy phép: [SOURCES.md](SOURCES.md). Các skill được lưu trong repo để `./install.sh` không phải tự tải lại nhiều nguồn; engine Impeccable tải đúng binary Linux khi cần (từ 4.8.0, mọi lần tải engine đều được kiểm tra digest kèm theo skill).

### Những gì KHÔNG có trong gói

- **`computer-use` và `chromium-cdp`** trên máy gốc gắn với môi trường desktop riêng nên không nằm trong gói. Trên máy nhận, dùng công cụ browser/GUI có sẵn để xem UI thật; nếu chưa có, yêu cầu agent cài hoặc cấu hình công cụ phù hợp máy đó.
- **Figma unattended.** Figma MCP hiện là remote server (`https://mcp.figma.com/mcp`) yêu cầu OAuth sign-in trên trình duyệt khi kết nối lần đầu. Mọi bước Figma đều là human-gated: agent phải dừng lại và báo chính xác người dùng cần bấm gì.
- **img2threejs trong default path (opt-in only).** Lệnh `claude mcp add img2threejs …` của JP là **sai — không tồn tại MCP server img2threejs**. Dạng đúng đã kiểm chứng một phần là skill-clone (`git clone https://github.com/img2threejs/img2threejs.git ~/.claude/skills/img2threejs`, gọi `/img2threejs …`). Không có lệnh harness nào được ship trong kit — img2threejs là opt-in only, CHƯA được test end-to-end trong kit, và KHÔNG có pinned command nào cho nó: bạn phải tự kiểm chứng install + `doctor` flow của upstream trước khi dùng. Chỉ dùng khi bạn chủ động yêu cầu.
- **Muse app install.** Không tồn tại. Xem giới hạn ở đầu README và `templates/install/muse-app-pack.md`.
- **macOS/Windows.** Linux-first; các đường macOS/Windows là open work.

### Buffet mode (chế độ tự chạy + bàn giao qua Figma)

**Buffet mode là yêu cầu chính thức của kit (xây sau khi lên main):** bạn giao brief rồi đi ăn; các agent tự chạy vòng lặp (orchestrator chia vai: builder / chuyên gia độc lập / judge độc lập / QC + red team, không có người trong vòng lặp, giữ bản tốt nhất, dừng theo luật 3 vòng/hướng); bạn quay lại sửa trực tiếp trên file Figma các agent đã làm (3 trang: Cover / Design System với biến Tokens + component / Screens 1440-768-390), hoặc sửa thẳng trên sản phẩm đã build. Sửa trong Figma chỉ về lại code bằng cách **đọc lại Figma rồi sinh code lại** (khóa lại `tokens.css`, build lại, chạy gate, chấm lại) — Figma không tự cập nhật app đang chạy.

**Giới hạn nói thẳng:** ghi Figma về qua MCP đang beta, chỉ chạy remote, cần ghế Full để ghi ngoài drafts, sau này sẽ thu phí theo lượt dùng với giá chưa công bố; `html_to_figma` chỉ ra các lớp phẳng, không ra component/biến — file Figma sửa được thật phải dựng bằng `use_figma`; API Variables chỉ dành cho Enterprise; Figma không có công cụ so sánh nên không bao giờ nằm trong gate; tài khoản Starter chỉ có ~20 lượt đọc MCP/tháng. Figma là input tùy chọn ở bước 1 (xuất biến native / import một lần bằng PAT / MCP nếu có), không bao giờ là xương sống — vòng lặp chạy đủ không cần Figma. Runbook đầy đủ: `BUFFET-MODE.md`.

## Kiểm tra sau khi cài

1. Chạy `./verify.sh` — v2 kiểm tra **cả vòng lặp**, không chỉ file tồn tại: skill có mặt theo từng host, `playwright-cli --help` chạy được, screenshot headless 390px thành công, `impeccable detect` chạy được, gate scripts chạy được, engine version khớp skill (lệch là fail to).
2. **Mở phiên mới** rồi chạy lệnh xác nhận của host bạn dùng (bảng trên).
3. Nếu một host chưa thấy skill sau phiên mới, kiểm tra có skill cùng tên trong project (`.agents/skills`, `.opencode/skills`, `.claude/skills`) vì bản project có thể ghi đè bản global.
