# ADR 0003: Catalog Events and Ubiquitous Language in Bounded Contexts

## Status

Accepted.

## Context

The previous HCL surface kept events inside workflow slices. That matched the
upstream JSON topology, but it made event contracts look owned by the slice
that first described them. In implementation repositories, events often live
in a shared API or contracts module and are reused by state-change, state-view,
automation, and translation workflows.

Events are the interface between workflows and frequently between bounded
contexts. Keeping them inside one vertical slice makes consumers appear coupled
to that producer slice. Repeated inline fields also leave ubiquitous-language
terms such as `Pet`, `Label`, or `DSL` without a canonical definition.

## Decision

HCL introduces top-level `bounded_context` blocks. A bounded context owns:

- canonical `event` contracts;
- reusable `field_type` definitions for ubiquitous-language data concepts;
- `aggregate` declarations.

Workflow blocks are direct top-level blocks: `state_change`, `state_view`,
`automation`, and `translation`. They no longer declare local events and no
longer carry `slice_type`. Workflows reference catalog events directly from
typed flow and scenario attributes. A single `field` block either names a
built-in type or refers to a context-owned `field_type`.

References resolve within one `.em.hcl` document for now. Context maps,
multi-file loading, conversion tooling, and cross-file references remain
future decisions.

## Consequences

- Event contracts have one authoritative owner and can be reused without
  coupling consumers to a producer workflow.
- Field types make ubiquitous-language terms explicit and reusable.
- Aggregate references become checkable instead of free-form strings.
- Direct workflow block kinds remove duplicated `slice_type` attributes.
- The language is less mechanically aligned with the upstream JSON schema and
  requires a breaking migration from slice-local events.
- The model topology can support future context maps without another event
  ownership change.
