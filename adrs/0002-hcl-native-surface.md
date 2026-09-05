# ADR 0002: HCL-Native Surface and Reference Resolution (v0.2.0)

## Status

Superseded by [ADR 0003](0003-bounded-context-contracts.md) for event and
field ownership. The HCL-native syntax decisions remain accepted.

## Context

v0.1.0 was a mechanical port of the upstream JSON schema. It read as "JSON in
HCL clothing": `type = "COMMAND"` restated the block keyword, `example` values
were stringified (`"1"`, `"null"`), relationships were denormalized
`dependency` blocks that repeated the target's title and kind on both
endpoints, and ordering integers (`index`, `spec_row`) were written by hand.
The upstream schema enforces neither id uniqueness nor referential integrity,
so the ported model was also weaker than it could be. Because the validator is
purely structural HCL — no JSON marshalling — the surface can be redesigned and
strengthened at low cost.

## Decision

v0.2.0 is a clean break with no dual-syntax support. The `.em.hcl` file is the
source of truth, so data that is derivable is dropped rather than preserved for
JSON round-tripping:

- An element's kind is its block keyword; the `type` attribute is removed.
- Relationships are `inbound`/`outbound` reference-list attributes. Each edge is
  written once; the target's title and kind are recovered by resolving the id.
- `field.example` values are native HCL literals, checked for consistency with
  the field's `type`.
- `given`/`when`/`then` steps are unlabeled and positional; `given`/`when`
  infer their type; `then` states it; step `linkedId` becomes `ref`.
- `index`, `spec_row`, and `sliceName` are derived and removed.

The validator now enforces two invariants the upstream schema omits: element
ids are unique across the document, and `inbound`/`outbound`/`linked_id`
references must resolve to a declared element or slice. A step's `ref` is not
required to resolve, because `given` prerequisites frequently originate in
slices outside the document under validation.

## Consequences

- Hand authoring is markedly terser and less error-prone; the pet-management
  model roughly halves in size.
- The model is a checkable graph: dangling references, duplicate ids, and
  wrong-typed examples are reported with source locations.
- Cross-file resolution, formatting, and JSON conversion remain out of scope.
- The `dependency` block, element `type` attribute, and the derived attributes
  are no longer part of the language; ADR 0001's opaque-reference stance no
  longer applies.
