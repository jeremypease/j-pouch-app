# J-Pouch — Product Requirements Document

*App name finalized: home screen / in-app name is "J-Pouch"; App Store listing title is "J-Pouch: Your Companion". iOS app, native SwiftUI recommended for HealthKit access and solo/no-code buildability (Xcode + SwiftUI is closer to no-code than a cross-platform stack for a single builder).*

## Problem Statement

People who undergo j-pouch (ileoanal pouch) surgery go through a distinct, multi-year medical journey — staged surgery, an unpredictable adaptation period, lifelong risk of pouchitis, and permanent changes to diet, hydration needs, and bathroom habits. No app on the App Store is built for this journey specifically. Patients currently use generic IBD trackers (Flarely, mySymptoms, Bearable, CareClinic) or general food-logging apps (MyFitnessPal) that don't understand pouch-specific realities like output adaptation, dehydration risk, or post-takedown food reintroduction — patients on the j-pouch.org forum are actively asking for this and being told to make do with mismatched tools. The cost of the gap: patients can't easily spot dehydration or pouchitis patterns early, GI visits run on vague recall instead of data, and there's no single place that adapts its guidance to *which stage* of the journey someone is in.

## Goals

- Give j-pouch patients a single app that adapts its tracking and guidance to their current surgical/recovery stage, rather than treating them as generic IBD patients.
- Reduce dehydration-related complications by making hydration and output tracking fast enough to actually use on bad days (under 30 seconds to log).
- Give patients something concrete to bring to GI appointments — a real trend report instead of memory.
- Build sustainable revenue via subscription (no ads) — target a modest but real paying base within a small, underserved patient population (roughly 100,000–150,000 people living with a j-pouch in the US).
- Ship a usable v1 within ~3 months as a solo/light-dev build.

## Non-Goals (v1)

- **Apple Watch app** — explicitly deferred; revisit once the iPhone app has real usage data on what's worth glancing at on-wrist.
- **Clinician-facing portal or EHR integration** — v1 exports a shareable report; it does not push data into any provider's system. Too much scope/compliance overhead for a solo build.
- **Real-time API integration with j-pouch.org** — the forum has no public API; anything here is a content/education partnership, not a live data feed (see Open Questions).
- **Android** — iOS only for v1; revisit if traction supports the dev cost of a second platform.
- **Diagnosing or replacing medical advice** — the app tracks and surfaces patterns; it explicitly does not tell users what a symptom means medically. Framed throughout as "bring this to your GI," never as a diagnosis.

## User Stories

**Pre-op / newly diagnosed**
- As a person scheduled for j-pouch surgery, I want a plain-language stage-by-stage overview of what's coming so I know what to expect at each surgery and in between.
- As a pre-op patient, I want to set my surgery dates so the app can adapt what it asks me to track once I've had surgery.

**Adaptation phase (post-takedown, first ~6–12 months)**
- As a patient in the adaptation phase, I want to log an output (frequency, consistency, urgency, blood, time of day) in under 30 seconds so I'll actually keep doing it on bad days.
- As a patient in the adaptation phase, I want the app to flag when my output count or hydration looks like it's trending toward dehydration so I know to act before it becomes an ER visit.
- As a patient reintroducing foods after takedown, I want to log what I ate and see it lined up against my output/symptom data over the following 12–72 hours so I can spot trigger foods.
- As a patient with night leakage, I want a quick way to log nighttime episodes separately from daytime ones so I can see if it's improving.

**Long-term maintenance (years out)**
- As a long-term j-pouch patient, I want the app to notice patterns that look like pouchitis (sudden frequency increase, urgency, blood, fever) so I know when to call my GI rather than waiting it out.
- As a patient on antibiotics for pouchitis, I want to log my course and symptom response so I can tell my GI whether it's working.
- As a long-term patient, I want Kegel/pelvic floor exercise reminders since continence tends to improve with consistent practice.
- As a patient prepping for a GI appointment, I want to generate a clean summary of the last 30/90 days so I don't have to reconstruct it from memory in the waiting room.

**All stages**
- As any j-pouch patient, I want my hydration and weight data to sync with Apple Health so I don't have to double-enter it, and so the app can catch dehydration trends using data I'm already tracking elsewhere.
- As a new user, I want to tell the app what stage I'm in (or set my surgery date) so it only asks me about things relevant to me right now.

## Requirements

### Must-Have (P0)

**Stage-aware onboarding & timeline**
- User sets surgery date(s) or selects current stage (pre-op / staged surgery in progress / adaptation / long-term maintenance).
- App's default tracking prompts and home screen adapt to stage (e.g., adaptation-phase users see hydration prominently; long-term users see pouchitis pattern status).
- Acceptance: given a user in "adaptation" stage, when they open the app, then hydration and output logging are the primary actions — not buried in a menu.

**Fast output/symptom logging**
- Single-screen log: time, consistency (Bristol-style scale adapted for pouch output), urgency (yes/no + severity), blood (none/streaks/significant), pain (0–5), day or night.
- Must complete in under 30 seconds / 4 taps for a basic entry.
- Acceptance: a user can log a basic entry (no notes) in 4 taps or fewer.

**Hydration tracking with HealthKit sync**
- Log water/fluid intake and electrolyte drink use.
- Read/write to HealthKit's dietary water and body mass records so data is shared with other health apps and survives an app reinstall.
- Simple daily hydration target with a visual (not alarmist) indicator of where the user stands.
- Acceptance: given a user logs water intake in the app, when they open Apple Health, then the entry appears under Dietary Water.

**Dehydration risk flag**
- Rule-based (not ML for v1) flag combining output frequency + hydration logged + optional HealthKit weight trend (sudden drop can indicate fluid loss).
- Plain-language "this looks like it's trending toward dehydration — consider electrolytes or calling your care team" message, never a diagnosis.
- Acceptance: given 3+ days of output count above the user's baseline with hydration below target, when the pattern holds, then the app surfaces a flag on the home screen.

**Pouchitis/flare pattern detection**
- Tracks the standard pouchitis symptom cluster (increased frequency, urgency, blood, cramping, fever/malaise if logged) against the user's personal baseline.
- Surfaces a "this looks different from your normal pattern" flag, framed as a prompt to contact their GI — not a diagnosis.
- Acceptance: given a user's output frequency spikes 50%+ above their 30-day rolling baseline with blood present, when this holds for 2+ days, then a flare flag appears.

**Food reintroduction log (adaptation phase)**
- Log meals/foods (text entry or photo, no AI analysis required for v1) and see them on the same timeline as symptom entries with a 12–72 hour lookback window highlighted.
- Acceptance: given a food logged on day 1, when the user views day 2–3 symptom entries, then the app visually links back to that food entry.

**Medication & antibiotic course tracking**
- Log medications, dosage, and schedule; flag antibiotic courses specifically (start/end date) so symptom response can be viewed against the course.
- Acceptance: given an active antibiotic course, when the user views their symptom trend, then the course start date is marked on the timeline.

**GI-visit report export**
- Generate a clean PDF/shareable summary (30 or 90 day window): output trend, hydration trend, flags raised, medications, notable food correlations.
- Acceptance: given 30 days of data, when the user taps "Generate report," then a PDF is created and shareable via the standard iOS share sheet.

**Free tier**
- All core logging (output, hydration, food, meds) and the stage-aware home screen are free, unlimited.

### Nice-to-Have (P1)

- Kegel/pelvic floor exercise reminders and a simple guided routine (text/timer based, not video).
- Pre-op and staged-surgery educational content, written plainly, organized by stage.
- Multi-stage timeline view showing the user's whole journey to date, not just current stage.
- Caregiver/family shared view (read-only) for a spouse or parent helping track, gated to paid tier.
- In-app curated links to j-pouch.org educational pages (dietary guidelines, Kegel exercises, illustrated pouch diagrams) and relevant forum categories — pending partnership/permission (see Open Questions).
- AI-assisted trigger-food suggestions (paid tier), once there's enough logged data to make this more than a coin flip.

### Future Considerations (P2)

- Apple Watch complication for quick logging and hydration reminders.
- Deeper j-pouch.org integration if a data-sharing or content-licensing partnership is arranged (e.g., surfacing relevant forum threads based on a user's current symptom pattern).
- Clinician-facing report delivery (secure link a GI office can view directly).
- Android version.
- Community/peer-support features built natively in the app, if a licensing arrangement with j-pouch.org doesn't pan out.

## Success Metrics

**Leading indicators**
- Day-7 retention of new users who complete onboarding (target: 40%+ — chronic-condition trackers typically retain worse than this without a strong "why keep opening it," so this is the number to watch first).
- % of logged entries completed in under 30 seconds (target: 80%+) — validates the speed requirement is actually met, not just designed for.
- Free-to-paid conversion rate at 30 days (target: 3–5%, in line with niche health-app freemium benchmarks).

**Lagging indicators**
- % of active users who generate at least one GI report export within 90 days (proxy for "this changed how they engage with their care").
- Subscription retention at 3 months (target: 60%+ of subscribers still active).
- Qualitative: forum/App Store review mentions of catching a flare or dehydration episode earlier than they would have otherwise.

*Measurement: App Store Connect analytics + in-app event logging for the tracking-speed metric. Evaluate at 30 days (leading) and 90 days (lagging) post-launch.*

## Open Questions

- **(Stakeholder — Jeremy)** Is a formal partnership or even informal permission from j-pouch.org worth pursuing before launch, or should v1 ship without any tie-in and revisit once there's traction to make the ask credible? Their forum has no public API, so any integration is a content/linking arrangement, not a technical one.
- **(Legal)** What's the right framing/disclaimer for the pouchitis and dehydration "flags" so they clearly read as pattern-noticing, not medical advice? Worth a plain-English review before launch given the health-data sensitivity.
- **(Design/Engineering)** Bristol stool scale is designed for solid stool — j-pouch output is often looser by nature. Does the logging scale need a pouch-specific adaptation, and is there existing clinical literature (e.g., from ostomy.org or Cleveland Clinic pouch programs) to base it on rather than inventing one from scratch?
- **(Engineering)** Confirm HealthKit's dietary water and body mass record types are sufficient, or whether a custom correlation needs data stored app-side (HealthKit has no native "bowel output" record type, so symptom logs will live in the app's own store regardless).
- **(Stakeholder)** Is $4.99–$6.99/month in line with what this audience will pay, or does the smaller, more medically-anxious patient base support a different price point than the general IBD-tracker comps (Flarely, Tract) suggest?

## Timeline Considerations

You asked for the full journey (pre-op through long-term maintenance) as the v1 scope, on a ~3-month solo timeline. That's an aggressive combination — full-journey breadth *and* a 3-month solo build usually trade against each other. Recommended phasing to hit both without cutting the vision:

- **Phase 1 (Months 1–3, ship this):** Everything in Must-Have (P0) above, which already spans all three stages at a lighter depth — stage-aware onboarding, fast logging, hydration/HealthKit sync, dehydration and pouchitis flags, food reintroduction log, medication tracking, GI report export. This is a real full-journey app; it's just not maximally deep in any one stage yet.
- **Phase 2 (Months 4–6):** Nice-to-Have (P1) — Kegel routine, pre-op education content, caregiver view, j-pouch.org content links if a partnership comes together.
- **Phase 3 (later):** Future Considerations (P2) — Watch app, AI trigger detection, deeper partnership integration, Android.

No hard external deadlines identified. The main dependency to flag early: if you want j-pouch.org involved at all (even just linking to their content), start that conversation now — community/nonprofit partnerships tend to move slower than a solo dev's 3-month build clock.
