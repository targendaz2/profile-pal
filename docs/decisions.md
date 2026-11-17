# Decisions

A log of decisions that shape the shipped app (its scope, formats, and model behavior), newest first. A decision that becomes a rule (in `CLAUDE.md` or `.claude/rules/`) isn't logged here, since the rule records it. Undecided questions stay in the doc that raised them (such as the open decisions in [remaining-tests.md](remaining-tests.md)) until they're settled. Add a row when a decision is made, deferred, or reversed; a reversal gets its own row rather than an edit to the old one.

| Date | Decision | Why | Where it applies |
| --- | --- | --- | --- |
| 2026-11-16 | **Nested values are coerced against the field's schema.** `PlistValue.coerced(to: ManifestField)` recurses into arrays (via the first subkey) and dictionaries (via the subkey with the same name). Keeping `<real>` and `<integer>` apart at decode time is deferred unless coercion keeps causing bugs. | The field type alone can't say what an array's items are; the subkeys can. | `PlistValue.coerced(to:)` |
| 2026-11-02 | **Manifests are XML plists only in v1.** Binary manifest support, and binary-format manifest tests, are deferred to v2. | Keeps v1 scope to the format ProfileManifests ships. | [remaining-tests.md](remaining-tests.md), Deferred to v2 |
