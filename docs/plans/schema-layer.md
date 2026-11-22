# Plan: a format-neutral schema layer in ProfilePal

## Status

| PR | State |
| --- | --- |
| 1: `pfm_platforms` on conditions | Merged as #9 on 2026-11-22, together with a review-workflow step; see PR 1 below. |
| 2: VersionKit | In review on `feat/version-kit`. |
| 3: The schema layer | Not started. Builds on PRs 1 and 2. |

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

What shipped in #9 (merged):
- `ManifestTargetCondition` has `platforms: [String]?` (`pfm_platforms`), typed to match `Manifest.platforms`. Because it's an extended key, the type now has both `// MARK:` sections. `target`'s doc comment mentions dotted paths and platform-only conditions.
- `pfm_platforms` was added to the existing `target-condition-all-keys.plist` fixture, rather than a new fixture, so `project.pbxproj` stayed out of the PR. `targetConditionAllKeys` checks it.
- The property-order rule's example of a type with only Apple-defined keys is now `ManifestConditionalRule`.
- `docs/decisions.md` logs the change. `docs/outstanding-questions.md` narrows the environment-conditions question to `pfm_n_platforms` (1 condition) and `pfm_distribution` (3).
- `claude-code-review.yml` gains a **Summarize review tool use** step. It logs tool names, permission denials, and models from the action's execution file, because the first review of #9 posted "No issues found" without running its agents. It's on `main` now, so it runs on the next PR the review covers.

Still open: a local review found that no test covers a condition with only `pfm_platforms` and no `pfm_target`, the real Apple shape. It needs its own fixture, which means a Copy Files phase entry in `project.pbxproj`.

## PR 2: VersionKit, branch `feat/version-kit` (independent of PR 1)

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

## PR 3: the schema layer (ProfilePal), branch `feat/payload-schema` on top of PRs 1 and 2

The `ProfilePalTests` target arrives in PR 2, so this PR replaces its placeholder test.

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
  - Describe the `ProfilePalTests` target, and note that the `ProfilePal` scheme runs it.
- `docs/decisions.md`: add rows for the schema layer living in the app, never throwing and recording diagnostics, nearest-scope target resolution, strictest-wins requirement merging, and cross-payload conditions being deferred.

## Verification

- Build and test with the `xcode` MCP server (`BuildProject`, then `RunAllTests`), using the `ProfileManifestKit` scheme for PR 1, `VersionKit` for PR 2, and `ProfilePal` for PR 3.
- Run `xcrun swift-format lint -r ProfilePal ProfileManifestKit ProfileManifestKitTests ProfilePalTests`.
- Clone ProfileManifests at `0d01e64` into the scratchpad and run the survey test with `PROFILEMANIFESTS_DIR` set. The expected diagnostics from today's numbers:
  - about 22 unresolved targets
  - 4 unsupported conditions (`pfm_n_platforms` and `pfm_distribution`)
  - 0 ambiguous targets: the one name with two candidates, in `extensiblesso`, has a single match at the top level, which nearest-scope checks first
  - 29 unparsable app versions (the 14 empty strings are treated as absent)
  - plus whatever value-type mismatches exist

  Every manifest should convert, and the counts get reported in the PR.
