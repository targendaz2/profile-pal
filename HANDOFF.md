# ProfileManifestsKit — Handoff

## What this is

A Swift 6 / macOS 14+ embeddable framework that renders **ProfileManifests**
(https://github.com/ProfileManifests/ProfileManifests) as runtime SwiftUI forms
and exports `.mobileconfig` configuration profiles.

Manifests are `.plist` files describing the structure of *another* plist (a
config profile). They're the format powering ProfileCreator and iMazing Profile
Editor. This framework parses them, renders an editing form, and serializes the
user's input back out as a profile.

**Design line:** the framework owns *everything about manifests* — decode,
value model, conditions, control resolution, rendering, export. A thin host app
(manifest picker, window chrome, file I/O) comes last and is out of scope until
step 10. If you find yourself writing app-policy code (where files live, window
management), it belongs in the app, not here.

**Authoritative spec:** the ProfileManifests wiki "Manifest Format" page. Fetch
it directly when you need a `pfm_*` key's exact semantics — prefer it over any
paraphrase in this doc.

## Conventions

- Swift 6 language mode, strict concurrency **on** (`swiftLanguageModes: [.v6]`).
- `FormModel` is `@MainActor`; every other type is `Sendable`.
- Public surface stays **minimal**: `ManifestForm` view, a manifest-loader
  protocol, an exported-profile accessor, and the handful of model types a
  consumer inspects. Everything else is `internal`. Keeping this narrow is
  deliberate — it preserves freedom to refactor internals and to later split a
  headless `ManifestCore` target out.
- Tests use **Swift Testing** (`@Test` / `#expect`), not XCTest.
- UI restraint: native macOS controls, System-Settings look, no decoration.
- No fetching at test time — tests run offline. Build plist fixtures in code
  with `PlistFixture` (see below).

## Build plan (10 steps)

1. Scaffold ✅
2. `PFMValue` — type-erased plist scalar ✅
3. Manifest model (`PayloadManifest`, `ManifestSubkey`) ✅
4. Form model (`FormModel`, `FormPath`, bindings) ✅
5. Condition evaluator (visibility + requirement) ✅
6. **Control resolution — NEXT (after the detour below)**
7. SwiftUI renderer
8. Public API (`ManifestForm`)
9. Export to `.mobileconfig`
10. Packaging + sample app

## Done and tested (headless), steps 1–5

**`PFMValue`** — enum over the plist scalar types (`string`, `integer`, `real`,
`boolean`, `date`, `data`) plus `indirect` `array` / `dictionary`. `Sendable`,
`Hashable`. Hand-written `Decodable` that **probes `Bool` before `Int`** (a plist
`<true/>` also decodes as `Int 1`). Note: `PropertyListDecoder` coerces an
integral-valued `<real>` (e.g. `5.0`) to `.integer` — the int/real distinction
can't be recovered at decode time, so it's restored later via `normalized(to:)`
driven by the subkey's declared `pfm_type`. Has `asDouble`, `displayString`,
`plistValue` (→ Foundation `Any`, for fixtures) accessors.

**`PayloadManifest` / `ManifestSubkey`** — decode the `pfm_*` keys via explicit
`CodingKeys`. Everything optional **except** `domain`, `title`, `type`,
`subkeys`. Critical: `pfm_name` is **optional** — array-element subkeys are
positional and have none. `pfm_required` (Bool) and `pfm_require` (String enum:
`always`/`always-nested`/`push`) are **two separate keys**, both decoded, not
merged at decode time. `pfm_default` / `pfm_value_placeholder` are `PFMValue?`.
Unknown `pfm_*` keys are silently ignored (only ~40 of ~60 keys modeled; add
more as real manifests demand). `PFMType` has a **case-insensitive** decoder
(manifests are inconsistent about capitalization).

**`FormModel`** — `@Observable @MainActor`. Owns `root: PFMValue` (the value
tree), `errors: [FormPath: [String]]`, and the manifest. `FormPath` addresses
into the tree with `.key(String)` / `.index(Int)` components. Seeds defaults on
init via `normalized(to:)`, seeding **only keys that have a `pfm_default`** —
absent ≠ empty is a real distinction the format cares about. `setValue` uses an
**immutable recursive spine-rebuild** (reassigns `root` so `@Observable` sees
it; never mutates a nested box in place). Setting `nil` **removes** the key.
Vends typed bindings: `stringBinding` (empty string clears), `boolBinding`
(honors `pfm_value_inverted`), `doubleBinding` (bridges int/real via `asDouble`).

**Condition evaluator** — `isVisible(_:)` and `isRequired(_:)` on `FormModel`.
Both `pfm_exclude` and `pfm_conditionals` wrap an array of `pfm_target_conditions`.
Combining: **conditions within one entry AND**, **entries in the outer array OR**.
Operators: `pfm_present`, `pfm_value_empty`, `pfm_range_list` (equals-any),
`pfm_n_range_list` (not-equals-any), `pfm_contains_any`, `pfm_n_contains_any`,
`pfm_platforms`. **Absence polarity matters**: an absent target is `false` for
`range_list` but `true` for `n_range_list` — getting this backwards inverts
visibility on fresh forms. `pfm_conditionals` with **no `pfm_require` is a
no-op**. Cross-payload targeting (`pfm_domain` inside a condition) is **not yet
supported** — returns nil/unresolvable, documented as a single-payload
limitation (needs a future workspace model holding multiple payloads' trees).
`validate()` populates `errors` for visible-and-required-but-empty keys only.

**`PlistFixture`** — a test-only generator building plist `Data` from Swift value
trees (`manifest(...)`, `key(...)`, `conditional(...)`, `exclusion(...)`,
`condition(target:_:)`). Use it instead of hand-writing XML — hand-written plist
strings caused a `Code=3840` malformed-XML failure earlier; this removes the
human from XML generation entirely.

### Known real-manifest quirks hit in step 3

> **David — fill this in from your notes.** Which fields you had to make
> optional beyond the sketch, any `pfm_type` casing you saw, and — importantly —
> whether `pfm_segments` actually matched the `[String: [String]]` shape I
> guessed (title → keypath-array). That last one is unverified and step 6
> depends on it. If you didn't keep notes, re-decode your step-3 fixture and
> jot what threw.

## The detour (do this FIRST, before step 6)

Six steps of pure logic, nothing seen on screen yet. Before the full renderer,
build **one throwaway SwiftUI preview rendering a single hard-coded control** —
a `TextField` bound to a `FormModel` value at a fixed path is enough. Goal: prove
the SwiftPM package actually compiles a view and renders in the Xcode preview
canvas / a tiny sample `App`. This de-risks "does any of this display" while the
resolver is still fresh, and surfaces any package-config problems (missing
platform, SwiftUI import, `@Observable` observation not firing) in isolation
rather than tangled up with step-7 complexity. Delete it after, or fold it into
the step-7 previews.

## Step 6 — Control resolution (the target)

A **pure function** `control(for: ManifestSubkey) -> Control` that decides *how*
a visible key renders. No SwiftUI — this returns an enum; step 7's renderer is a
boring switch over it. Unit-test it directly: subkey in, `Control` case out.

### The `Control` enum (sketch — refine associated values as step 7 needs)

```swift
enum Control: Equatable {
    case textField(secure: Bool)
    case toggle(inverted: Bool)
    case radioTwoState(titles: [String])        // boolean with exactly 2 range_list_titles
    case popUp(values: [PFMValue], titles: [String], allowsCustom: Bool)
    case slider(min: Double, max: Double)
    case stepper(min: Double?, max: Double?)
    case datePicker(style: String?)
    case fileDrop(types: [String])              // pfm_type == data
    case arrayTable(element: ManifestSubkey)
    case dictionary(subkeys: [ManifestSubkey])
    case segmented([String: [String]])
    case unsupported                            // explicit fallback; don't crash
}
```

### Decision order (ORDER IS LOAD-BEARING)

Resolve `let type = key.typeInput ?? key.type` first, then check in this order —
enumerated/explicit-hint controls must win **before** type-based defaults, or an
enumerated string renders as a plain text box:

1. `pfm_segments` present → `.segmented`
2. `pfm_range_list` present → `.popUp` (titles from `pfm_range_list_titles`,
   falling back to each value's `displayString`; `allowsCustom` from
   `pfm_range_list_allow_custom_value`)
3. else switch on `type`:
   - `.boolean` → if `pfm_range_list_titles` has exactly 2 entries,
     `.radioTwoState`; else `.toggle(inverted: pfm_value_inverted)`
   - `.string`, `.url` → `.textField(secure: pfm_sensitive)`
   - `.integer`, `.real` → if `pfm_view == "slider"` and both `range_min`/`range_max`
     present, `.slider`; else if either range bound present, `.stepper`; else
     `.textField(secure: false)`
   - `.date` → `.datePicker(style: pfm_date_style)`
   - `.data` → `.fileDrop(types: pfm_allowed_file_types ?? [])`
   - `.array` → `.arrayTable(element: subkeys.first ?? key)`
   - `.dictionary` → `.dictionary(subkeys: subkeys ?? [])`

Never trap on an unrecognized combination — return `.unsupported` so an
unexpected manifest degrades gracefully instead of crashing the form.

### Tests to write (headless)

- Each `type` with no hints → its default control.
- `range_list` on a string → `.popUp`, **not** `.textField` (the ordering trap).
- `range_list` **without** `range_list_titles` → titles fall back to
  `displayString` of each value.
- boolean + exactly 2 titles → `.radioTwoState`; boolean + 0 titles → `.toggle`.
- `pfm_value_inverted` surfaces in the `.toggle` associated value.
- integer + `pfm_view: slider` + both bounds → `.slider`; integer + one bound →
  `.stepper`; integer + no bounds → `.textField`.
- `typeInput` overrides `type` (e.g. stored `string`, input `integer`).
- `pfm_sensitive` string → `.textField(secure: true)`.
- Unknown/empty combination → `.unsupported`, no trap.

## Working relationship

- **Design questions → back to the chat with Claude (Opus).** Architecture, why
  a rule exists, edge-case reasoning, modeling forks (e.g. should array-of-dict
  be a table or a repeated sub-form — that's a real step-7 fork). Resolve the
  shape there, implement it here.
- **Claude Code (you) → make it compile, test, and render.** Run `swift build` /
  `swift test`, iterate against real compiler errors, render previews.

## Guardrails / gotchas

- Bool-before-Int in any plist decode path.
- Immutable spine-rebuild in `FormModel.set` — never in-place mutation, or
  `@Observable` misses the change and the UI won't refresh.
- Absent-vs-empty: clearing a field removes the key; don't store `.string("")`.
- Absence polarity in conditions (see evaluator note).
- `.copy` (not `.process`) for any real `.plist` test resource — don't let
  Xcode's plist optimizer rewrite fixtures and mask a decode bug.
- Export (step 9) is where correctness actually bites — an MDM rejects a
  malformed profile. Drop excluded keys, flip inverted booleans, write defaults
  only where appropriate, wrap in the `PayloadContent`/`PayloadType`/`PayloadUUID`
  envelope. Give it the same test rigor as the evaluator.

## For CLAUDE.md (merge into the existing file — do not overwrite)

There is already a `CLAUDE.md` in this repo that David started. **Merge** the
rules below into it: keep everything already there, add what's missing, and if
anything conflicts, surface the conflict to David rather than silently
resolving it. Don't duplicate a rule that's already present in different words —
consolidate. Keep `CLAUDE.md` tight; it's read every turn, so it holds durable
constraints only, not the build narrative (that lives here in HANDOFF.md).

Rules to ensure are present:

### Environment
- Swift 6 language mode, strict concurrency on. macOS 14+ only.
- `FormModel` is `@MainActor`; all other types must be `Sendable`.
- Build/test with SwiftPM: `swift build`, `swift test`. Tests use Swift Testing
  (`@Test`/`#expect`), never XCTest.

### Non-negotiable correctness rules
- **Plist decoding probes `Bool` before `Int`** — a `<true/>` also decodes as
  `Int 1`. Reversing this silently turns every boolean into an integer.
- **`FormModel` value writes rebuild the tree immutably** (reassign `root`);
  never mutate a nested value in place, or `@Observable` misses the change.
- **Absent ≠ empty.** Clearing a field removes its key from the tree; never
  store `.string("")` as a stand-in for "unset."
- **Condition absence polarity:** an absent target is `false` for `range_list`
  (equals-any) and `true` for `n_range_list` (not-equals-any). Preserve this.
- **`pfm_conditionals` with no `pfm_require` is a no-op.**
- **Control resolution order is load-bearing:** `segments` then `range_list`
  win before any type-based default. Never trap on an unknown combination —
  return `.unsupported`.

### Model conventions
- Manifest fields are optional except `domain`, `title`, `type`, `subkeys`.
  `pfm_name` is optional (array-element subkeys have none). When a real manifest
  throws on a non-optional field, make it optional — don't force it.
- `pfm_required` (Bool) and `pfm_require` (String enum) are separate keys, both
  decoded, resolved only in the evaluator.
- Unknown `pfm_*` keys are silently ignored by design; add fields only as real
  manifests require them.

### API surface
- Keep `public` minimal: `ManifestForm`, the loader protocol, the
  exported-profile accessor, and model types a consumer inspects. Default new
  types to `internal`.

### Testing
- No network at test time. Build plist fixtures in code with `PlistFixture`,
  never hand-written XML strings.
- Use `.copy` (not `.process`) for any real `.plist` test resource.

### Working relationship
- Design/architecture/edge-case questions are resolved with David in the Claude
  chat, then implemented here. When you hit a modeling fork this doc doesn't
  settle, flag it for that conversation rather than picking a direction silently.

### Spec authority
- The ProfileManifests wiki "Manifest Format" page is authoritative for `pfm_*`
  semantics. Fetch it directly when unsure; prefer it over paraphrases in
  HANDOFF.md.
