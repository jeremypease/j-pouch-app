# J-Pouch Design System

**Company:** J-Pouch: Your Companion — an app for people transitioning to, or living with, a j-pouch (ileal pouch-anal anastomosis) after colectomy surgery.

## Sources
No codebase, Figma file, slide deck, or existing brand assets were attached to this project. Everything here — palette, type system, iconography, and the mobile UI kit — was designed from scratch based on the company description and the answers to a direction questionnaire (tone: clinical-but-friendly; palette: teal/tan; type: decide-for-me; no logo yet). If a codebase, Figma link, or brand guide becomes available, re-run this skill and it will be treated as ground truth over what's here.

## Product
Single surface for now: **the J-Pouch mobile app** — daily tracking for people recovering from or living with a j-pouch: bowel output/frequency log, hydration, medications & supplements, symptom check-ins, and a recovery-stage timeline (pre-op → takedown → adjustment → stable). Built for a health context: calm, precise, never clinical-cold or cutesy.

## Index
- `styles.css` — root stylesheet, import-only. Pulls in `tokens/`.
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `effects.css`.
- `guidelines/` — specimen cards for the Design System tab (Colors, Type, Spacing, Effects, Brand groups).
- `components/core/` — Button, IconButton, Icon, Badge, Tag, Card
- `components/forms/` — Input, Select, Checkbox, Radio, Switch
- `components/feedback/` — Toast, Tooltip, Dialog
- `components/navigation/` — Tabs
- `ui_kits/mobile-app/` — interactive click-through recreation: onboarding, dashboard, log-entry, symptom check-in, settings.
- `SKILL.md` — portable skill definition for Claude Code.

### Intentional additions
No component source was provided, so this is a from-scratch standard set (Button, IconButton, Input, Select, Checkbox, Radio, Switch, Card, Badge, Tag, Tabs, Dialog, Toast, Tooltip) sized to the app's needs. Two domain-specific additions beyond the standard set:
- **StatCard** (`components/core/`) — the dashboard's metric tile (today's output count, hydration, etc). Central to how this app presents data; a generic Card doesn't cover it.
- **Icon** (`components/core/`) — thin wrapper around the Lucide icon set (see Iconography) so components reference icons by name rather than inline SVG.
- **TabBar** (`components/navigation/`) — persistent bottom navigation (Home/Log/Insights/Profile); this is the app's primary navigation pattern per the Visual Foundations layout rules.

## Content Fundamentals
**Tone:** clinical but friendly — precise and medically accurate, never sterile. Think "a good GI nurse," not a hospital form and not a wellness influencer.
- **Address:** direct second person, "you/your" — never third-person distancing ("the patient"). *"Log today's output"*, not *"Users can log output."*
- **Voice:** plain, declarative sentences. Short. No forced enthusiasm, no hedging. *"Your output is trending down this week."* not *"Great job! You're crushing your output goals! 🎉"*
- **Vocabulary:** correct clinical terms used plainly and defined on first use where it helps (*"output (bowel movements)"*), not euphemism, not jargon-for-its-own-sake. Say "stoma," "pouch," "takedown," "output" — don't soften into vague wellness-speak.
- **Casing:** sentence case everywhere — headings, buttons, nav labels. Never title case, never all-caps except tiny eyebrow labels (e.g. section overlines at `--text-2xs` + `--tracking-wider`).
- **Emoji:** none in UI chrome or system copy. Fine only in truly optional user-authored free text (e.g. a personal note field), never authored by the product.
- **Numbers/units:** always shown with units, right-aligned in data contexts, monospace (`--font-mono`) for anything numeric/tabular — output counts, times, doses — so digits don't jitter and scan cleanly.
- **Errors & empty states:** state the fact, then the next action. *"No entries yet today. Log your first one."* Never blame the user, never over-apologize.
- **Example copy pairs:**
  - Button: "Log output" (not "Add Entry!" / "Track it now")
  - Empty state: "Nothing logged yet today." (not "It's quiet here...")
  - Reminder: "Time for your evening dose of loperamide." (not "Don't forget your meds! 💊")
  - Milestone: "12 weeks since takedown." (not "You're crushing recovery!")

## Visual Foundations
- **Palette:** deep teal (`--teal-500` #3c7a6a) as primary — calm, clinical-adjacent without reading cold — on a warm off-white/pale-teal background (`--teal-50`). Warm tan/apricot (`--tan-400`) as the sole accent, used sparingly for highlights, active states on secondary actions, and data-visualization warmth. Neutrals are warm grays, not blue-grays. Semantic colors (success/warning/danger/info) sit in the same warm-muted family — no saturated red/green alarm colors; this is a body-function tracker, and loud "success/fail" color language reads punitive.
- **Type:** `Manrope` (display/headings) — geometric but slightly rounded, friendly without being juvenile. `IBM Plex Sans` (body/UI) — clean, precise, built for interfaces. `IBM Plex Mono` (numbers, timestamps, dosages, log data) — gives tracked data a precise, tabular feel and visually separates "your data" from "the app's voice." Headings use tight tracking and `--weight-extrabold`/`--weight-bold`; body stays regular/medium.
- **Spacing:** 4px base scale (4/8/12/16/20/24/32/40/48/64/80/96). Generous vertical rhythm between sections (32–48px) — this is a health app used one-handed, often quickly; touch targets and breathing room matter more than density.
- **Backgrounds:** flat, no gradients, no textures/patterns, no photography-heavy hero treatments. Occasional very soft radial teal-to-transparent wash behind onboarding/empty-state illustration slots only — otherwise flat `--color-bg` / `--color-surface`. No full-bleed imagery in-product; this isn't a marketing surface.
- **Animation:** minimal and functional — 120–200ms ease-out fades/slides (`--duration-fast`/`--duration-normal`, `--ease-out`) on sheet/modal open, tab switches, toast entry. No bounce/spring on system chrome (reserve `--ease-spring` only for a rare celebratory milestone moment). No looping/ambient animation — this is a tool used under stress; motion should never feel busy.
- **Hover states:** background steps one shade darker (`--color-primary-hover`) for filled buttons; ghost/text buttons gain a soft tinted background (`--color-primary-soft`). No opacity-fade hovers — they read washed-out on a warm-neutral background.
- **Press/active states:** one shade darker still (`--color-primary-active`) plus a 1px scale-down (`transform: scale(0.98)`) at `--duration-fast`. No color-shift-only presses on primary actions — the scale gives tactile confirmation for a "log this" action people do many times a day.
- **Borders:** 1px, `--color-border` (very light warm gray) on cards and inputs; `--color-border-strong` for dividers that need to read. No colored borders as a decoration technique.
- **Shadows:** soft and shallow (`--shadow-sm`/`--shadow-md`) — cards lift barely off the background; nothing floats dramatically. Modals/sheets use `--shadow-lg`. No inner glows, no colored shadows.
- **Radii:** rounded but not pill-happy — cards `20px`, buttons/inputs `14px`, small chips/badges `999px` (pill). Consistent throughout; no mixed sharp/rounded within one screen.
- **Cards:** white surface, `--radius-card` (20px), `--shadow-sm`, 1px `--color-border`. No colored left-border accent strip (explicitly avoided per brand guidance) — status is communicated with a small icon + label, not a border color.
- **Transparency/blur:** used only for the bottom sheet / modal scrim (`rgba(28,33,31,0.4)`) and a subtle `--blur-glass` on the sticky bottom tab bar so content is visible scrolling underneath. Not used decoratively.
- **Imagery:** none provided. Where an illustration/photo would go (onboarding, empty states), use a neutral placeholder — warm tone, no imagery invented. Flagged inline in the UI kit.
- **Layout rules:** mobile app is a fixed 390px-wide frame with a persistent bottom tab bar (Home / Log / Insights / Profile) and a sticky top header carrying the screen title + a contextual primary action.

## Iconography
No icon assets or icon font were provided. **Substitution:** [Lucide](https://lucide.dev) icons (CDN, `lucide-static` SVGs), stroke-based, 1.5–2px stroke weight to match the app's precise-but-friendly linework — flagged here as a substitution, not a brand original. Icons are referenced via the `Icon` component (`components/core/Icon.jsx`), which loads a named Lucide SVG and recolors it with `currentColor` via CSS mask so it always matches surrounding text/icon color tokens. No emoji, no unicode glyphs-as-icons anywhere in the product. If the real team has a brand icon set, drop the SVGs into `assets/icons/` and point `Icon.jsx` at them — same call signature.

## Caveats — please help iterate
- **No logo was provided.** Every place a mark would go uses the wordmark "J-Pouch" in `--font-display`. If you have a real logo, attach it and I'll wire it in everywhere.
- **No codebase or Figma was attached**, so every color, spacing value, and component shape here is a from-scratch proposal based on the brief + tone answers — not derived from an existing product. Treat this as v1 to react to, not ground truth.
- **Icons are a CDN substitution** (Lucide), not a brand-original set.
- Only one surface (mobile app) was in scope per your answers — say the word if you also want a marketing site, a clinician-facing view, or a community/forum surface.
