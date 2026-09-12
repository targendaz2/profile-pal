# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Profile Pal is a macOS app (SwiftUI, macOS 26.0+, Swift 6) for building Apple configuration
profiles from Apple's [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests)
format. `ProfileManifestKit` decodes `pfm_*` payload manifest plists into typed Swift models and
drives a dynamic form (`FormModel`) for editing the resulting profile payload as a `PFMValue` tree.

**The framework is headless.** It owns all manifest *logic* — decode, value tree, conditions
(visibility/requirement), control resolution, and export — and exposes it as a queryable, public
API (`FormModel`, `control(for:)`, and the `FormNode` render tree). The **app** owns 100% of the
SwiftUI: it walks `FormNode`, switches on each field's `Control`, and applies its own styling. No
SwiftUI ships from `ProfileManifestKit`. Keep that boundary: rendering/presentation decisions
belong in the app, manifest semantics belong in the framework.

## Build & test

This is an Xcode project (`ProfilePal.xcodeproj`), not SwiftPM. Use `xcodebuild` or the `xcode` MCP
server (`mcp__xcode__*`, configured in `.mcp.json`) rather than `swift build`/`swift test`.

```sh
# List targets/schemes
xcodebuild -list -project ProfilePal.xcodeproj

# Build a target/scheme
xcodebuild build -project ProfilePal.xcodeproj -scheme ProfilePal

# Run all ProfileManifestKit tests
xcodebuild test -project ProfilePal.xcodeproj -scheme ProfileManifestKitTests -destination 'platform=macOS'

# Run a single test (XCTest-style identifier works for Swift Testing too)
xcodebuild test -project ProfilePal.xcodeproj -scheme ProfileManifestKitTests \
  -destination 'platform=macOS' -only-testing:ProfileManifestKitTests/PayloadManifestTests
```

Targets: `ProfilePal` (app), `ProfileManifestKit` (framework — the actual logic), and
`ProfileManifestKitTests` (Swift Testing, depends on `ProfileManifestKit`). All three use Xcode's
file-system-synchronized groups, so new files under `ProfileManifestKit/` or
`ProfileManifestKitTests/` are picked up automatically — no `.pbxproj` editing needed.

Note: Xcode's SourceKit index can lag behind newly-added files and report false
"Cannot find type in scope" diagnostics; a build (`mcp__xcode__BuildProject` or `xcodebuild build`)
is the source of truth, not the live diagnostics list.

## Architecture

**Decoding pipeline**: `PayloadManifest` (top-level plist) → `[ManifestSubkey]` (`pfm_subkeys`,
recursively nested for `dictionary`/`array` types) → `PFMValue` (the actual decoded/edited value,
an indirect enum covering every plist type: string/integer/real/boolean/date/data/array/dictionary).
`PFMType` is the `pfm_type` enum subkeys declare; `Manifest/Conditions.swift` holds the rest of the
manifest vocabulary (`RequireMode`, `HiddenMode`, `Conditional`, `Exclusion`, `TargetCondition` for
`pfm_target_conditions`).

Key invariant: a subkey's declared `pfm_type` doesn't necessarily match the literal type
`Decodable` infers from the plist value (e.g. a `real` field with an integer-looking default).
`PFMValue.normalized(to:)` coerces a decoded value to its subkey's declared type and must be used
whenever a value is seeded or read against its manifest type — see `PFMValue.seed(for:)`. It uses
`Int(exactly:)` rather than `Int(r)` because the source plist is untrusted input; don't reintroduce
a trapping conversion here.

**Form editing**: `FormModel` is an `@Observable` tree of `PFMValue` rooted at a `PayloadManifest`,
addressed by `FormPath` (a `Hashable` sequence of `.key`/`.index` components — dict keys or array
indices). It's seeded once from each subkey's `pfm_default` (coerced via `normalized(to:)`);
subkeys with no default are *absent* from the tree, not present with an empty/zero value — this
distinction is load-bearing throughout (see `FormModelTests`'s "absent vs. empty" suite) since an
absent key means "not in the exported payload" while an empty string is still an exported value.
`set(_:at:in:)` rebuilds the tree spine immutably along a path without disturbing sibling values.
Typed `Binding` helpers (`stringBinding`, `boolBinding`, `doubleBinding`) bridge `PFMValue` to
SwiftUI controls; `boolBinding` honors `pfm_value_inverted`. `doubleBinding` currently always writes
back `.real` regardless of the subkey's declared type (see the `TODO` in `FormModel.swift`) — fine
while only `real`-typed subkeys use it, but coerce via `normalized(to:)` if an integer-typed slider
is added.

**Testing pattern**: manifests are never hand-written as XML strings. `PlistFixture` (in
`FixtureGen.swift`) builds fixtures as `[String: Any]` trees and serializes them with
`PropertyListSerialization`, so malformed XML can't be produced by a typo. `PlistFixtures` holds
reusable named fixtures (e.g. `.dock`, `.trap`). Tests then round-trip through
`PropertyListDecoder().decode(PayloadManifest.self, from:)`.

## Correctness invariants (don't regress these)

- **Plist decode probes `Bool` before `Int`** — a `<true/>` also decodes as `Int 1`;
  reversing this silently turns every boolean into an integer.
- **`pfm_required` (Bool) and `pfm_require` (String enum: `always`/`always-nested`/`push`)
  are separate keys** — both decoded, never merged at decode time; resolved only in the
  condition evaluator.
- **Condition absence polarity:** an absent target is `false` for `pfm_range_list`
  (equals-any) and `true` for `pfm_n_range_list` (not-equals-any). `isVisible`/`isRequired`
  on `FormModel` depend on getting this right.
- **`pfm_conditionals` with no `pfm_require` is a no-op.**
- **Control resolution order is load-bearing:** `pfm_segments` then `pfm_range_list` win
  before any type-based default; never trap on an unknown combination — return `.unsupported`.

## Style

Formatting is enforced by `.swift-format` (4-space indent, 100-col lines, one case per line,
switch bodies never on the same line as `case`, trailing commas in multiline collections/calls —
`swift-format` should be run/respected rather than hand-formatting to a different style).
