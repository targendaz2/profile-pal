# Decisions

Short records of the load-bearing choices. Newest first.

## D6 — Cache manifests at startup; edit state per opened payload
Parse definitions once into `PFMPayload` (immutable, `Sendable`) via a
`ManifestStore`; build a `FormModel` per opened payload for the session. The
rendered `formTree` stays live (it depends on edits — conditionals). Don't freeze
the rendered tree.
**Why:** fast launch + no runtime parsing; matches ProfileCreator's
placeholder-then-full-load pattern. See [architecture.md](architecture.md).

## D5 — Align with ProfileCreator / ProfilePayloads
Adopt its proven splits: a source-keyed manifest store with lightweight
placeholders (step 2), and an edit→export `ValueProcessor` seam so `PFMValue` is
explicitly the *edit* value and export transforms it (step 3). Reserve
`pfm_overrides` (decode-and-ignore for v1).
**Why:** the mature reference independently converged on the same framework/app
split; its deltas were all additive framework surface. `PFMValue`-as-both-edit-and-
export is the one simplification to correct, before export bites.

## D4 — GUI basis: "Liquid Glass" mockup, adapted to native (not 1:1)
Base the UI on the Claude Design "Profile Editor – Liquid Glass" project, but lean
on what macOS 26 renders natively (sidebar, toolbar, materials, grouped `Form`)
and only hand-build the distinctive parts (type pills, tinted nesting, set
affordance). Coupling GUI↔logic is acceptable pre-v1.

## D3 — Minimal 2-layer for now (framework + app), not a component layer
One app, so skip the swappable middle "components" layer (the RHF-style
`ManifestComponents` protocol / `DefaultComponents`). The framework hands a
prepared tree; the app has one recursive `NodeView` with styling inline.
**Why:** fewest moving parts; the `Field`/`FormNode` core is identical to the
richer designs, so extracting a component layer later is non-breaking. Considered
and deferred: framework-renders-with-styles, structure+leaf-closure, pure-logic
(no SwiftUI), and the 3-layer RHF split.

## D2 — Headless "prepared field" API; `Control` leaf-only
The framework is headless (owns parsing/logic/value model, vends `Binding`s, ships
no views). `Control` carries only leaf widgets; structure lives in `FormNode`.
`Field` is fully prepared (control + labels + typed bindings + an `isSet`
present/absent binding) so the app never touches the manifest model.
**Why:** the app must own 100% of a dense, bespoke layout; a prepared model gives
that with minimal app code and no manifest vocabulary leaking into the app.
Implemented in the step-1 reshape.

## D1 — Framework owns manifest logic; app owns rendering/styling
All manifest reading, parsing, conditionals, and control resolution live in
`ProfileManifestKit`; the app owns appearance, layout, and presentation.
**Why:** separation of concerns, testable headless logic, and it matches
ProfileCreator/ProfilePayloads.
