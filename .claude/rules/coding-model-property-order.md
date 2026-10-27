---
paths:
  - "ProfilePal/Models/**/*.swift"
---

# Property ordering for profile coding models

Applies only to types that encode/decode mobileconfigs or profile manifests. Use `ManifestField` as the reference.

- Split properties into `// MARK: - Apple-defined keys` then `// MARK: - Extended keys` (ProfileManifests `pfm_` extensions). Never mix the two.
- Within each section, order by purpose, not alphabetically:
  - **Apple-defined:** identity (name, title, description, type) → value and constraints (default, allowed values, min/max, format) → nesting (subkeys, repetition) → requirement rules (require, conditionals, exclusions) → scope (targets).
  - **Extended:** display help (placeholder, titles, unit, note, documentation URL) → device requirements (sensitive, supervised, user approved) → platform versions.
- Paired bounds go min before max (`rangeMin`, `rangeMax`).
- Platform versions are grouped per platform (iOS, macOS, tvOS, …), each in lifecycle order: min, deprecated, max.
- `CodingKeys` lists cases in the same order as the properties, with a blank line between the two sections.
