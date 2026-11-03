# ProfileManifestKit: remaining tests

As of 2026-11-03.

`PlistValue` and `ManifestField` are fully tested on `feat/manifest-framework`: 39 passing cases in `PlistValueTests` and 8 tests in `ManifestFieldTests`. What's left is suites for the other two manifest model files: `ManifestCondition` and `Manifest`. Manifests are XML plists only; binary manifest support is deferred to v2 (see [decisions.md](decisions.md)).

Every new test follows the two rules in `.claude/rules/`:

- **`testing-unit-test-style.md`:** Given / When / Then comments that say what each step is, one concept per line. Minimal `func` names, with context in the `@Test` display name. `func` on the line below `@Test(...)`. An "And not" check where an earlier-tried type could realistically claim the value. No tests of behavior Swift synthesizes, such as an enum's implicit raw values.
- **`testing-plist-fixtures.md`:** XML fixtures in `ProfileManifestKitTests/Fixtures/<Subject>/`, one case per file. Each folder gets its own `Copy <Subject> Fixtures` build phase, and every new fixture must be added to that phase by hand.

## 1. `ManifestConditionTests`

New fixture folder `Fixtures/ManifestCondition/` with a `Copy ManifestCondition Fixtures` phase.

| Test | Fixture | Checks |
| --- | --- | --- |
| Target condition, every key | `condition-all-keys` | All six keys set, with mixed-type range lists; every property matches. |
| Target condition, missing target | `condition-missing-target` | Throws `keyNotFound`. |
| Conditional rule, minimal | `conditional-rule-minimal` | `pfm_require` is optional; `require` is `nil`. |
| Conditional rule, missing conditions | `conditional-rule-missing-conditions` | Throws `keyNotFound`. |
| Exclusion rule, missing conditions | `exclusion-rule-missing-conditions` | Throws `keyNotFound`. |
| Wiring | `field-with-rules` | A field with `pfm_conditionals` and `pfm_exclude` decodes all the way down to its target conditions. |

## 2. `ManifestTests`

New fixture folder `Fixtures/Manifest/` with a `Copy Manifest Fixtures` phase.

| Test | Fixture | Checks |
| --- | --- | --- |
| Every key | `manifest-all-keys` | All 23 keys set, including `pfm_icon` (`<data>`) and `pfm_last_modified` (`<date>`); every property matches. |
| Minimal | `manifest-minimal` | Only `pfm_domain` and `pfm_subkeys`; every optional property is `nil`. |
| Missing domain | `manifest-missing-domain` | Throws `keyNotFound`. |
| Missing subkeys | `manifest-missing-subkeys` | Throws `keyNotFound`. |
| Unknown interaction | `manifest-interaction-unknown` | An undocumented `pfm_interaction` value throws. Pins the strict-spec policy. The documented values' raw values are synthesized, so they aren't tested. |
| `load(from:)` | `manifest-minimal` | Loads from the fixture's bundle URL. |
| `load(from:)`, missing file | none | A URL that doesn't exist throws. |
| `load(from:)`, not a plist | `not-a-plist.txt` | A text file throws. |

## 3. Real-manifest smoke test (optional)

Copy one or two real manifests from [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) (MIT licensed) into `Fixtures/Manifest/`, such as `com.apple.applicationaccess` or a domain that uses conditionals. Check that each loads and has subkeys.

## Open decisions

- [ ] **Real manifests vs. the strict spec.** Real manifests with undocumented `pfm_type` or target values fail to load, by design. Choose fixtures that pass, or treat a failure as a finding.
- [ ] **One bad enum value fails the whole manifest.** The tests above pin this behavior. Decide whether that's the intended product behavior before the UI depends on it.
- [ ] **Coercing array items.** `coerced(to:)` doesn't recurse into arrays (pinned by `coerceArray`). Decide who coerces the items of a real-typed array or `rangeList`.

## Deferred to v2

- **Binary manifests.** Manifests are XML plists only in v1, so manifest tests use XML fixtures alone. When binary support is added, run the `PlistValue` fixture decode tests and the `load(from:)` test against binary plists too, converting the XML fixtures in the test with `PropertyListSerialization` rather than committing binary copies. `PlistValueTests.roundTrip` already covers binary encoding, which applies to payloads rather than manifests.
