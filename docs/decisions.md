# Decisions

A log of product and engineering decisions, newest first. Add a row when a decision is made, deferred, or reversed; a reversal gets its own row rather than an edit to the old one. Undecided questions stay in the doc that raised them (such as the open decisions in [remaining-tests.md](remaining-tests.md)) until they're settled here.

| Date | Decision | Why | Where it applies |
| --- | --- | --- | --- |
| 2026-11-02 | **Manifests are XML plists only in v1.** Binary manifest support, and binary-format manifest tests, are deferred to v2. | Keeps v1 scope to the format ProfileManifests ships. | [remaining-tests.md](remaining-tests.md), Deferred to v2 |
| 2026-11-01 | **Unit tests use described Given / When / Then comments,** one concept per line, minimal `func` names with context in the `@Test` display name. | Tests read as specifications, and reports show the display names. | `.claude/rules/testing-unit-test-style.md` |
| 2026-11-01 | **Fixtures are copied by one Copy Files phase per subject folder**, into `Resources/Fixtures/<Subject>/`, instead of the Resources phase. | The Resources phase flattens folders into one namespace and may process plists. Copy Files keeps the folder and copies files byte for byte. | `.claude/rules/testing-plist-fixtures.md` |
| 2026-11-01 | **Tests read plists from real fixture files**, never inline XML strings. | Fixtures mirror real manifest files and keep tag types such as `<real>` and `<integer>` visible. | `.claude/rules/testing-plist-fixtures.md` |
| 2026-10-27 | **The ProfileManifests spec is the source of truth for models.** No undocumented keys or enum cases, and no derived logic that fixes spec quirks. | Models mirror the documented format; spec ambiguity is flagged as deferred work instead. | `CLAUDE.md`, Rules for model code |
