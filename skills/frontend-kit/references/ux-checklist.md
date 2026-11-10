# UX checklist — heuristics + approved crawler rules

A vendored reference for the UX expert (`skills/frontend-kit/experts/ux.md`).
Every rule below is council-approved (`research/ux/SYNTHESIS.md` §8 UX-E,
2026-11-10). Each rule names what to look at and what counts as a pass,
with a concrete example. Rules are grouped by source corner; the
`→ UX-N` tag maps a rule to the criterion it evidences in `ux.md`.
Access date for all web sources: 2026-11-10.

**What this file is not:** it is not a second expert brief and it adds no
score. The 14 criteria in `ux.md` govern; this file is the checkable
detail behind them. Anything in `research/ux/SYNTHESIS.md` §6 PARKED
or §7 KILLED stays out — see "Deliberately excluded" at the end.

## 1. Nielsen Norman Group — top 8 (read in full)

### 1.1 The 10 heuristics — the master checklist

Source: Nielsen, Jakob. "10 Usability Heuristics for User Interface
Design." Nielsen Norman Group, originally published 1994-04-24,
updated 2026-08-20.
https://www.nngroup.com/articles/ten-usability-heuristics/

- [ ] **H1 — status visible.** Every action shows feedback within a
  reasonable time. → UX-2.
  Example: a submit button that shows a loading state, then a success
  state; a click that changes nothing on screen fails.
- [ ] **H2 — the user's language, in a natural order.** Labels, headings,
  and section order use the user's words, not internal jargon, and
  follow a natural, logical order for the task. → UX-3.
  Example: a pricing tier labelled "SKU-2 Pro" with no plain
  explanation fails; a feature list placed before the product
  description fails.
- [ ] **H3 — an emergency exit.** Every multi-step flow, modal,
  destructive action, and form has a clearly marked back / close /
  cancel / undo. → UX-4.
  Example: a modal whose only exit is completing the form fails.
- [ ] **H4 — consistency, Jakob's Law.** Different words, situations, or
  actions never mean the same thing; follow platform and industry
  conventions. → UX-5.
  Example: nav "Pricing", hero button "Plans", footer "Costs" for one
  destination fails.
- [ ] **H5 — prevent errors first.** Eliminate error-prone conditions,
  or confirm before commit. → UX-8a.
  Example: a delete that acts immediately with no confirmation fails.
- [ ] **H6 — recognition over recall.** Make elements, actions, and
  options visible; offer help in context instead of a tutorial to
  memorise. → UX-7.
  Example: at 768px the only nav is a hamburger with no visible cue
  for the primary task link — see §6.2 for when that passes.
- [ ] **H7 — flexibility and efficiency.** Shortcuts, hidden from novice
  users, speed up expert users; frequent actions can be tailored.
  → UX-7. (H7 is counted once: it appeared in both E1-1 and E1-7
  and the double-count is fixed in `ux.md`.)
  Example: no search or anchor nav, so reaching pricing requires
  scrolling through 5 sections on every visit, fails.
- [ ] **H8 — essentials only.** No irrelevant or rarely needed
  information competes with the primary goal. → UX-9a.
  Example: a hero with 3 competing CTAs plus a newsletter block above
  the primary action fails.
- [ ] **H9 — plain-language errors.** Error messages are expressed in
  plain language (no error codes), precisely indicate the problem,
  and constructively suggest a solution. → UX-8b.
  Example: an empty-form submit showing "ERR_400" with no fix
  suggested fails.
- [ ] **H10 — help when needed.** Best if no explanation is needed; where
  the task needs it, help/documentation is easy to search,
  task-focused, and lists concrete steps. → UX-9b.
  Example: a form with a complex field and no help or contact link
  anywhere fails.

### 1.2 Heuristic-evaluation procedure

Source: Moran, Kate and Gordon, Kelley. "Heuristic Evaluations: How to
Conduct." Nielsen Norman Group, published 2023-06-25, updated
2026-08-20.
https://www.nngroup.com/articles/how-to-conduct-a-heuristic-evaluation/

- [ ] Scope narrowly: one task, one section, or one device per pass.
- [ ] Two passes: first pass to learn the flow, second pass to log
  violations — one observation per line, mapped to a heuristic.
- [ ] A violation is not automatically a defect: context and available
  alternatives decide. Record severity + justification, not just a
  binary flag. A justified tradeoff names its constraint (e.g.
  reduced screen space); "it feels fine" is not a justification.
- [ ] This kit runs a single-evaluator screen, not the method's 3–5
  evaluators — every verdict says so (see `ux.md`, Role).

### 1.3 Forms — top 10 recommendations

Source: Nielsen Norman Group. "Website Forms Usability: Top 10
Recommendations." Published 2016-05-01, updated 2024-10-24.
https://www.nngroup.com/articles/web-form-design/

- [ ] Single-column layout: one field per row, except short related
  fields (City / State / ZIP) on one row. → UX-9a.
- [ ] Every field has a real `<label>` immediately above it (or beside
  it, for very long desktop forms). No placeholder text standing in
  for a label. → UX-7, UX-8b.
- [ ] Field width ≈ expected input length.
- [ ] 2–3 options as radio buttons, not a dropdown.
- [ ] Optional fields capped at 1–2 and explicitly marked.
- [ ] Formatting requirements stated *before* submission, not revealed
  by an error.
- [ ] No Reset / Clear button.
- [ ] Errors signalled by outline + red text + heavier weight — never
  colour alone; erroneous input preserved for correction.
  Example: a form that clears the user's typed email after a failed
  submit fails; an error shown in red alone, with no icon or text
  cue, fails.

### 1.4 Error-message guidelines (12, across visibility, communication, efficiency)

Source: Nielsen Norman Group. "Error-Message Guidelines." Published
2023-05-15, updated 2024-08-02.
https://www.nngroup.com/articles/error-message-guidelines/

- [ ] Message placed adjacent to the error's source; bold,
  high-contrast, red styling *plus* a non-colour cue (icon/text).
- [ ] Severity matched to presentation: toast/banner for warnings,
  modal only for blocking errors.
- [ ] No premature errors before input is complete.
- [ ] Human-readable, jargon-free wording; error codes hidden or
  minimised; precise description of the problem + a concrete remedy.
- [ ] Positive, non-blaming tone — no "invalid / illegal / incorrect".
- [ ] The user's input preserved; a one-click fix offered where the
  system can guess the correction (e.g. matching city for a ZIP code).
  → UX-8b.

### 1.5 Reporting errors in forms (10 guidelines)

Source: Nielsen Norman Group. "10 Design Guidelines for Reporting
Errors in Forms." Published 2019-02-03, updated 2024-12-12.
https://www.nngroup.com/articles/errors-forms-design-guidelines/

- [ ] Inline validation on field completion; success indicators only
  for complex fields (password/username), never for trivially
  required ones.
- [ ] Error text directly next to the offending field, so the user
  never has to memorise it; colour + icon (never colour alone).
- [ ] Modals / confirmation dialogs used sparingly (they force the user
  to memorise instructions).
- [ ] Never validate before input is complete.
- [ ] A top-of-form validation summary is never the *only* indication.
- [ ] Never report errors via tooltip / hover (unavailable on touch).
- [ ] After 3+ repeats of the same error, offer extra help (link to
  support / revised guidance) — a signal the design itself is at
  fault. → UX-8b.

**Validation timing (settled):** validate inline on blur, clear live
on keystroke (NN/g + Baymard weight). GOV.UK dissent recorded: GOV.UK
validates on submit, not on exit. The behavioural half — driving a
form in a headless browser to prove the timing — is PARKED (no
harness exists); this checklist states the rule, it does not run the
probe.

### 1.6 Visibility of system status

Source: Nielsen Norman Group. "Visibility of System Status (Usability
Heuristic #1)." Published 2018-06-03, updated 2024-01-26.
https://www.nngroup.com/articles/visibility-system-status/

- [ ] Every user action produces immediate, visible feedback (button
  state change, checkmark, progress indicator) — the user never
  wonders whether a click registered.
- [ ] Any action taking ~1 second or more shows a progress indicator;
  waits over ~10 seconds show percent-done / steps completed and
  remaining — a bare spinner is insufficient.
- [ ] State changes the user did not cause (item went out of stock,
  list contents changed) are communicated explicitly, not silently
  applied.
- [ ] Status that drives a decision (low stock, distance to free
  shipping) is visible at the decision point. → UX-2.
  Example: a low-stock row whose "Order today" status is amber text
  with no action, and no visible feedback after the user acts on it,
  fails.

### 1.7 Recognition and recall

Source: Nielsen Norman Group. "Memory Recognition and Recall in User
Interfaces." Updated 2024-01-31.
https://www.nngroup.com/articles/recognition-and-recall/

- [ ] Navigation and actions shown as labelled menus/buttons, not
  hidden behind icons alone — unlabeled icons fail this check.
- [ ] No gesture-only or shortcut-only operation without a visible cue.
- [ ] No tutorial that must be memorised — help is contextual, at the
  point of need.
- [ ] Recently viewed items, search history, saved lists, and drafts
  are surfaced so users recognise rather than recall; search
  suggestions are present to convert query recall into recognition.
  → UX-7.
  Example: a search box with no suggestions and no recent searches,
  on a page whose task is finding a previously seen item, fails.

### 1.8 Task analysis — the task-flow check

Source: Nielsen Norman Group. "Task Analysis: Support Users in
Achieving Their Goals." Published 2020-09-20, updated 2024-01-19.
https://www.nngroup.com/articles/task-analysis/

- [ ] For the page's stated user goal, enumerate the task sequence and
  verify the built flow covers every step in the right order — no
  missing step, no unnecessary step, no step that forces recall of
  information from an earlier screen.
- [ ] Count steps, frequency, cognitive complexity, and time per step:
  a flow with many steps or heavy mental operations is a UX defect
  even when every individual screen looks clean.
- [ ] A design that solves the wrong problem fails no matter how good
  its UI — an unjustified section is the plan-level form of that
  failure. → UX-1, UX-9a, UX-14.
  Example: a landing page whose first viewport answers step 3
  (pricing) while step 1 ("grasp what the tool does") sits below the
  fold, with no inventory note justifying the inversion, fails.

## 2. Material Design 3 — narrowed (primaries only)

Only the primaries read in full on m3.material.io are used below.
Parked and therefore absent: 48dp touch target, motion durations,
type scale / shape values, #8 motion (secondary distillation),
and all secondary-only rules.

### 2.1 Window size classes — responsive behaviour at five breakpoints

Source: Material Design 3. "Applying layout — window size classes."
https://m3.material.io/foundations/layout/applying-layout/window-size-classes
(accessed 2026-11-10).

- [ ] Responsive behaviour is judged at five opinionated breakpoints,
  not per-device: Compact <600dp, Medium 600–839dp, Expanded
  840–1199dp, Large 1200–1599dp, Extra-large 1600dp+.
- [ ] Navigation swaps form as width grows (bar → rail → drawer);
  pane count goes 1 → 2 → 3; body-text line length stays 40–60
  characters at every size.
- [ ] Components are only ever swapped for functionally equivalent
  ones — never a button for a chip. → UX-6, UX-11.
  Example: a nav that simply disappears below 820px with no
  replacement fails; a nav that swaps to a rail or drawer carrying
  the same destinations passes.

### 2.2 Dialogs — interruption has a strict budget

Source: Material Design 3. "Dialogs — guidelines."
https://m3.material.io/components/dialogs/guidelines
(accessed 2026-11-10).

- [ ] Dialogs are reserved for high-importance, blocking decisions;
  low/medium-priority messages belong in a snackbar.
- [ ] A dialog holds at most two actions; the confirming action sits
  closest to the edge; dismissive actions are never disabled;
  confirming actions are never vague ("Send" / "Create", not "OK" /
  "Done").
- [ ] Field errors appear inline where they occur; only general (e.g.
  network) failures get a dialog. → UX-4, UX-8a.
  Example: a dialog with three actions, or a confirm button labelled
  "OK", fails.

### 2.3 Colour as paired roles, not raw hex

Sources: Material Design 3. "Color — how the system works."
https://m3.material.io/styles/color/system/how-the-system-works ;
"Advanced color customizations — applying color roles."
https://m3.material.io/styles/color/advanced/apply-colors
(accessed 2026-11-10).

- [ ] Every surface/text pair is a role + its `on-` role
  (primary/on-primary, surface/on-surface), generated from one
  source colour; no hard-coded hex on text-bearing surfaces.
- [ ] Text/background contrast meets 4.5:1 (small text) and 3:1
  (large text); the pairing must survive in both light and dark
  themes. → (colour expert's numbers; UX cites them only where a
  contrast failure blocks the task.)

### 2.4 Labelling elements — purpose, not appearance

Source: Material Design 3. "Accessibility designing — labeling
elements." https://m3.material.io/foundations/designing/elements
(accessed 2026-11-10).

- [ ] Every interactive element a sighted user understands from vision
  alone carries a text equivalent: icon-only buttons, status icons,
  and meaningful images get labels describing their **purpose, not
  their appearance** ("Voice search", not "Microphone").
- [ ] Generic links ("Learn more") and repeated generic buttons
  ("Save") get disambiguating context; decorative elements are
  explicitly marked hidden.
- [ ] The label never contains the element role ("Got it button" is
  wrong — the screen reader adds "button" itself). → UX-3, UX-10.
  Example: an icon-only mic button with no accessible name fails;
  a "Learn more" link repeated three times with three different
  destinations fails.

### 2.5 Native elements first; three input modes

Sources: Material Design 3. "Accessibility designing — overview."
https://m3.material.io/foundations/designing/overview ;
"Accessibility overview — assistive technology."
https://m3.material.io/foundations/overview/assistive-technology
(accessed 2026-11-10).

- [ ] Use native platform elements (e.g. the standard platform dialog)
  rather than custom look-alikes — non-standard elements need extra
  testing to work with assistive technology.
- [ ] Three input modes must all work: keyboard/D-pad (linear
  selection-to-selection movement), screen reader (all visible
  content plus hidden labels verbalised, including alt text for
  icons and headings), and switch input (items scanned and
  highlighted in turn).
- [ ] No interaction that requires precise pointer input only.
  (Focus-ring / keyboard / contrast failures belong to the
  accessibility expert, not UX — see `ux.md`, priority rule.)

## 3. Baymard Institute — transactional briefs only

Baymard is e-commerce-only. Its rules transfer to any transactional
flow (forms, checkout, product detail) and do NOT stretch to
marketing sites, dashboards, or SaaS onboarding without a separate
source. §4 of the Baymard crawler ("all read in full") is KILLED;
the 68/31/57/42 numbers are struck and appear nowhere below.

### 3.1 Checkout

Source: Baymard Institute. "Checkout UX Best Practices 2026."
https://baymard.com/research-articles/current-state-of-checkout-ux
(published 2024-11-13, updated 2026-11-03; accessed 2026-11-10).

- [ ] Guest checkout is offered; account creation is deferred to the
  post-purchase confirmation step — no password field appears
  before/during checkout.
- [ ] Accordion checkouts collapse completed steps into visible
  summaries with an Edit link.
- [ ] Shipping options show a concrete delivery *date* ("Delivers
  Thursday"), not just a speed ("2–3 business days"); any cutoff is
  a countdown ("order within 43 min"), not a static timezone-bound
  time.
- [ ] Cart quantity is changed with +/− buttons (or buttons + text
  field), never a bare text field that invites "21"-style typos.
- [ ] **Both** required and optional fields are explicitly marked
  (asterisk + "(optional)"); marking only one side is a fail.
- [ ] A required phone field carries an inline explanation of why it
  is needed. → UX-1, UX-4, UX-8a.
  Example: a checkout that forces account creation before payment
  fails; a quantity field that is a bare text input fails.

### 3.2 Checkout flow — countable form length, inline errors, enclosed flow

Source: Baymard Institute. "Ecommerce Checkout UX Guide — Optimize
Your Order Flow." https://baymard.com/blog/checkout-flow-ux-optimization
(accessed 2026-11-10; final ~50 lines, image captions + footer, unread).

- [ ] Progress indicator is a literal 1:1 map of the checkout steps;
  past steps are clickable; primary buttons carry descriptive labels
  ("Continue to Payment", "Place Order"), not bare "Continue".
- [ ] Form length is countable: ideal checkout is 12–14 form elements
  / 7–8 fields vs. the 23.48-element average. Single "Full Name"
  field; "Address Line 2" hidden behind a link; billing defaults to
  shipping.
- [ ] Errors: inline next to the field, adaptive/specific ("ZIP code
  is too short", never "Invalid input"); user auto-scrolled to the
  first error; **all entered data preserved after an error** —
  especially card data.
- [ ] Checkout is "enclosed": no site navigation / promos / newsletter
  pop-ups in the flow. → UX-1, UX-8b, UX-9a.

### 3.3 Product page

Source: Baymard Institute. "Product Page UX Best Practices 2026."
https://baymard.com/research-articles/current-state-ecommerce-product-page-ux
(published 2023-10-24, updated 2026-03-18; accessed 2026-11-10).

- [ ] Variant selection uses exposed button selectors (size buttons
  with out-of-stock states visible), never a drop-down that hides
  availability.
- [ ] An "in scale" image (product next to a hand / person /
  known-size object) and, for wearable products, a human-model image
  are present.
- [ ] Price-per-unit is shown for multi-quantity products; lowest
  total order cost (incl. shipping estimate) appears near the Buy
  section — no "add to cart to see the price" trap.
- [ ] Return-policy link/summary is in the main product-page content,
  not footer-only.
- [ ] Reviewer-submitted images open in a carousel navigable *across*
  reviews (arrow/swipe), not trapped inside one review; staff replies
  to negative reviews are visually distinct from the reviews.
  → UX-1, UX-9a.

### 3.4 Payment step

Source: Baymard Institute. "Payment UX: Research-Backed Standards for
Ecommerce Checkouts." https://baymard.com/blog/payment-ux
(published 2026-06-01; accessed 2026-11-10).

- [ ] Final total (shipping + taxes + fees) is visible *before* the
  payment fields; order summary stays visible (or
  collapsed-but-accessible) on the payment step; primary CTA says
  what happens next ("Continue to Review", not "Continue").
- [ ] Payment methods are grouped (cards / wallets / BNPL); most common
  method preselected with its fields shown by default; rarer options
  behind "more options"; at least one third-party option (Apple Pay /
  Google Pay / PayPal) is offered as a distinct button *above* the
  card form, and selecting it renames the primary button
  ("Continue to PayPal").
- [ ] Card form mirrors the physical card: auto-detected card type,
  auto-formatted spaces, two-digit MM/YY expiry, security-code hint,
  front-end Luhn validation.
- [ ] Promo/coupon field is collapsed by default; no promo banners or
  newsletter sign-ups on the payment step. → UX-1, UX-3.

### 3.5 Cross-page sweep (35 practices)

Source: Baymard Institute. "35 Data-Driven Ecommerce Best Practices."
https://baymard.com/blog/ecommerce-ux-best-practices
(published 2021-12-09, updated 2026-06-11; accessed 2026-11-10).

- [ ] Search field is visually obvious on the homepage (bold border /
  contrasting background, not lost among graphics); exact-match
  products rank top in search results.
- [ ] Category chunks: subdivide at ~10 subcategories, ≥10 products at
  the deepest level; parent category headers are clickable links.
- [ ] Product lists: total item count shown above *and* below the list;
  "Load More" instead of pagination or endless scroll; rating average
  **and** count of ratings on every list item; checkboxes on every
  filter option; sort by Price / Rating / Best Selling / Newest.
- [ ] Product page: vertically collapsed sections with clear titles
  (not horizontal tabs); 3–5 images minimum; video for top/complex
  products; Add to Cart as the single visually unique CTA.
- [ ] Sitewide: cart icon top-right with badge count; no auto-opening
  live-chat overlays; FAQ link in footer. → UX-1, UX-3, UX-9a.

### 3.6 Mobile (practices 1–7 only; 8–10 unread)

Source: Baymard Institute. "Mobile UX Trends 2026: 10 Best
Practices." https://baymard.com/research-articles/mobile-ux-ecommerce
(accessed 2026-11-10; lines 0–217 of 343 read — practices 8–10
unread, fetch rate-limited, not paywalled).

- [ ] Mobile search field has an explicit in-UI "submit" button
  adjacent to it — users must not depend on the OS keyboard's search
  key.
- [ ] Every catalog level offers a "View All" menu item ("View All
  Women's", "View All Coats", …).
- [ ] Current scope is highlighted in the main navigation (93% of
  mobile sites fail this, per the article).
- [ ] Address validator/lookup is present at the shipping step —
  mobile typing errors are far more frequent.
- [ ] Validation errors are adaptive: the message names the exact
  subrule ("missing the @ character" vs. "missing part of the
  domain"), with 4–7 variants per complex field; 93% of sites fail
  this, per the article. → UX-7, UX-8b.

### 3.7 Homepage & navigation (practices 1–6 only; 7–10 unread)

Source: Baymard Institute. "Homepage & Navigation UX Best Practices
2026." https://baymard.com/research-articles/ecommerce-navigation-best-practice
(accessed 2026-11-10; lines 0–207 of 369 read — practices 7–10
unread, fetch rate-limited, not paywalled).

- [ ] On mobile, product categories are the first level of the main
  navigation — not hidden behind a single "Products" /
  "Departments" item.
- [ ] Product types with shared attributes are one list with
  *filters*, not separate categories — and multiple filters must be
  combinable (selecting a second filter must not reset the first).
- [ ] Current scope is highlighted in the main navigation on desktop
  (96% fail, per the article) and mobile; parent category headings
  are clickable links to intermediary category pages.
- [ ] Category menus subdivide at ~10 items. → UX-6, UX-7.

### 3.8 Prioritisation figure (vintage noted)

Source: Baymard Institute. "Cart Abandonment Rate: 50 Statistics
(2026)." https://baymard.com/lists/cart-abandonment-rate
(last updated 2026-10-28; accessed 2026-11-10).

- Average documented cart abandonment **70.22%** — 50 studies,
  2006–2025, range 55–84%. Vintage note: the figure is an unweighted
  mean across heterogeneous studies spanning two decades, not "your
  rate"; the earlier 49-study count gave 70.19% — the two figures
  differ by study-count vintage, do not quote both as one number.
  Excluding "just browsing" (42%), the fixable reasons are extra
  costs 40%, slow delivery 20%, card distrust 19%, forced account
  18%, too-long/complicated checkout 17%, site errors 17%,
  unsatisfactory returns 13%, total cost not visible up front 12%,
  not enough payment methods 9%. Use this to rank which of §3.1–§3.7
  is a gate vs. a nice-to-have — it is a prioritisation source, not
  a design rulebook.

## 4. WCAG 2.2 — references (reasoning manual, not a checklist)

WCAG enters this file as references: the Quickref, What's New in
2.2, the APG introduction, and the Accessibility Principles page are
the reasoning manual the UX expert cites when a gate finding and a
vision judgement disagree. APG widget rules are PARKED (individual
pattern pages unread — rate-limited, not paywalled) and must not be
cited as rules. The four vision-only additions (focused-state
screenshot / Tab walkthrough, error-state render, 320px /
forced-text-spacing render, APG keyboard checks) are PARKED pending
a costed pipeline proposal — they are not checks in this file.

Sources (all accessed 2026-11-10):
- W3C WAI. "How to Meet WCAG 2.2 (Quickref Reference)."
  https://www.w3.org/WAI/WCAG22/quickref/ (read in full).
- W3C. "Web Content Accessibility Guidelines (WCAG) 2.2."
  https://www.w3.org/TR/WCAG22/ (front matter read in full; body
  success-criterion text read via the Quickref — same normative
  wording).
- W3C WAI. "What's New in WCAG 2.2."
  https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/
  (read in full; WCAG 2.2 published as a W3C Recommendation
  5 October 2023; 9 additional criteria; 4.1.1 Parsing obsolete).
- W3C WAI. "Understanding WCAG 2.2."
  https://www.w3.org/WAI/WCAG22/Understanding/ (index read in full;
  individual Understanding documents not opened — open per
  criterion when adopted).
- W3C WAI. "ARIA Authoring Practices Guide (APG) — Patterns index."
  https://www.w3.org/WAI/ARIA/apg/patterns/ (index read in full;
  individual pattern pages not opened).
- W3C WAI. "APG Introduction."
  https://www.w3.org/WAI/ARIA/apg/about/introduction/ (read in
  full). Status rule: APG patterns are *not* a normative standard —
  cite as "APG pattern X expects Y; deviation needs a reason", never
  as a conformance failure.
- W3C WAI. "Accessibility, Usability, and Inclusion."
  https://www.w3.org/WAI/fundamentals/accessibility-usability-inclusion/
  (read in full). Licence to treat WCAG as UX: the Understandable
  criteria (predictable operation, helpful errors, clear labels)
  *are* usability criteria — but a green pa11y run is not a UX pass.
- W3C WAI. "Accessibility Principles."
  https://www.w3.org/WAI/fundamentals/accessibility-principles/
  (read in full). Two rules worth promoting verbatim: (a) link
  purpose should be evident "ideally even when the link is viewed on
  its own"; (b) alt text must convey *purpose/function*, not
  appearance ("search", not "magnifying lens").

Reference points the expert may cite (AA is the practical target;
AAA is not recommended as a whole-site policy):

- **2.4.7 Focus Visible (AA):** a visible focus indicator exists for
  every keyboard-operable control. **2.4.11 Focus Not Obscured,
  Minimum (AA, new in 2.2):** the focused element is never entirely
  hidden by author content (sticky header/footer, banner, chat
  widget). **2.4.13 Focus Appearance (AAA, new in 2.2):** focus
  indicator ≥ a 2px perimeter of the control and ≥3:1
  focused-vs-unfocused — usable as a quantified vision check, not a
  FAIL.
- **2.5.8 Target Size, Minimum (AA, new in 2.2):** targets ≥24×24px
  or the spacing/equivalent/inline exceptions. The kit's own 44px
  rule already exceeds this floor (44×44px is the AAA criterion
  2.5.5); WCAG's contribution is the exception logic, not a bigger
  number. See §6.3 for the multiply-corroborated 44px hit-region rule.
- **1.4.3 Contrast, Minimum (AA):** text ≥4.5:1, large text ≥3:1.
  **1.4.11 Non-text Contrast (AA):** UI components, focus
  indicators, input borders ≥3:1 vs adjacent colours.
- **1.4.10 Reflow (AA):** at 320 CSS px width, no loss and no
  two-dimensional scrolling (except genuinely 2-D content).
  **1.4.12 Text Spacing (AA):** no loss when line-height 1.5 /
  paragraph 2 / letter 0.12 / word 0.16 spacing is forced.
- **1.4.13 Content on Hover or Focus (AA):** hover/focus popups are
  dismissible (Esc), hoverable, and persistent.
- **2.4.4 / 2.4.6 Link Purpose and Headings-and-Labels:** the *words*
  describe topic or purpose — a semantic judgement, not a DOM check.
  **2.5.3 Label in Name (A):** accessible name contains the visible
  label text.
- **3.3.1 Error Identification (A) / 3.3.3 Error Suggestion (AA):**
  errors are named in text *and* a usable correction is offered.
  **3.3.4 Error Prevention, Legal/Financial/Data (AA):** reversible /
  checked / confirmed submissions.
- **2.5.7 Dragging Movements (AA, new in 2.2):** every drag has a
  tap/click alternative (up/down arrows or buttons).
  **3.2.6 Consistent Help (A, new in 2.2):** help in the same
  place/order on every page. **3.3.7 Redundant Entry (A, new in
  2.2):** never ask twice in one process. **3.3.8 Accessible
  Authentication, Minimum (AA, new in 2.2):** no puzzle / memory test
  to log in without an alternative or assistance.
- **4.1.1 Parsing (A): removed / obsolete in WCAG 2.2.** Do not cite
  as a WCAG failure — html-validate failures are hygiene, not WCAG
  violations.
- **Gate labels:** pa11y is NOT installed on this VM (verified
  2026-11-10) — the gate's WCAG coverage is conditional on the tool
  being present at all. Do not write a rule that assumes pa11y ran.

## 5. Patterns — format, vocabulary, two measured cases

### 5.1 Documentation format (copy this, not just the patterns)

Source: GOV.UK Design System.
https://design-system.service.gov.uk/ (home page read in full;
individual pattern pages partially read via search excerpt;
accessed 2026-11-10).

Every pattern ships with **when to use / when not to use / how it
works / research on this pattern**, plus working code. That format
is the model for how the kit's own expert skill documents a
pattern — a rule without its when-not-to-use and its research note
is not a pattern, it is taste.

GOV.UK pattern rules liftable verbatim:

- [ ] One question per page ("Question pages" pattern).
- [ ] A "Check your answers" review page before submit, with per-row
  Change links; then a confirmation page with a reference number.
- [ ] Error summaries that list every error and move focus to the
  list. → UX-4, UX-8b.

### 5.2 Pattern vocabulary

Source: UI-Patterns.com — UI Design Patterns Library.
http://ui-patterns.com/patterns (patterns index read in full;
individual pattern pages not opened; accessed 2026-11-10;
CC BY-NC-SA 2.5 Denmark).

- Each entry is structured as problem → when (not) to use → how →
  why, which maps directly onto a deterministic gate ("does this
  page use Wizard + Steps Left for a multi-step flow? Is there a
  Forgiving Format on inputs? Are defaults good?").
- Prefer the UI patterns over the persuasive ones: persuasive patterns
  (scarcity, sunk-cost) are easy to misuse as dark patterns and need
  an ethics gate if cited at all.
- Caveat: the index carries no measured outcomes per pattern — it is
  a taxonomy with examples, not an evidence base. Pair it with §5.3
  before any pattern becomes a kit rule.

### 5.3 Two measured cases (as labelled)

**Case 1 — GDS Betagov, plain scannable content.**
Source: Breeze, Nick. "Quantitative testing Betagov content and
layout." GDS Technology Blog, 2012-01-13.
https://gds.blog.gov.uk/2012/01/13/quantitative-testing-betagov/
(read in full; accessed 2026-11-10). Method: 1,800-person
representative online panel; Directgov vs Betagov versions of Tax
and Going-to-Court content; four find-the-information tasks each.
Measured: Betagov users found information in **80 seconds on average
vs 123 seconds** for Directgov (some tasks over a minute quicker);
task success **~60% → nearly 70%**; **90%** rated Betagov
"quite/very easy" to find information in. Author's caution: a
1,800-person panel is not a substitute for real users with real
needs, and the projected "1M+ more needs met per month / 215,000
hours saved" is a conditional extrapolation, not a measurement.
Checkable rule: plain, scannable, right-amount content beats dense
official copy on time-on-task (~35% faster) and task success
(~10 points) — short paragraphs, headings that carry the
information, no jargon, one idea per section. → UX-3, UX-9a.

**Case 2 — GOV.UK Pay migration to the Design System.**
Source: GDS Technology Blog. "The benefits of migrating GOV.UK Pay's
codebase to the GOV.UK Design System." 2018-12-21.
https://gdstechnology.blog.gov.uk/2018/12/21/the-benefits-of-migrating-gov-uk-pays-codebase-to-the-gov-uk-design-system/
(read in full; accessed 2026-11-10). Method: incremental migration
over ~4 months / ~50 pull requests across 4 Node.js microservices.
Measured: Lighthouse performance **91 → 99/100**; first meaningful
paint on mobile 3G **2.4s → 0.9s (−62.5%)**; CSS **93% smaller**,
JS **61% smaller**; codebase **−1,400 lines**, CSS files 4 → 1.
Checkable rule: adopting a shared, tested component system is a
measurable performance intervention, not just a consistency one —
gate a built page on Lighthouse + first-paint before/after, and on
"no bespoke CSS/JS where a system component exists". Process lesson:
migrate incrementally (one template at a time, old and new
frameworks side by side) rather than big-bang.

## 6. Forms & mobile — static rules now

Behavioural rules (driving a form in a headless browser) are PARKED
— no harness exists. The rules below are all checkable statically
from HTML/CSS or a 390px screenshot.

### 6.1 Labels and placeholders

Sources: NN/g "Website Forms Usability" (§1.3 above); NN/g.
"Placeholders in Form Fields Are Harmful." Published 2014-05-11,
updated 2024-01-26. https://www.nngroup.com/articles/form-design-placeholders/
(read in full; accessed 2026-11-10).

- [ ] Every `<input>` / `<textarea>` has a persistent, visible
  `<label>` placed *outside* the field.
- [ ] A `placeholder`, if present at all, may only carry a
  supplementary format example (e.g. `name@example.com`) and must
  never be the sole label.
- [ ] Floating labels are a second-best fallback (label always
  visible, in-field or above), not equivalent to a static label
  above the field.
  Gate: fail if any field lacks an associated visible label, or if
  its only label text lives in `placeholder`. → UX-7, UX-8b.

### 6.2 Mobile navigation

Source: Nielsen Norman Group. "Basic Patterns for Mobile Navigation:
A Primer." Published 2015-11-15, updated 2024-01-24.
https://www.nngroup.com/articles/mobile-navigation-patterns/
(read in full; accessed 2026-11-10).

- [ ] A persistent tab/navigation bar holds at most 5 destinations,
  each icon + text label, and is the page's main chrome — if the site
  has more than 5 top-level options, a tab bar is the wrong pattern.
- [ ] A hamburger/menu-hidden navigation is acceptable only for
  browse-mostly, content-heavy sites — for task-oriented sites the
  primary destinations must be visible without opening a menu, and
  if a hamburger is used, supporting navigation (in-content links,
  footer nav repeat) must exist on interior pages. (This is the same
  hamburger rule as `ux.md` criterion 6.)
- [ ] Content over chrome: at 390px the combined persistent chrome
  (nav + header + search) must not crowd out content — navigation
  must not consume the majority of the first viewport. → UX-6.

### 6.3 Hit regions — 44×44 CSS px (multiply corroborated)

The 44px figure is corroborated across independent sources, not
resting on any single one: Apple HIG "Buttons" ("a button needs a
hit region of at least 44x44 pt"), WCAG 2.2 SC 2.5.5 Target Size,
Enhanced (AAA, 44×44px), and the kit's own `--tap-min` 44px rule.
(The Apple page itself was not opened in this run — verified
verbatim in three independent secondary sources quoting the HIG
directly and in an Apple-docs mirror excerpt; treat the Apple page
as "verify by direct open before freezing the rule". The HIG corner
as a whole is PARKED; only this multiply-corroborated number is
used, as corroboration.)

- [ ] Every interactive element's *hit region* — not its visible
  glyph — is ≥ 44×44 CSS px at 390px. (WCAG 2.2 AA floor is 24×24
  CSS px, SC 2.5.8; the kit's 44px stands as the stricter bar.)
- [ ] No 8px inter-target gap rule exists in this kit — the 8px gap
  rule was KILLED as invented (occurs once in the crawler file with
  no source). Do not cite it. → UX-10.
  Example: a 16px-tall text link with no padding, whose tap area is
  16px tall at 390px, fails; a 24px icon inside a 44px padded button
  passes.

### 6.4 Thumb reach — primary action in the bottom half at 390px

Source: Hoober, Steven. "How Do Users Really Hold Mobile Devices?"
UXmatters, 18 February 2013.
https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php
(read in full except the final ~34 lines "Next Steps" tail;
accessed 2026-11-10).

- [ ] The primary CTA and the most-used actions sit in the bottom
  half of the screen at 390px (the thumb's natural arc), and never
  sit only in a top corner; destructive or rarely-used actions may
  live in the hard-to-reach top zone.
- [ ] Do NOT assume a single fixed grip — check "primary action
  reachable in the bottom half", not "everything in the bottom
  third", and do not treat top-corner placement of a *secondary*
  action as a failure.
- Caveat: the 49% one-handed / 36% cradled / 15% two-handed split is
  2013, pre-large-phone data — directional, not current; the
  principle (design for the most constrained grip) is the durable
  part. → UX-1.

### 6.5 Error summary (GOV.UK, static form)

Source: GOV.UK Design System. "Error summary" component.
https://design-system.service.gov.uk/components/error-summary/
(read in full for guidance — usage + "How it works" + linking
rules; accessed 2026-11-10).

- [ ] On any failed submit, the page shows BOTH (1) an error summary
  at the top headed exactly "There is a problem", with one link per
  error, each link targeting the field in error and worded
  identically to the inline message, with keyboard focus moved to
  the summary; AND (2) an inline error message next to each field
  in error.
- [ ] The page `<title>` is prefixed "Error: " while errors are shown.
  (Static rule only: the behavioural probe — submitting known-bad
  values and asserting summary presence, link count, and title
  prefix — is PARKED with the rest of the behavioural form gates.)
  → UX-8b.

## Deliberately excluded (PARKED / KILLED — do not re-add without a council vote)

- **85% figure** ("5 users uncover ~85% of problems") and **Seckler
  78/42** (guideline-compliant forms 78% one-try error-free vs 42%
  for violating forms) — PARKED pending verification.
- **68 / 31 / 57 / 42** (Baymard) — KILLED as untraceable; 68%/57%/42%
  occur nowhere else in the crawler file, 31% comes from a
  snippet-only item.
- **8px inter-target gap rule** — KILLED as invented.
- **Baileigh Industrial case study** (+85% tree-test findability) —
  PARKED pending canonical re-read (read only via a syndicated copy,
  not the canonical NN/g page).
- **HIG #2–#8 + #1 tail** — PARKED (mirror-only, predates the June
  2026 principle change); only the multiply-corroborated 44px hit
  region (§6.3) is used, as corroboration.
- **Material 48dp touch target, motion durations, type scale / shape
  values, #8 motion** — PARKED (secondaries or 429'd primaries).
- **"20–28% of words read"** — dwell-time conversion, not a measured
  figure; do not cite.
- **Behavioural form gates** (headless-browser form driving: blur /
  keystroke timing probes, failed-submit probes) — PARKED, no harness
  exists. The timing rule itself (blur-default, GOV.UK dissent) is
  stated in §1.5.
- **APG widget rules** (per-widget keyboard tables) — PARKED (individual
  pattern pages unread).
- **UX-F vision-only additions** (focused-state screenshot / Tab
  walkthrough, error-state render, 320px / forced-text-spacing
  render, APG keyboard checks) — PARKED pending a costed pipeline
  proposal.
- **NNG snippet / partial items** (progress indicators, layer-cake
  scanning, hostile error messages, 5-user rule, card sorting tail,
  and the rest of `c-nng.md` §2–§3) — PARKED; only the top 8 read in
  full are in §1.
- **Baymard practices 8–10 (mobile) and 7–10 (homepage & navigation)**
  — unread (fetch rate-limited); re-fetch before use.
- **Agency / Behance / Dribbble case studies** — self-reported or
  estimated numbers, no independent verification; corroboration at
  best, never a kit rule.
