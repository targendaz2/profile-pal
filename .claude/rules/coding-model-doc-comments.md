---
paths:
  - "ProfilePal/Models/**/*.swift"
---

# Doc comments for profile coding models

Applies only to types that encode/decode mobileconfigs or profile manifests. Every property gets a `///` comment. Use `ManifestField` as the reference.

- **Summary line:** one short sentence describing what the property holds.
  - Booleans start with "Whether…" (e.g. "Whether the device must be supervised for the field to work.").
  - Everything else starts with "The…" or "A…". Never "Indicates…".
- **Subject:** refer to the thing being described consistently as "the field" in manifest types, or "the payload" in payload types. Not "key" or "this field".
- **Layout:** summary, then an optional short discussion paragraph, then the callout last, with blank `///` lines between them.
- **Callouts:** `- Important:` for constraints that break the profile if ignored (type must match, counts must match); `- Note:` for platform caveats or cross-references.
- **References:** name other properties by their Swift name in backticks (`placeholder`), never the raw `pfm_` key.
- **Brevity:** one line where possible. Keep only guidance that changes how the value is set; drop restatements of the property name.
- **Parallel properties use parallel wording:** e.g. "The iOS version that started supporting the field." / "…deprecated the field." / "…stopped supporting the field."
