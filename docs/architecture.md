# Architecture

ProfilePal is a macOS 26+ app for editing Apple configuration profiles from the
[ProfileManifests](https://github.com/ProfileManifests/ProfileManifests) format.
It has two layers:

- **`ProfileManifestKit`** (framework) — reads/parses manifests, evaluates
  conditionals, resolves controls, owns the value model, and (later) manifest
  loading + edit→export value processing. **Headless**: it vends SwiftUI
  `Binding`s but ships no views.
- **`ProfilePal`** (app) — native window chrome (`NavigationSplitView` +
  `.toolbar`) and one recursive `NodeView` that renders the framework's form tree.
  All layout and styling live here.

The GUI is based on the "Profile Editor – Liquid Glass" Claude Design mockup,
**adapted to native macOS 26** (materials, sidebar, toolbar, grouped `Form` insets
come free) rather than reproduced 1:1. See [decisions.md](decisions.md).

## Three lifetimes

The split that keeps everything decoupled (and makes caching clean):

1. **Definitions** — `PFMPayload`, parsed from a `pfm_*` plist. Immutable,
   `Sendable`, cacheable.
2. **Edit state** — `FormModel`, one per opened payload, lives for the session.
3. **Rendered tree** — `formTree`, recomputed live and cheaply (it *must* stay
   live: visibility/requirement/segments depend on current edits).

## Public API (framework)

The app touches only *form* concepts — never a manifest type.

```
FormModel (@Observable @MainActor)
  init(manifest:) · formTree · value(at:)/setValue(_:at:)        (escape hatch)
  stringBinding/boolBinding/doubleBinding/dateBinding/binding(at:)
  addArrayElement(at:) · removeArrayElement(at:index:)

FormNode  = field(Field) | group(id,title,isSet,children)
          | array(id,title,rows) | segmented(id,tabs,groups)

Field     = id · control · title · help · note · isRequired
          · isSet (present/absent Binding) · text/bool/number/date/selection bindings

Control (leaf-only) = textField(secure:) | toggle(inverted:) | radioTwoState(titles:)
          | popUp(options:allowsCustom:) | slider(min:max:) | stepper(min:max:)
          | datePicker(style:) | fileDrop(types:) | unsupported
          Control.Option = value · title

PFMPayload (identity: domain/title/description) · FormPath · PFMValue
```

Internal (not public): `PFMSubkey`, `PFMType`, `control(for:)`,
`isVisible`/`isRequired`, condition types (`PFMConditional`/`PFMExclusion`/`PFMTargetCondition`),
`PFMPayload.subkeys`.

`Control` is **leaf-only** — dictionaries/arrays/segmented are expressed as
`FormNode` kinds, so a `Field.control` is always a real widget (no dead cases in
the app's switch). `Field` is **prepared**: it carries the control, labels, and
ready-to-bind values, so the app writes `field.text` rather than reaching into the
manifest. `isSet` makes the absent-vs-present distinction a first-class affordance.

## App render loop

One file (`ProfilePal/ManifestFormView.swift`): a recursive `NodeView` walks
`formTree`, switches on `FormNode`, and for a leaf switches on `Field.control` to a
native control bound to the prepared binding. Group set-toggle, array Add/Delete,
and segmented tabs are wired. Styling grows this file; no new types.

## Lifecycle

- **`ManifestStore`** (planned, step 2): one per app; parses definitions lazily,
  caches, and vends `PayloadPlaceholder`s for the sidebar / add-payload list and
  full `PFMPayload`s on open. Source-keyed (multiple manifest sources).
- **`FormModel` per opened payload**: the edit state, held for the session (e.g.
  `[domain: FormModel]` on a future `Profile` aggregate). Switching payloads swaps
  which model renders.

## Value model — edit vs. export seam

`PFMValue` is the **edit** representation the bindings read/write. Some subkeys
store a *different* representation in the profile (hex→data, time→minutes,
weekdays-bitmask→int, …). A per-subkey `ValueProcessor` (planned, step 3) bridges
the two; `exportedProfile()` applies it. v1 ships identity/normalize only, but the
seam exists so export doesn't have to reshape the value type. Mirrors
ProfilePayloads' `ValueProcessors`.

## Status

- **Done:** `PFMValue`, manifest model, `FormModel` + value tree, condition
  evaluator, control resolution, headless render tree, headless prepared-field API
  + one-file app renderer (the "step 1" reshape).
- **Next:** `ManifestStore` + `PayloadPlaceholder` (loading/caching), then the
  `ValueProcessor` seam wired into `.mobileconfig` export.
- **Deferred:** concrete value processors; `pfm_overrides`; non-manifest payload
  sources (`PayloadCustom`, managed preferences); remote/GitHub manifest sources.

## Alignment with ProfileCreator / ProfilePayloads

The framework/app split matches the mature reference (ProfilePayloads = logic,
ProfileCreator = AppKit UI). Concept map:

| Ours | ProfilePayloads |
|------|-----------------|
| `PFMPayload` / `PFMSubkey` | `PayloadManifest` / `PayloadManifestSubkey` |
| `PFMConditional`/`PFMExclusion`/`PFMTargetCondition` | `PayloadCondition`/`PayloadExclude`/`PayloadTargetCondition` |
| `ManifestStore` / `ManifestSource` (planned) | `ManifestRepositories` / `ManifestRepository` |
| `PayloadPlaceholder` (planned) | `PayloadPlaceholder` |
| `ValueProcessor` (planned) | `ValueProcessors` |
| overrides (deferred) | `PayloadOverride` |
| `FormModel` + `formTree` | `Payload` runtime model + payload controllers |
