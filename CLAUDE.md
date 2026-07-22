# J-Pouch — project context

This is the working folder for the J-Pouch iOS app. See `jpouch-app-prd.md` in this same folder for the full product requirements document (problem statement, goals, user stories, P0/P1/P2 requirements, success metrics, timeline).

## Naming (finalized)

- **Home screen / in-app name:** `J-Pouch`
- **App Store Connect listing title:** `J-Pouch: Your Companion`
- Use "J-Pouch" everywhere in code, UI strings, bundle display name, and asset names. Reserve the longer "J-Pouch: Your Companion" for the App Store Connect title field only.

## Key product decisions

- Native SwiftUI, iOS only for v1 (no Android, no Apple Watch app — deferred to P2).
- Solo/light-dev build, ~3 month target for v1 (P0 scope only — see PRD Timeline Considerations).
- Freemium via subscription, not ads. Free tier = all core logging (output, hydration, food, meds). Paid tier gates caregiver view and future AI trigger-food suggestions.
- HealthKit integration (dietary water, body mass) is in P0 scope.
- No diagnosis language anywhere — dehydration/pouchitis pattern flags are framed as "bring this to your GI," never a medical determination.
- j-pouch.org has no public API; any tie-in is a content/linking partnership, not a data integration (open question, not yet resolved).

## Working style

Jeremy prefers concise, direct communication with minimal unnecessary explanation.
