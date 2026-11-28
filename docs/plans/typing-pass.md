# Plan: ProfileManifestKit's typing pass

## Status

| Step | State |
| --- | --- |
| 0: Survey mismatched values | Done on 2026-11-28. The results trimmed the conversion table (see [decisions.md](../decisions.md)). |
| A: Conversion and field-value typing | **In progress** on branch `feat/best-effort-loading`. |
| B: Condition targets and condition-value typing | Not started. Branch from `main` once A merges. |

## Open follow-ups

These are outside PR A's and PR B's scope.

- **Field-level drops:** an element wrapper on `subkeys` for an unknown or missing `pfm_type`, or a missing `pfm_name`.
- **Key-level drops:** still an open question in [outstanding-questions.md](../outstanding-questions.md).
- **Load failures:** the minimal `pfm_domain` check, and failing a manifest with no usable fields.
- **Tests that should stop throwing:** update `ManifestFieldTests.unknownType` and `ManifestTests.unknownInteraction` when those drops land.

## Context

`ProfileManifestKit` guarantees that every default, range-list item, and condition value it returns is typed by its field, so the schema converter never coerces values. Placeholders are only displayed, so they load as decoded. Today `PlistValue` decodes by guessing, and callers call the public `coerced(to:)`, which handles only int to double.

The design, all logged in [decisions.md](../decisions.md):
- one typing pass inside `Manifest.load(from:)`, after normal decoding;
- one shared conversion function;
- a bad array item or dictionary entry is dropped alone;
- conversions and drops are reported as issues;
- condition targets are resolved in the kit so their test values can be typed.

## Step 0: survey results

All 288 manifests at ProfileManifests `0d01e64`, decoded with Python's `plistlib`, which keeps `<integer>` and `<real>` apart:

| Value | Checked | Mismatched |
| --- | --- | --- |
| Defaults | 5,524, plus 34 array items and dictionary entries | 4, all `<integer>` on a real field (silent) |
| Range-list items | 5,237 | 0 |
| Placeholders | 1,400 | 158, now exempt from typing |
| Condition values | 984 (28 more had targets a bare-name lookup couldn't resolve) | 3, `<integer>` 0 on a boolean target |

No manifest puts `pfm_range_list` on an array field.

## PR A: conversion and field-value typing

- **Issues:** a public `ManifestIssue` (`fieldPath: [String]`, the raw `pfm_` `key`, and `kind`), with kinds `.valueConverted(from:to:)` and `.valueDropped(_:expected:)`. Each kind holds the value as written, so the GUI can show it, which makes `PlistValue` `Hashable`. An unnamed array item appears in `fieldPath` as `[]`.
- **Delivery:** `Manifest.issues`, a `public internal(set) var` outside `CodingKeys`. `load(from:)` keeps its signature.
- **Mutability:** the value properties (`defaultValue`, `rangeList`, and `rangeListTitles`, which loses the title of each dropped range-list value) and `subkeys` become `public internal(set) var`. The condition properties wait for PR B, which first needs them. Their doc comments say values are typed only through `Manifest.load(from:)`.
- **Conversion function** (`PlistValue+Conversion.swift`, internal): it replaces `coerced(to:)` and keeps its recursion. Arrays use their first subkey; dictionaries use the subkey with the same name and keep entries with no subkey. A bad item or entry is dropped and reported alone. Scalar conversions are only the ones in decisions.md:
  - an `<integer>` 0 or 1 to a boolean;
  - a `<string>` to an integer or real when it parses as one, finite only, or to a boolean when it's `true`/`false`, `YES`/`NO`, or `1`/`0`, ignoring case;
  - an `<integer>` to a string as its digits;
  - a single value to a one-item array when it converts to the item type.

  `.int` on a real field becomes `.double` and `.uint` passes on an integer field, both without an issue. Every other mismatch is dropped and reported.
- **The pass** (`Manifest+Typing.swift`, internal): `load(from:)` calls it after decoding. It types `defaultValue` and each `rangeList` item, recursing through `subkeys`. Remove the public `coerced(to:)`, and update `CLAUDE.md`'s `PlistValue` paragraph.
- **Tests:**
  - Move the `coerce*` tests from `PlistValueTests` into `PlistValueConversionTests`. Build values in Swift, and load fields from `Fixtures/PlistValue/field-*.plist`, adding fixtures as needed.
  - Add one test per conversion, plus tests for dropping a mismatched scalar, for dropping an item, dropping an entry, and the issues recorded.
  - Make `ManifestTests.coerceRealWorldDefault` check that `load` alone returns `.double(1)`.
  - Add a load-level test that checks typed values and `manifest.issues`.

## PR B: condition targets and condition-value typing

- A public `ManifestTargetReference` (`levelsUp`, `path`) stored on `ManifestTargetCondition.resolvedTarget`, a `public internal(set) var` outside `CodingKeys`.
- **Resolution:** split `pfm_target` on `.`, start at the conditioned field's siblings, and walk outward to the root. The first level with exactly one match wins. More than one match at a level is ambiguous, and no match anywhere is unresolved. Both are issues. Conditions with no target are skipped.
- **Typing:** `rangeList` and `negatedRangeList` are typed against the target, and `containsAny` and `negatedContainsAny` against the target's item subkey.
- **Tests:** synthetic `ManifestCondition` fixtures for a bare unique name, an array-item sibling, a dotted root path, a relative dotted path, an ambiguous name, a missing target, and a platform-only condition, plus typing each one's test values.

## Verification

- Use the `ProfileManifestKit` scheme with the `xcode` MCP server (`BuildProject`, `RunAllTests`), then run the `CLAUDE.md` swift-format lint.
- Load every manifest in a local ProfileManifests checkout through `Manifest.load`. Check that every default, range-list item, and condition value matches its field's type, and that the issue counts match the survey. Commit no ProfileManifests files.
