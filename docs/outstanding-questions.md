# Outstanding questions

Questions that shape the shipped app but aren't settled yet. When one is settled, log it in [decisions.md](decisions.md), or write it as a rule if it's a convention, and remove it here.

The survey numbers below come from decoding all 288 of [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests)' manifests (commit `0d01e64`) on 2026-11-20. 286 load.

## Where will the app get its manifests?

ProfileManifests has no license, so the app likely can't bundle its manifests. The app is sandboxed with read-only access to user-selected files, so downloading them at runtime would need a network entitlement. Options include asking the maintainers to add a license, having the user point the app at a local checkout, or downloading at runtime. The answer also decides whether `ProfileManifestKit` needs more than `Manifest.load(from:)` for a single file, such as a loader for a folder or for ProfileManifests' `index`.

## How should the kit type `PlistValue` against `pfm_type`?

`pfm_type` is authoritative. A value that doesn't match it should be converted to that type and reported, and a value that can't be converted should be reported and left out of the field. Three questions are still open:

- **Which conversions count?** Candidates include integer to real, a whole-number real to integer, `"5"` to integer, integer 0 or 1 to boolean, and an ISO 8601 string to date.
- **When one array item can't be converted,** is that item dropped, or the whole value?
- **How does the kit see the type the file wrote?** `PropertyListDecoder` reads `<real>2.0</real>` as an `Int` and `<integer>2</integer>` as a `Double`, so it can't tell them apart. A validator built on it misses integers in `real` fields and whole-number reals in `integer` fields. A custom `Decoder` over `PropertyListSerialization` can tell them apart (`CFNumberIsFloatType`), at the cost of owning a `Decoder` implementation.

The mechanism is open as well. A typing pass inside `Manifest.load` keeps `ManifestField`'s synthesized decoding and can also type condition values once their targets are resolved. `DecodableWithConfiguration` needs a hand-written `ManifestField.init(from:)` and can't type conditions, whose targets aren't decoded yet.

## Should v1 accept undocumented values that real manifests use?

The spec rule forbids undocumented enum cases, but v1 prioritizes loading existing manifests (see [decisions.md](decisions.md)). The 2 manifests that still fail, ProfileCreator's `com.profilecreator.developer.slider` and `com.profilecreator.developer.textfieldfloat`, use the undocumented `pfm_type` value `float`. They're ProfileCreator's own test manifests, not real payloads. Leaving them failing until v2's graceful handling is the current behavior.

## Do the `pfm_app_*` keys apply to payloads?

The spec's table says `pfm_app_min`, `pfm_app_max`, and `pfm_app_deprecated` apply to fields only, but their descriptions say "key or payload", and 10 manifests set `pfm_app_min` on the payload. They're modeled on `ManifestField` only, so payload values are dropped.

## How should `pfm_n_platforms` and `pfm_distribution` in conditions be handled?

7 conditions in 4 Apple manifests have no `pfm_target` and test the environment instead of a field. `pfm_platforms` is now modeled on `ManifestTargetCondition` (see [decisions.md](decisions.md)), which covers 3 of them. The other 4 use `pfm_n_platforms` (1 condition in `com.apple.carddav.account`) or `pfm_distribution` (3 in `com.apple.configurationprofile.identification`). `pfm_n_platforms` in a condition is only an inference from the spec's `pfm_platforms` example, and `pfm_distribution` isn't documented, so neither is modeled. Those conditions still decode with every property `nil`.

## How malformed can a manifest be and still load?

v2 or later should load partly malformed manifests and flag each problem in the GUI (see [decisions.md](decisions.md)). Some problems, such as a missing `pfm_domain` or a file that isn't a plist, must still fail. Where the line is for the rest, such as a manifest with many fields skipped, isn't decided.
