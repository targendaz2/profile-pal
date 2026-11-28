# Plan: a format-neutral schema layer in ProfilePal

## Status

| PR | State |
| --- | --- |
| 1: `pfm_platforms` on conditions | Merged as #9 on 2026-11-22. |
| 2: VersionKit | Merged as #10 on 2026-11-22. |
| 3a: Schema types and field conversion | **Next.** Not started. Branch `feat/payload-schema` from `main`. |
| 3b: Condition resolution | Not started. Branch `feat/schema-conditions` from `main` once 3a merges. |

## Open follow-ups

These are outside PR 3a's and 3b's scope. Pick them up separately, or fold them in where noted.

- **Check that the automated code review now reviews.** On #9, #10, and #12 the review workflow reported success without reviewing anything. #13 found the causes: the plugin's first subagent started in the background and the headless run ended before it ran, and `--allowedTools` blocked the subagents' `gh` calls. #14 then rewrote `code-review.yml` from the plugin's standard setup, keeping `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS: "1"` and allowing `gh pr diff`, `gh pr view`, and `gh pr comment`. It also dropped the **Summarize review tool use** step and the draft-PR check. No Swift PR has run under the rewritten workflow yet, so PR 3a is the first real test. Open it and check that the review posts inline comments or a summary, rather than passing silently. With no summary step, the run's log in the Actions tab is the only other evidence. If it fails again, fix the workflow in its own PR: the action skips any PR whose copy of the workflow differs from `main`.
- **`CLAUDE.md` still says the review runs on "a non-draft PR"** that touches Swift, pbxproj, plist, or entitlements files. Since #14, it also runs on drafts and on `CLAUDE.md`, `README.md`, `docs/**/*.md`, and `Package.resolved`. Fold the fix into PR 3a's `CLAUDE.md` changes.

## Context

`ProfileManifestKit` mirrors the ProfileManifests spec exactly: about 40 flat optionals per field, `require` and `required` side by side, nine OS-version keys, and parallel `rangeList`/`rangeListTitles` arrays. That's correct for the kit, whose job is implementing the spec. It's awkward for the app, which in v1 will render an editing form, validate values, evaluate conditions live, and write profiles.

This work adds a **cleaner, format-neutral layer in the ProfilePal app target**, so the app never touches `Manifest*` types directly. Other manifest formats can later convert into the same layer. All normalization ("fix-up" logic the spec rule forbids in the kit) lives here.

Survey basis: all 288 manifests at ProfileManifests `0d01e64`.

## Decisions

| Topic | Decision |
| --- | --- |
| Placement | `ProfilePal/Schema/`, tested in the new `ProfilePalTests` target |
| Names | `PayloadSchema`, `SchemaField`, … |
| Values | Typed per kind (a `String` default for string fields, and so on). `coerced(to:)` runs once, inside the converter. |
| Bad input | Conversion never throws. Bad pieces are dropped and recorded as `SchemaDiagnostic`s. |
| Condition targets | Nearest scope outward for both bare names and dotted paths (the spec documents `.` paths). Stored as a relative reference, so each array item is evaluated against its own values. A target that's missing, or matches more than one field at the same level, gets a diagnostic. |
| Environment conditions | Model the documented `pfm_platforms` in the kit first, in a separate PR. `pfm_n_platforms` (inferred) and `pfm_distribution` (undocumented) stay unmodeled, so those conditions become diagnostics. |
| Cross-payload conditions (`pfm_domain`) | Deferred. They show up as unresolved-target diagnostics. |
| Platforms | A closed enum: iOS, iPadOS, macOS, Mac Catalyst, tvOS, visionOS, watchOS. An unknown string gets a diagnostic. ProfileManifestKit keeps platforms as strings and adds no keys for the new platforms, since the spec has no version keys for them and no manifest uses them. |
| Versions | A new **VersionKit** framework in this project, used by the ProfilePal app only. ProfileManifestKit keeps raw strings, as the spec types them. `Version` parses any number of numeric parts and keeps the original string for display. Wildcards and annotations (29 values, such as `15.x` and `16.27 ONLY`) get a diagnostic, and empty strings (14) are treated as absent. |
| `require` vs `required` | Strictest wins (`alwaysNested` > `always` > `mdmOnly`), with a diagnostic when they disagree. |

## PR 1: `pfm_platforms` on conditions (ProfileManifestKit), branch `feat/condition-platforms`

What shipped in #9:
- `ManifestTargetCondition` has `platforms: [String]?` (`pfm_platforms`), typed to match `Manifest.platforms`. Because it's an extended key, the type now has both `// MARK:` sections. `target`'s doc comment mentions dotted paths and platform-only conditions.
- `pfm_platforms` was added to the existing `target-condition-all-keys.plist` fixture, rather than a new fixture, so `project.pbxproj` stayed out of the PR. `targetConditionAllKeys` checks it.
- The property-order rule's example of a type with only Apple-defined keys is now `ManifestConditionalRule`.
- `docs/decisions.md` logs the change. `docs/outstanding-questions.md` narrows the environment-conditions question to `pfm_n_platforms` (1 condition) and `pfm_distribution` (3).
- The review workflow (now `code-review.yml`) gains a **Summarize review tool use** step. It logs tool names, permission denials, and models from the action's execution file, because the first review of #9 posted "No issues found" without running its agents.

A test for a platform-only condition (`pfm_platforms` and no `pfm_target`, the shape real Apple manifests use) followed separately, on branch `test/platform-only-condition`, with the `target-condition-platforms-only.plist` fixture.

## PR 2: VersionKit, branch `feat/version-kit` (independent of PR 1)

Shipped in #10 as planned below. Two things differ from the plan:
- `VersionKitTests` doesn't run inside the app: it has no `TEST_HOST` and no dependency on the app, matching `ProfileManifestKitTests`. While it was hosted, Xcode wouldn't add it to the `VersionKit` scheme.
- #10 also changed the review workflow: it flags errored tool calls, installs the plugin from `claude-plugins-official`, and renames the workflow to `code-review.yml` (see Open follow-ups).

**Prerequisite (created by the project owner in Xcode):**
- a `VersionKit` framework target, embedded in ProfilePal
- a `VersionKitTests` target using Swift Testing
- a shared `VersionKit` scheme that runs `VersionKitTests`, like `ProfileManifestKit`'s

**The type,** in `VersionKit/Version.swift`: `public struct Version: Sendable, Hashable, Comparable, LosslessStringConvertible`.
- `public let components: [Int]` holds the numeric parts.
- `public let original: String` holds the exact parsed string. `description` returns it, so `10.15` shows as `10.15`.
- `public init?(_ string: String)` splits on `.`. Every part must be non-empty digits; leading zeros are allowed and parse as integers. Anything else returns `nil`.
- `public init(_ components: Int...)` builds a version directly, for tests and constants.
- `==`, `hash`, and `<` compare the parts with trailing zeros ignored, so `10.15 == 10.15.0` and `2024.1.160.0 > 2024.1.16`.

**Tests** in `VersionKitTests`: parsing (1 to 4 parts, leading zeros, and rejecting `""`, `15.x`, `16.27 ONLY`, `4.31y`, `1..2`, and `v1.2`), keeping the original string, and equality, hashing, and ordering across part counts. These test strings, not plists, so there are no fixtures.

**Also in this PR:** the `ProfilePalTests` target (with its placeholder test), since its project changes can't be split from VersionKit's; VersionKit's tests in `tests.yml`; and removing the distribution-only build settings (library evolution, module verifier) that Xcode's framework template turns on, as was done for ProfileManifestKit.

**Docs:**
- `CLAUDE.md`: add VersionKit to the targets and schemes list. Extend the `paths:` of `testing-unit-test-style.md` to `VersionKitTests/**`. Add `VersionKitTests` to the swift-format commands.
- `docs/decisions.md`: log the version formats accepted, with the audit numbers.

## PR 3: the schema layer (ProfilePal), in two PRs

The design below covers the whole layer. It ships as two PRs, split at the converter's second pass, since condition resolution is the most involved part and has its own tests and survey numbers.

### PR 3a: schema types and field conversion, branch `feat/payload-schema`

- **Types:** everything below except `Condition.swift`. `SchemaField` has no `exclusions` yet, and `Requirement` has `level` only, without `conditional`. Both are added in 3b, so no condition type exists before it can be filled in.
- **Converter:** `ManifestSchemaConverter.swift` with pass 1 only (`+Fields`, `+Availability`). `pfm_conditionals` and `pfm_exclude` aren't read yet. Nothing in the app uses the schema before 3b lands, so skipping them isn't a user-visible loss.
- **Diagnostics:** the `SchemaDiagnostic.Kind` cases pass 1 can produce: `valueTypeMismatch`, `choiceTitleCountMismatch`, `unparsableVersion`, `unknownPlatform`, `requirementConflict`, `constraintNotApplicable`, and `invalidPattern`.
- **Tests:** the test setup (fixture helper, Copy Files phases, rule `paths:`), and the `FieldKind`, `Requirement` merging, and `Availability` suites. Also the xCreds and macOSLAPS smoke test, which checks only that they convert, with no condition-related diagnostics.
- **CI:** the `ProfilePal` scheme step in `tests.yml`. The `ProfilePalTests` target came in with #10, so this PR replaces its placeholder test. Its tests run inside the app, so check that `CODE_SIGNING_ALLOWED=NO` still works for them.
- **Docs:** the `CLAUDE.md` schema-layer section and the ProfileManifestKit-only scope of the spec rules. `docs/decisions.md` rows for never throwing and strictest-wins requirement merging.

### PR 3b: condition resolution, branch `feat/schema-conditions`

- **Types:** `Condition.swift`, `SchemaField.exclusions`, and `Requirement.conditional`.
- **Converter:** pass 2 (`+Conditions`): target resolution and coercing test values. It also drops a conditional rule that has no `require`, recording a diagnostic.
- **Diagnostics:** `unresolvedConditionTarget`, `ambiguousConditionTarget`, `unsupportedCondition`, and `missingConditionalRequirement`.
- **Tests:** the condition-resolution suite with its synthetic fixtures, and the `PROFILEMANIFESTS_DIR` survey test. The survey waits for 3b because most of its expected counts are condition diagnostics.
- **Docs:** `docs/decisions.md` rows for nearest-scope target resolution and deferring cross-payload conditions.

### Types (`ProfilePal/Schema/`)

The app target defaults to `MainActor` isolation, so every schema type is a `nonisolated` `Sendable`, `Hashable` value type.

- **`PayloadSchema.swift`**: `domain`, `subdomain`, `title`, `description`, `note`, `icon: Data?`, `appURL: URL?`, `interaction: Interaction?`, `isUnique: Bool?`, `scopes: Set<Scope>`, `availability: Availability`, `fields: [SchemaField]`, `version: Int?`, `lastModified: Date?`. `Interaction` and `Scope` are the schema's own enums, not the kit's.
- **`SchemaField.swift`**: `name: String?` (the payload key; for an array item, its identifier only), `kind: FieldKind`, `presentation: FieldPresentation`, `requirement: Requirement`, `exclusions: [ConditionGroup]`, `availability: Availability`, `scopes: Set<Scope>?` (`nil` means inherited from the payload), `isSensitive: Bool`.
- **`FieldKind.swift`**:
  - `.string(StringField)`: `defaultValue`, `placeholder`, `choices: [Choice<String>]?`, `pattern: String?`
  - `.integer(NumberField<Int>)` and `.real(NumberField<Double>)`: default, placeholder, choices, `range` (min/max)
  - `.boolean(BooleanField)`: default, `isInverted`
  - `.date(DateField)` and `.data(DataField)`: default
  - `.array(ArrayField)`: `item: SchemaField` (boxed, since it's recursive), `count` (min/max)
  - `.dictionary(DictionaryField)`: `fields: [SchemaField]`
  - `Choice<Value>`: `value` and `title`, from zipping `rangeList` with `rangeListTitles`.
- **`FieldPresentation.swift`**: `title` (falls back to `name`), `description`, `note`, `unit`, `documentationURL: URL?`.
- **`Requirement.swift`**: `level: RequirementLevel` (`.optional`, `.always`, `.alwaysNested`, `.mdmOnly`) plus `conditional: [ConditionalRequirement]`, where each has a `level` and a `ConditionGroup`.
- **`Condition.swift`**:
  - `ConditionGroup` is `[Condition]`, and all of them must match.
  - `Condition` is either `.field(FieldReference, [FieldTest])` or `.platforms(Set<Platform>)`.
  - `FieldTest` is one of `.isPresent(Bool)`, `.isOneOf([ScalarValue])`, `.isNoneOf`, `.containsAny`, `.containsNone`. Values are coerced to the target field's kind.
  - `FieldReference` is `levelsUp: Int` plus `path: [String]`, relative to the conditioned field's enclosing scope.
- **`Availability.swift`**:
  - `supportedPlatforms: Set<Platform>?` and `unsupportedPlatforms: Set<Platform>`
  - `versions: [Platform: VersionRange]`, where a `VersionRange` has `introduced`, `deprecated`, and `removed`, each a `VersionKit.Version?`
  - `app: VersionRange?`
  - `requiresSupervision` and `requiresUserApproval`
  - `Platform` is the closed enum.
- **`SchemaDiagnostic.swift`**: a `fieldPath: [String]` and a `kind` enum with associated values:
  - `valueTypeMismatch`
  - `choiceTitleCountMismatch`
  - `unparsableVersion`
  - `unknownPlatform`
  - `unresolvedConditionTarget`
  - `ambiguousConditionTarget`
  - `unsupportedCondition`, covering empty or environment-only keys we don't model
  - `requirementConflict`
  - `missingConditionalRequirement`
  - `constraintNotApplicable`, for example a range on a string or `valueInverted` on a non-boolean
  - `invalidPattern`

  User-facing text comes later, in the UI.

### Converter (`ProfilePal/Schema/ProfileManifests/`)

- **`ManifestSchemaConverter.swift`**: the entry point `static func convert(_ manifest: Manifest) -> SchemaConversion`, where `SchemaConversion` holds `schema` and `diagnostics`. Conversion runs in two passes:
  1. Build the field tree: kinds, typed values, presentation, availability, and requirement levels. Values go through `PlistValue.coerced(to:)` (`ProfileManifestKit/PlistValue.swift`) and then a typed extraction step.
  2. Resolve every condition's `pfm_target` against the finished tree:
     - Split the target on `.`.
     - Starting at the conditioned field's own scope, look for that path at each enclosing level up to the root. Path segments match field names, including array-item names such as `StaticItem`.
     - The first level with exactly one match wins. More than one match at the same level is ambiguous; no match at any level is unresolved.
     - Coerce the test values to the target's kind.
- Split the converter across extension files by concern (`+Fields`, `+Conditions`, `+Availability`) to keep each one readable (`coding-readable-functions.md`).
- Conversion rules:
  - `required: true` merges with `require`, and the strictest wins.
  - `targets == nil` gives `[.user]` at the payload level.
  - An array uses its first subkey as its item; extra subkeys get a diagnostic.
  - A conditional rule whose `require` is `nil` is dropped with a diagnostic.
  - An empty version string is treated as absent.

### Tests (`ProfilePalTests`)

- Copy `FixtureLoading.swift`'s helper.
- Fixtures go in `ProfilePalTests/Fixtures/<Subject>/`, each folder with its own Copy Files phase.
- Extend the `paths:` of `testing-plist-fixtures.md` and `testing-unit-test-style.md` to cover `ProfilePalTests/**`.
- Suites:
  - `FieldKind` conversion, including typed defaults, choices, and the whole-number `<real>` case
  - `Requirement` merging
  - Condition resolution, with synthetic fixtures for: a bare unique name, an array-item sibling (the `wdav` pattern), a dotted root path, a relative dotted path (the `dnsSettings` pattern), an ambiguous name, a missing target, and a platform condition
  - `Availability`, including converting version strings and recording a diagnostic for unparsable ones
  - A real-world smoke test that converts the existing xCreds and macOSLAPS fixtures, copied together with their `THIRD-PARTY-NOTICES.md`
- A survey test over a local ProfileManifests checkout, enabled only when the `PROFILEMANIFESTS_DIR` environment variable is set. It converts every manifest and prints a count of each diagnostic kind. No ProfileManifests files are committed, matching the licensing decision.

### Docs

- `CLAUDE.md`:
  - Add an "Architecture: schema layer (ProfilePal)" section.
  - State the rule that the spec-mirroring and no-fix-up rules apply to `ProfileManifestKit` only, and that normalization belongs in `ProfilePal/Schema/`.
- `docs/decisions.md`: add rows for never throwing and recording diagnostics, nearest-scope target resolution, strictest-wins requirement merging, and cross-payload conditions being deferred.

## Verification

- Build and test with the `xcode` MCP server (`BuildProject`, then `RunAllTests`), using the `ProfileManifestKit` scheme for PR 1, `VersionKit` for PR 2, and `ProfilePal` for PRs 3a and 3b.
- Run the swift-format lint command from `CLAUDE.md`, which covers all six source folders.
- For PR 3b, clone ProfileManifests at `0d01e64` into the scratchpad and run the survey test with `PROFILEMANIFESTS_DIR` set. The expected diagnostics from today's numbers:
  - about 22 unresolved targets
  - 4 unsupported conditions (`pfm_n_platforms` and `pfm_distribution`)
  - 0 ambiguous targets: the one name with two candidates, in `extensiblesso`, has a single match at the top level, which nearest-scope checks first
  - 29 unparsable app versions (the 14 empty strings are treated as absent)
  - plus whatever value-type mismatches exist

  Every manifest should convert, and the counts get reported in the PR.
