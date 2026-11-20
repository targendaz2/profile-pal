---
paths:
  - "**/*.swift"
---

# Readable functions

Applies to any Swift function or block that packs several decisions together. Use `PlistValue.coerced(to:)` as the reference.

- **Spot chunky code:** a single expression that makes more than one decision (a lookup, a fallback, and a transform chained with `map`, `??`, or nested closures), or a `switch` whose cases each run several steps with nothing marking where one ends.
- **Comment each case that does real work:** state what kind of input it handles and, if it isn't obvious, why (`// An array: every item shares one definition, the array's first subkey.`). Skip comments that only repeat the pattern being matched.
- **Comment the surprising branch:** a fallback that leaves a value unchanged or skips work says why at that line (`// No subkey describes this key, so there's no type to coerce to.`).
- **Separate steps with blank lines:** within a case or function, put a blank line between the early exit, the setup, the main work, and the `return`. A `guard` that's followed by more work takes its `else` body on its own lines.
- **Loop when a step decides:** use a plain `for` loop with `if`/`else` when each step does a lookup or a choice. Keep `map`, `filter`, and `reduce(into:)` for steps that are one short expression. They compile to the same work, so pick by how each step reads, not by speed.
- **Don't optimize what isn't slow:** keep the readable form unless a measured cost says otherwise. Note a known ceiling in a comment instead (for example, a linear search over a field's subkeys, which stay small).
