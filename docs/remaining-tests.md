# ProfileManifestKit: remaining tests

As of 2026-11-20.

Every manifest model is fully tested on `feat/manifest-framework`, in `PlistValueTests`, `ManifestFieldTests`, `ManifestConditionTests`, and `ManifestTests`. What's left is an optional smoke test against real manifests. Manifests are XML plists only; binary manifest support is deferred to v2 (see [decisions.md](decisions.md)).

Every new test follows the two rules in `.claude/rules/`:

- **`testing-unit-test-style.md`:** Given / When / Then comments that say what each step is, one concept per line. Minimal `func` names, with context in the `@Test` display name. `func` on the line below `@Test(...)`. An "And not" check where an earlier-tried type could realistically claim the value. No tests of behavior Swift synthesizes, such as an enum's implicit raw values.
- **`testing-plist-fixtures.md`:** XML fixtures in `ProfileManifestKitTests/Fixtures/<Subject>/`, one case per file. Each folder gets its own `Copy <Subject> Fixtures` build phase, and every new fixture must be added to that phase by hand.

## Real-manifest smoke test (optional)

Copy one or two real manifests from [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) (MIT licensed) into `Fixtures/Manifest/`, such as `com.apple.applicationaccess` or a domain that uses conditionals. Check that each loads and has subkeys.

## Open decisions

- [ ] **Real manifests vs. the strict spec.** Real manifests with undocumented `pfm_type` or target values fail to load, by design. Choose fixtures that pass, or treat a failure as a finding.
- [ ] **One bad enum value fails the whole manifest.** `ManifestFieldTests.unknownType` and `ManifestTests.unknownInteraction` pin this behavior. Decide whether that's the intended product behavior before the UI depends on it.

## Deferred to v2

- **Binary manifests.** Manifests are XML plists only in v1, so manifest tests use XML fixtures alone. When binary support is added, run the `PlistValue` fixture decode tests and the `load(from:)` test against binary plists too, converting the XML fixtures in the test with `PropertyListSerialization` rather than committing binary copies. `PlistValueTests.roundTrip` already covers binary encoding, which applies to payloads rather than manifests.
