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

On 2026-11-20, 286 of ProfileManifests' 288 manifests (commit `0d01e64`) loaded. The 2 failures, and keys that load but are dropped, point at these gaps. None is fixed yet.

- [ ] **A conditional's `require` accepts `.alwaysNested`.** The spec allows `always-nested` on a field's `pfm_require` but lists only `always` and `push` for a conditional's, and both use `ManifestRequirement`. One manifest (`com.jamf.connect.login-OpenID`) uses it in a conditional and loads. A separate two-case enum would enforce the spec but reject that manifest.
- [ ] **`ManifestTargetCondition` lacks two documented keys.** `pfm_value_empty`, which the spec oddly marks required, and the extended condition key `pfm_domain`. Both are silently dropped (`com.apple.dock` uses `pfm_value_empty`).
- [ ] **Conditions without `pfm_target` load but say nothing.** 4 Apple manifests have conditions with only `pfm_platforms`, `pfm_n_platforms`, or `pfm_distribution`. `target` is optional so they load (see [decisions.md](decisions.md)), but none of those three keys is modeled, so these conditions have no target and no test. The spec's own example (under "Example Conditions & Exclusions") uses `pfm_platforms` in a condition; `pfm_n_platforms` and `pfm_distribution` aren't documented there.
- [ ] **2 manifests use the undocumented `pfm_type` value `float`.** These fail by design under the strict-spec policy.
- [ ] **`pfm_app_min`, `pfm_app_max`, and `pfm_app_deprecated` are modeled on fields only.** The spec's table says they don't apply to payloads, but their descriptions say "key or payload", and 10 manifests set `pfm_app_min` on the payload. Those payload values are dropped.
- [ ] **`interaction` and `lastModified` are optional on `Manifest`, though the spec requires them on a payload.** `platforms` is required, as the spec says, and `unique` is deliberately optional (see [decisions.md](decisions.md)), so `Manifest` is inconsistent until these two are decided.
- [ ] **The models implement a subset of the documented extended keys.** Still unmodeled, and dropped when present: `pfm_allowed_file_types`, `pfm_default_copy`, `pfm_value_copy`, `pfm_description_extended`, `pfm_description_reference`, `pfm_enabled`, `pfm_excluded`, `pfm_hidden`, `pfm_value_decimal_places`, `pfm_substitution_variables`, `pfmx_comment`, and the 10 keys the spec marks as ProfileCreator-only. No decision records this as a scope cut.

## Open decisions

- [ ] **Real manifests vs. the strict spec.** Real manifests with undocumented values fail to load for now, while undocumented keys are silently dropped. Both should eventually become findings shown in the GUI (see [decisions.md](decisions.md)). The smoke-test fixtures were chosen to pass; the findings above list the failures seen.

## Deferred to v2

- **Binary manifests.** Manifests are XML plists only in v1, so manifest tests use XML fixtures alone. When binary support is added, run the `PlistValue` fixture decode tests and the `load(from:)` test against binary plists too, converting the XML fixtures in the test with `PropertyListSerialization` rather than committing binary copies. `PlistValueTests.roundTrip` already covers binary encoding, which applies to payloads rather than manifests.
