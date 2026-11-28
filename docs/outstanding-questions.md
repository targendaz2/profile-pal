# Outstanding questions

Questions that shape the shipped app but aren't settled yet. When one is settled, log it in [decisions.md](decisions.md), or write it as a rule if it's a convention, and remove it here.

The survey numbers below come from decoding all 288 of [ProfileManifests](https://github.com/ProfileManifests/ProfileManifests)' manifests (commit `0d01e64`) on 2026-11-20. 286 load.

## Where will the app get its manifests?

ProfileManifests has no license, so the app likely can't bundle its manifests. The app is sandboxed with read-only access to user-selected files, so downloading them at runtime would need a network entitlement. Options include asking the maintainers to add a license, having the user point the app at a local checkout, or downloading at runtime. The answer also decides whether `ProfileManifestKit` needs more than `Manifest.load(from:)` for a single file, such as a loader for a folder or for ProfileManifests' `index`.

## Do the `pfm_app_*` keys apply to payloads?

The spec's table says `pfm_app_min`, `pfm_app_max`, and `pfm_app_deprecated` apply to fields only, but their descriptions say "key or payload", and 10 manifests set `pfm_app_min` on the payload. They're modeled on `ManifestField` only, so payload values are dropped.

## How should `pfm_n_platforms` and `pfm_distribution` in conditions be handled?

7 conditions in 4 Apple manifests have no `pfm_target` and test the environment instead of a field. `pfm_platforms` is now modeled on `ManifestTargetCondition` (see [decisions.md](decisions.md)), which covers 3 of them. The other 4 use `pfm_n_platforms` (1 condition in `com.apple.carddav.account`) or `pfm_distribution` (3 in `com.apple.configurationprofile.identification`). `pfm_n_platforms` in a condition is only an inference from the spec's `pfm_platforms` example, and `pfm_distribution` isn't documented, so neither is modeled. Those conditions still decode with every property `nil`.

## How does the kit drop a single bad key without failing its field?

Key-level dropping conflicts with the decision that `ManifestField` keeps its synthesized decoding. A synthesized `init(from:)` throws on the first key whose value doesn't decode, which fails the whole field. The options are to hand-write `ManifestField.init(from:)` (about 40 keys) and the other models' decoders, or to keep synthesized decoding and wrap each property in a lenient property wrapper, with a `KeyedDecodingContainer` overload for that wrapper so a missing key still decodes as `nil`. Either way, the conversions to each key's fixed type need to run at decode time, because the value never reaches the typing pass if decoding throws.
