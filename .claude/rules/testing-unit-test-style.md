---
paths:
  - "ProfileManifestKitTests/**/*.swift"
---

# Unit test style

Applies to every Swift Testing unit test. Use `PlistValueTests.parseBool` as the reference.

- **Structure:** every test body is split into `// Given`, `// When`, and `// Then` sections, in that order, each followed by its code.
- **Say what, not just which step:** each section comment states what's given, what happens, or what's expected (e.g. `// When the value is decoded as a PlistValue`), never a bare `// Given`.
- **One thing per line:** each comment line describes exactly one concept. Add another concept on an extra line starting with `// And` (all apply) or `// Or` (alternatives), which also describes one concept.
  - Variants of the same concept, such as the values a parameterized test runs over, stay on one line (`a <true/> or <false/> tag`).
  - So do details describing that one thing, such as a value's contents (`an <array> of a mixed-type <dict> and an empty <dict>`), not separate `// And` lines.
  - Split only when the concepts are distinct:

    ```swift
    // Given a value decoded as .int
    // And a field whose type is real
    ```
- **Naming:** keep the function name minimal (`parseBool`). Put the context in the `@Test` display name, which is what test reports show.
- **Layout:** `@Test(...)` sits on its own line(s), with `func` on the line below, never `@Test func` on one line.

```swift
@Test(
    "Parses bool values correctly",
    arguments: zip(["bool-false", "bool-true"], [false, true]),
)
func parseBool(fileName: String, expected: Bool) async throws {
    // Given a plist whose value is a <true/> or <false/> tag
    let data = try fixtureData(named: fileName)

    // When the value is decoded as a PlistValue
    let value = try decodeValue(from: data)

    // Then it's a .bool holding the tag's value
    #expect(value == .bool(expected))
}
```
