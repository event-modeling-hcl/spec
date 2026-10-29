# RFC Process

Use an RFC for every language change that affects valid source, validation,
canonical formatting, the typed IR, or compatibility.

## Proposal Format

Create `rfcs/NNNN-short-title.md` with these sections:

1. Summary and motivation.
2. Proposed normative language changes, including syntax and semantics.
3. Compatibility and migration from the current version.
4. Validation, formatter, and typed-IR impact.
5. Examples and acceptance tests.
6. Alternatives and unresolved questions.

## Lifecycle

RFCs begin as proposed. Once accepted, their normative content is merged into
`eventmodeling.hclspec.md`, the changelog is updated, and the implementation
repository receives matching validator, formatter, IR, example, and test
changes. Rejected and superseded RFCs remain in the repository as history.

The specification repository is the language authority. An implementation must
not introduce undocumented language behavior.

## Proposals

- [RFC 0003: Hotspot Resolution](0003-hotspot-resolution.md) — proposed optional
  answer text, independent of the existing open/resolved status.

## Accepted

- [RFC 0004: Uncoupled Authoring Controls](0004-uncoupled-authoring-controls.md)
  — accepted in v0.5.0: explicit field bindings, a partial board, chapter
  membership sets, layout-free files, literal titles, policy separate from the
  IR, and `translation` merged into `automation`.
