# ProfileManifestKit: remaining tests

As of 2026-11-20.

Every manifest model is fully tested on `feat/manifest-framework`, in `PlistValueTests`, `ManifestFieldTests`, `ManifestConditionTests`, and `ManifestTests`, including smoke tests against two real manifests. No tests are left; what remains are the open decisions and model gaps below, which the real-manifest survey surfaced. Manifests are XML plists only; binary manifest support is deferred to v2 (see [decisions.md](decisions.md)).

Every new test follows the two rules in `.claude/rules/`:

- **`testing-unit-test-style.md`:** Given / When / Then comments that say what each step is, one concept per line. Minimal `func` names, with context in the `@Test` display name. `func` on the line below `@Test(...)`. An "And not" check where an earlier-tried type could realistically claim the value. No tests of behavior Swift synthesizes, such as an enum's implicit raw values.
- **`testing-plist-fixtures.md`:** XML fixtures in `ProfileManifestKitTests/Fixtures/<Subject>/`, one case per file. Each folder gets its own `Copy <Subject> Fixtures` build phase, and every new fixture must be added to that phase by hand.

## Real-manifest smoke tests

`ManifestTests.loadRealWorld` loads unmodified manifests from [xCreds](https://github.com/twocanoes/xcreds) (BSD-3-Clause) and [macOSLAPS](https://github.com/joshua-d-miller/macOSLAPS) (MIT). Sources, commits, and licenses are in `Fixtures/Manifest/THIRD-PARTY-NOTICES.md`. `ManifestTests.coerceRealWorldDefault` checks xCreds' whole-number `<real>` defaults.

[ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) has no license (the MIT text in its `ACKNOWLEDGEMENTS.md` covers Apple's schema), so none of its manifests are committed. Neither open-source manifest uses `pfm_conditionals` or `pfm_exclude`, so conditions are covered by synthetic fixtures only.

## Findings from the real-manifest survey

On 2026-11-20, 112 of ProfileManifests' 118 Apple manifests (commit `0d01e64`) loaded. The 6 failures, and keys that load but are dropped, point at these gaps. None is fixed yet.

- [ ] **`always-nested` is missing from `ManifestRequirement`.** The spec documents it for a field's `pfm_require` (format version 2), but for a conditional's `pfm_require` it lists only `always` and `push`, and both use the same enum. 2 Apple manifests fail on it.
- [ ] **`ManifestTargetCondition` lacks two documented keys.** `pfm_value_empty`, which the spec oddly marks required, and the extended condition key `pfm_domain`. Both are silently dropped (`com.apple.dock` uses `pfm_value_empty`).
- [ ] **Undocumented condition keys fail the whole manifest.** 4 Apple manifests have conditions with only `pfm_platforms`, `pfm_n_platforms`, or `pfm_distribution` and no `pfm_target`, which the spec requires. This is the strict-spec policy working as designed.
- [ ] **The models implement a subset of the documented extended keys.** Both open-source manifests use `pfm_app_min`, `pfm_app_max`, `pfm_app_deprecated`, `pfm_app_url`, `pfm_platforms`, `pfm_unique`, `pfm_hidden`, or `pfm_description_reference`, which load but are dropped. No decision records this as a scope cut.

## Open decisions

- [ ] **Real manifests vs. the strict spec.** Real manifests with undocumented values fail to load, by design, while undocumented keys are silently dropped. The smoke-test fixtures were chosen to pass; the findings above list the failures seen.
- [ ] **One bad enum value fails the whole manifest.** `ManifestFieldTests.unknownType` and `ManifestTests.unknownInteraction` pin this behavior. Decide whether that's the intended product behavior before the UI depends on it.

## Deferred to v2

- **Binary manifests.** Manifests are XML plists only in v1, so manifest tests use XML fixtures alone. When binary support is added, run the `PlistValue` fixture decode tests and the `load(from:)` test against binary plists too, converting the XML fixtures in the test with `PropertyListSerialization` rather than committing binary copies. `PlistValueTests.roundTrip` already covers binary encoding, which applies to payloads rather than manifests.
