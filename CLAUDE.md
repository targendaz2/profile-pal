# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Profile Pal is a macOS SwiftUI app for building and editing Apple configuration profiles (`.mobileconfig`). Its editing UI will be driven by [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) manifests (`pfm_*` plist keys), which describe each payload domain and its fields.

The project is early: the manifest model layer exists, while the UI is still the template `ContentView`.

## Build, test, format

- Build and test through the `xcode` MCP server (enabled in `.claude/settings.json`), using `BuildProject`, `RunAllTests`, `RunSomeTests`, and `XcodeRefreshCodeIssuesInFile`. Fall back to the CLI only if it's unavailable:
  ```sh
  xcodebuild -project ProfilePal.xcodeproj -scheme ProfilePal -configuration Debug build
  ```
- There is no test target yet. When one is added, use **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.
- Format with the toolchain's swift-format (config in `.swift-format`: 4-space indent, 100-column lines, trailing commas on multiline collections, `switch` case labels indented):
  ```sh
  xcrun swift-format format -i -r ProfilePal
  xcrun swift-format lint -r ProfilePal
  ```

## Project setup

- One target and scheme, `ProfilePal`. Swift 6 with approachable concurrency; the models are all `Sendable`.
- The project uses Xcode file-system-synchronized groups, so files added under `ProfilePal/` are picked up without editing `project.pbxproj`.
- The app is sandboxed with read-only access to user-selected files.

## Architecture: manifest models (`ProfilePal/Models`)

- `Manifest` is one payload domain (`pfm_domain`). Its `subkeys` is a tree of `ManifestField`s, nested through `subkeys` for arrays and dictionaries. Load one with `Manifest.load(from:)`, which uses `PropertyListDecoder`.
- `ManifestField.require`/`conditionals`/`exclude` hold requirement logic. `ManifestConditionalRule` and `ManifestExclusionRule` each contain `ManifestTargetCondition`s that test *another* field by name (`pfm_target`).
- `PlistValue` is a type-erased plist value used wherever a key can hold any type (defaults, range lists, placeholders). `PropertyListDecoder` decodes a whole-number `<real>` as `.int`, so call `coerced(to:)` with the field's `ManifestFieldType` before encoding.
- Every model property maps to a `pfm_*` key through an explicit `CodingKeys` enum. Every key is optional except where the spec requires it.

### Rules for model code

- **The spec is the source of truth.** Models mirror the documented ProfileManifests format. Don't add undocumented keys or enum cases, even ones real-world manifests use, and don't add derived logic that "fixes" spec quirks (for example, merging `require` and `required`). Flag spec ambiguity as deferred work instead.
- Path-scoped rules in `.claude/rules/` govern every type in `ProfilePal/Models/`. `coding-model-property-order.md` sets the property and `CodingKeys` order (Apple-defined keys, then extended keys, each ordered by purpose). `coding-model-doc-comments.md` sets the `///` comment style. `ManifestField` is the reference implementation for both.
- Skip doc comments on enum cases whose names already say everything (such as `ManifestFieldType`).

## Workflow

- Work on feature branches and open PRs into `main`. When a non-draft PR touches Swift, pbxproj, plist, or entitlements files, `.github/workflows/claude-code-review.yml` runs an automated Claude code review on it.
- When a pre-commit check (security review, diagnostics) finds an issue, report it and wait for the user. Don't fix it yourself.
