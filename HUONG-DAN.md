# Sổ tay dùng skill frontend

> **Nhớ một dòng:** `frontend-kit` dẫn toàn bộ vòng lặp (taste lock → build → gate → chấm bằng mắt → sửa); Impeccable xây giao diện; GSAP làm chuyển động; ThreeUI thêm component 3D; Pro Max tra cứu; Taste là taste layer mặc định. Luôn xem bản chạy thật trước khi chốt.

## Chọn đúng skill

| Bạn cần | Skill | Nói với agent |
|---|---|---|
| Trang, app, dashboard, form đẹp và dễ dùng | `impeccable` | “Dùng Impeccable thiết kế và xây màn hình đăng ký cho người mới.” |
| Đặt hướng thẩm mỹ trước khi build (plan-first, check counterfactual) | `frontend-design` | “Dùng frontend-design đặt hướng trước: 4–6 màu đặt tên, vai trò type, wireframe ASCII, rồi check counterfactual.” |
| Hiệu ứng xuất hiện, chuỗi chuyển động, animation theo cuộn | `gsap-*` | “Dùng `gsap-scrolltrigger` làm đoạn reveal theo cuộn, hỗ trợ người tắt hiệu ứng.” |
| Một component 3D/shader trong trang React | `threeui` | “Tìm component ThreeUI Community hợp phần hero và tích hợp vào project.” |
| Ba lựa chọn style, màu, font, biểu đồ để so | `ui-ux-pro-max-reference` | “Tra Pro Max cho ba hướng màu và font của trang này; giải thích vì sao hợp.” |
| Đặt hướng thẩm mỹ mặc định cho mọi build (taste lock) | `taste-reference` | “Dùng Taste làm taste layer mặc định: khóa hướng thẩm mỹ trước khi build.” |

**Taste từ v2 là taste layer mặc định, không còn chỉ-khi-được-yêu-cầu.** Orchestrator
`frontend-kit` dùng Taste trên mọi build (khóa taste, chọn hướng, chạy checker/gate).
Bạn vẫn có thể gọi `taste-reference` trực tiếp khi muốn một phương án so sánh.

**Pro Max là nguồn tra cứu.** Khi đã chọn một hướng, để Impeccable dẫn phần xây dựng. Không cần gọi tất cả skill trong một prompt.

## Thứ tự mặc định: orchestrator-first

Từ v2, đừng gọi skill lẻ trước. Thứ tự mặc định cho mọi brief — kể cả brief mơ hồ:

1. **Gọi `frontend-kit`** (orchestrator). Nó tự đọc brief, xác định loại sản phẩm
   (landing / dashboard / app screen / redesign), đối tượng, và Impeccable mode
   (Persuade / Operate / Read / Experience).
2. **Taste lock (chưa build):** orchestrator chọn hướng tham chiếu (site nào, DESIGN.md
   nào), viết `tokens.css`, build demo 1 trang chứng minh tokens chạy được. Tokens +
   references được commit **trước** khi viết HTML. Nếu brief mơ hồ về hướng: sinh
   **5 variant chỉ-khác-CSS** (Editorial / Dark / Warm brutalist / Glassy / Minimal),
   chụp từng variant cùng một chiều rộng — bạn chọn một, lựa chọn đó là feedback.
3. **Build** một file HTML, chỉ dùng tokens — không inline style lệch.
4. **Gate xác định trước khi chấm:** chạy `impeccable detect` (62 rule) + gate scripts
   (overflow / collide / tap-size, chiều cao section, một section một màn hình,
   copy-lint). Gate FAIL thì chặn vòng — không tốn lượt chấm bằng mắt cho bản gate đã fail.
5. **Chấm bằng mắt:** Playwright screenshot 1440 / 768 / 390, chấm 1–5 theo
   Type / Layout / Colour / Space so với reference đã khóa. Mỗi điểm phải kèm **một dòng
   bằng chứng quan sát được** (tên element, tỉ lệ tương phản đo được, giá trị pixel) —
   điểm không có bằng chứng không phải là điểm. **Người build KHÔNG BAO GIỜ tự chấm
   bài của chính mình:** lượt chấm phải do judge độc lập thực hiện — judge sub-agent
   chuyên gia được train độc lập và không tham gia build, Muse (manager) chấm trực
   tiếp, hoặc một agent/model khác với builder. Tự chấm là CẤM, không phải chỉ "không
   nên"; điểm nào không ghi rõ nhãn grader độc lập là điểm không hợp lệ. Nếu không có
   judge độc lập, điểm là "gate xanh, chưa có chấm bằng mắt" và bạn là người chấm.
6. **Sửa top 2 lỗi dưới dạng token diff** (top 1 nếu bằng chứng mỏng). Sửa ở `tokens.css`
   trước; chỉ đụng HTML/layout nếu gate vẫn fail sau khi đổi token. Giữ bản điểm cao
   nhất; vòng điểm thấp hơn thì bỏ, không iterate tiếp. Tối đa **3 vòng**.
7. **Human gate:** bảng điểm + screenshot 3 chiều rộng + 2–4 câu hỏi có options cụ thể
   + lệnh tiếp theo đề xuất, kết thúc bằng `polish`. Sau khi bạn duyệt, screenshot
   3 chiều rộng được lưu làm baseline pixel-diff để các vòng feedback sau không regress lặng lẽ.

**Dừng khi:** ≥4 mọi trục VÀ gate xanh — hoặc sau 3 vòng. Build không đạt ≥4 sau 3 vòng
là vấn đề hướng (sai reference, sai tokens) — chọn lại variant, không làm vòng thứ 4.

## Khi nào kết hợp?

| Tình huống | Thứ tự dễ dùng |
|---|---|
| Giao diện thông thường | `frontend-kit` → taste lock → build → gate (`detect`) → chấm bằng mắt → `critique`/`polish` |
| Chưa rõ gu | `frontend-kit` → 5 variant CSS-only → bạn chọn → build → gate → chấm |
| Landing page cần chuyển động | `frontend-kit` → GSAP theo yêu cầu cụ thể → xem desktop/mobile |
| Hero cần 3D | `frontend-kit` → ThreeUI → GSAP chỉ nếu cần chuyển cảnh → xem desktop/mobile |
| Chỉ sửa hiệu ứng đang lỗi | Skill GSAP liên quan → chạy trang, cuộn/thao tác để kiểm tra |
| Chỉ cần tra style/màu/font | Tra Pro Max trực tiếp (lookup, không cần orchestrator) |
| So sánh hướng thẩm mỹ | Tra Taste trực tiếp để có phương án đối chiếu |

**Ví dụ prompt đầy đủ:**

> Dùng `frontend-kit` thiết kế trang giới thiệu ứng dụng học ngoại ngữ cho người đi làm, ref kiểu Apple/Anthropic. Khóa taste trước (tokens + references), rồi build, chạy `impeccable detect`, chấm bằng screenshot thật ở desktop và mobile, sửa top 2 lỗi rồi đưa tôi chọn. Phần kể câu chuyện theo cuộn dùng GSAP nếu giúp người đọc hiểu hơn.

## Chọn skill GSAP con

| Skill | Việc chính |
|---|---|
| `gsap-core` | Chuyển động đơn giản, thời gian, easing (nhịp nhanh/chậm) |
| `gsap-timeline` | Ghép nhiều hiệu ứng theo thứ tự |
| `gsap-scrolltrigger` | Hiệu ứng theo cuộn, ghim một đoạn khi cuộn, chuyển động nhiều lớp |
| `gsap-react` | GSAP trong React/Next.js, dọn hiệu ứng khi component đóng |
| `gsap-frameworks` | GSAP trong Vue/Svelte và framework khác |
| `gsap-plugins` | Flip, Draggable, SplitText và plugin khác |
| `gsap-performance` | Hiệu ứng giật, chậm, tốn tài nguyên |
| `gsap-utils` | Các hàm hỗ trợ tính toán của GSAP |

Chỉ chọn skill khớp việc. Nếu project đã dùng thư viện animation khác, nói rõ để agent giữ đúng công nghệ của project.

## Gọi trong từng ứng dụng

| Ứng dụng | Cách nhanh |
|---|---|
| **Claude Code** | Nhắn “dùng `frontend-kit`…”; hoặc `/impeccable init`, `/impeccable critique trang chủ` |
| **Codex** | Nhắn “dùng `frontend-kit`…”; hoặc `$impeccable critique trang chủ` |
| **OpenCode** | `/impeccable init`, `/impeccable critique trang chủ`; `/frontend-kit` gọi orchestrator; với skill khác, nói “dùng skill `gsap-react`…” |
| **Gemini CLI** | Nhắn “dùng `frontend-kit`…”; hook Impeccable chưa có bằng chứng trên host này — critique chạy bằng gọi tay + `detect` |
| **GitHub Copilot** | Chỉ ở VS Code agent mode / Copilot CLI / cloud agent; dùng `.github/copilot-instructions.md` — Copilot không đọc file skill Claude/Cursor |
| **Hermes Agent** | Nhắn “dùng `frontend-kit`…”; `hermes skills list` để kiểm tra |
| **Muse Code** | Nhắn “dùng `frontend-kit`…” (đọc `~/.agents/skills/` native) |
| **CommandCode (`cmd`)** | Nhắn “dùng skill `impeccable`…”; xem skill đã nạp bằng `cmd skills list --debug` (CHƯA ĐỌC — chưa kiểm chứng) |
| **Cursor** | Nhắn “dùng `frontend-kit`…” |
| **Muse app** | Không cài được skill — dùng paste packet `templates/install/muse-app-pack.md`, mỗi cuộc trò chuyện dán lại một lần |

**Lệnh Impeccable hay dùng:** `init` ghi ngữ cảnh sản phẩm; `shape` lên hướng; `critique` nhận xét trải nghiệm và hình thức; `audit` soi khả năng dùng bằng bàn phím/đọc màn hình, khả năng thích ứng desktop/mobile và tốc độ; `polish` hoàn thiện; `adapt` chỉnh cho mobile/tablet. **`detect` là gate xác định** (62 rule, exit non-zero = sửa findings, không tốn lượt chấm) — v1 không nhắc tới nó; từ v2 nó chạy trước mọi lượt chấm bằng mắt. Mở **đúng thư mục project** trước khi gọi.

## Kiểm tra sau khi xây

1. Chạy app và mở giao diện thật bằng browser/GUI trên máy đó (serve qua http, không dùng `file://` — module script không chạy).
2. Xem ít nhất desktop và mobile (screenshot 1440 / 768 / 390); thử cuộn, bấm nút, nhập form, trạng thái lỗi và trạng thái rỗng.
3. Chạy gate (`impeccable detect` + gate scripts) trước khi chấm; sửa vấn đề nhìn thấy, rồi nhờ Impeccable `critique` hoặc `audit` phần quan trọng.
4. Sau khi duyệt, giữ lại screenshot 3 chiều rộng làm baseline pixel-diff.

Gói này **không cài `computer-use` hoặc `chromium-cdp`** vì hai công cụ trên máy nguồn phụ thuộc desktop riêng. Máy nhận có thể dùng browser/GUI khác; nhờ agent kiểm tra và chọn công cụ phù hợp nếu cần.

## Nếu agent không thấy skill

- Chạy `./verify.sh`, rồi mở **phiên mới** của ứng dụng. **Test trong cùng phiên vừa cài là false-failure mode số 1** — skill chỉ nạp khi session bắt đầu.
- Kiểm tra có skill cùng tên bên trong project (`.agents/skills`, `.opencode/skills`, `.claude/skills`) vì bản project có thể ghi đè bản global.
- Với OpenCode, `/impeccable` là lệnh riêng; các GSAP/ThreeUI/skill tham khảo có thể gọi bằng tên trong lời nhắn.
- Xem cách cài và vị trí backup trong [README.md](README.md); nguồn và giấy phép trong [SOURCES.md](SOURCES.md).
