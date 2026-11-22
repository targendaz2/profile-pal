# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Profile Pal is a macOS SwiftUI app for building and editing Apple configuration profiles (`.mobileconfig`). Its editing UI will be driven by [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) manifests (`pfm_*` plist keys), which describe each payload domain and its fields.

The project is early: the manifest model layer (`ProfileManifestKit`) and version parsing (`VersionKit`) exist, while the UI is still the template `ContentView`. Work in progress is the app's schema layer, a cleaner format between the manifest models and the UI; its plan, status, and open follow-ups are in [`docs/plans/schema-layer.md`](docs/plans/schema-layer.md).

## Build, test, format

- Build and test through the `xcode` MCP server (enabled in `.claude/settings.json`), using `BuildProject`, `RunAllTests`, `RunSomeTests`, and `XcodeRefreshCodeIssuesInFile`. Fall back to the CLI only if it's unavailable:
  ```sh
  xcodebuild -project ProfilePal.xcodeproj -scheme ProfilePal -configuration Debug build
  ```
- Tests live in the `ProfileManifestKitTests`, `VersionKitTests`, and `ProfilePalTests` targets and use **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.
- Format with the toolchain's swift-format (config in `.swift-format`: 4-space indent, 100-column lines, trailing commas on multiline collections, `switch` case labels indented):
  ```sh
  xcrun swift-format format -i -r ProfilePal ProfilePalTests ProfileManifestKit ProfileManifestKitTests VersionKit VersionKitTests
  xcrun swift-format lint -r ProfilePal ProfilePalTests ProfileManifestKit ProfileManifestKitTests VersionKit VersionKitTests
  ```

## Project setup

- Targets: the `ProfilePal` app and its `ProfilePalTests`; the `ProfileManifestKit` framework and `ProfileManifestKitTests`; and the `VersionKit` framework and `VersionKitTests`. Both frameworks are embedded in the app and are built only for it, so they don't use library-evolution or module-verifier settings. Three shared schemes: `ProfilePal` builds and runs the app and runs `ProfilePalTests` and `VersionKitTests`; `ProfileManifestKit` and `VersionKit` each build their framework and run its tests, so make the matching one active before running a framework's tests. CI runs the two framework schemes. Swift 6, set at the project level, with approachable concurrency; the models are all `Sendable`.
- The project uses Xcode file-system-synchronized groups, so files added under each target's folder are picked up without editing `project.pbxproj`. Test fixtures are the exception: each must be added to its Copy Files phase (see `.claude/rules/testing-plist-fixtures.md`).
- The app is sandboxed with read-only access to user-selected files.

## Architecture: manifest models (`ProfileManifestKit`)

- `Manifest` is one payload domain (`pfm_domain`). Its `subkeys` is a tree of `ManifestField`s, nested through `subkeys` for arrays and dictionaries. Load one with `Manifest.load(from:)`, which uses `PropertyListDecoder`.
- `ManifestField.require`/`conditionals`/`exclude` hold requirement logic. `ManifestConditionalRule` and `ManifestExclusionRule` each contain `ManifestTargetCondition`s that test *another* field by name (`pfm_target`, which is optional because some real conditions test the platform instead).
- `PlistValue` is a type-erased plist value used wherever a key can hold any type (defaults, range lists, placeholders). `PropertyListDecoder` decodes a whole-number `<real>` as `.int`, so call `coerced(to:)` with the value's `ManifestField` before encoding. It also reaches values nested in arrays and dictionaries.
- Every model property maps to a `pfm_*` key through an explicit `CodingKeys` enum. In v1, loading existing manifests comes first: a property is non-optional only when the spec requires its key and real manifests reliably include it. A spec-required key that real manifests leave out stays optional, with a row in `docs/decisions.md` saying why.

### Rules for model code

- **The spec is the source of truth.** Models mirror the documented ProfileManifests format. Don't add undocumented keys or enum cases, even ones real-world manifests use, and don't add derived logic that "fixes" spec quirks (for example, merging `require` and `required`). Flag spec ambiguity as deferred work instead.
- Path-scoped rules in `.claude/rules/` govern every type in `ProfileManifestKit/`. Types the app uses must be `public`. `coding-model-property-order.md` sets the property and `CodingKeys` order (Apple-defined keys, then extended keys, each ordered by purpose). `coding-model-doc-comments.md` sets the `///` comment style. `ManifestField` is the reference implementation for both.
- Skip doc comments on enum cases whose names already say everything (such as `ManifestFieldType`).

## Workflow

- Work on feature branches and open PRs into `main`. When a non-draft PR touches Swift, pbxproj, plist, or entitlements files, `.github/workflows/code-review.yml` runs an automated Claude code review on it.
- Work that spans several PRs gets a plan in `docs/plans/` with a status table and open follow-ups. Check it at the start of a session, and update its status as PRs open and merge.
- When a pre-commit check (security review, diagnostics) finds an issue, report it and wait for the user. Don't fix it yourself.
- When a decision becomes a convention, write it as a rule (here or in `.claude/rules/`) instead of logging it. Log other decisions that shape the shipped app (scope cuts, deferrals) in `docs/decisions.md` when they're made, and check it before proposing work it rules out. Track unsettled questions in `docs/outstanding-questions.md`; when one is settled, log it (or write the rule) and remove it from that file.
