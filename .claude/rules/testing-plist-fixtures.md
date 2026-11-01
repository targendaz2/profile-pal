---
paths:
  - "ProfileManifestKitTests/**"
---

# Plist test fixtures

Tests read plists from real fixture files, never inline XML strings.

- **Location:** `ProfileManifestKitTests/Fixtures/<Subject>/`, one folder per type or feature under test (e.g. `PlistValue`).
- **One case per file**, named in kebab-case after what it tests (`real-whole.plist`, `array-empty.plist`), not after the expected result.
- **Format:** XML only, tab-indented, standard Apple plist header. Check each new file with `plutil -lint`. Binary variants are derived in the test with `PropertyListSerialization`, not committed, so they can't drift from the XML.
- **Bare values:** a fixture for a value that isn't a whole document (such as a `PlistValue`) wraps it in a root `<dict>` under the key `value`, matching how such values appear in manifests.
- **Copying into the bundle:** each fixture folder gets its own Copy Files build phase in the `ProfileManifestKitTests` target, named `Copy <Subject> Fixtures`, with destination `Resources` and subpath `Fixtures/<Subject>`. Never use the Resources phase (the test target has none): it flattens folders into one namespace and may process plists.
  - The synchronized group doesn't add files to a Copy Files phase on its own. Every new fixture must be added to its folder's phase (Target Membership in Xcode, or the phase's `PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet` in `project.pbxproj`). A fixture left out fails its test with a missing resource.
- **Loading:** `Bundle(for:)` or `Bundle(identifier:)`, then `url(forResource: "<name>", withExtension: "plist", subdirectory: "Fixtures/<Subject>")`.
