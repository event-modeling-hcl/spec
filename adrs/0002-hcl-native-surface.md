# ADR 0002: Native Event Modeling HCL Language

## Status

Accepted for v0.2.0.

## Context

v0.1.0 mechanically mirrored an upstream JSON schema. That made `.em.hcl`
verbose, allowed equivalent flow spellings, kept event contracts inside slices,
and gave tools only raw HCL. Event Modeling needs a compact, checkable language
that keeps domain contracts, workflows, and workshop decisions explicit.

## Decision

v0.2 is a clean break with no compatibility syntax:

- HCL block kinds represent Event Modeling concepts. Bounded contexts own
  aggregates, reusable field types, and canonical event contracts; workflows
  are first-class State Change, State View, Automation, or Translation blocks.
- Relationships use typed, unquoted HCL traversals. Every flow edge has one
  source-oriented spelling; reverse forms are errors.
- Fields use native HCL literals and either a built-in type or a context-owned
  `field_type`. Labels are lower snake case identities, source order is model
  order, and titles are optional derived presentation values.
- Scenarios are workflow-local Given/When/Then steps with pattern-specific
  target rules. State Views have one or more `given` events and `then` a read
  model; they have no `when` or synthetic `query` step.
- Actors, ownership, chapters, and hotspots preserve workshop information.
  Objective rules are errors; judgment-dependent smells remain diagnostics.
- Validation runs against HCL for precise source ranges. Clean input decodes to
  a normalized typed IR with effective titles and one source-to-target edge
  list; formatting canonicalizes layout without changing semantic order.

## Consequences

- Models are concise, canonical, and directly express the four Event Modeling
  patterns.
- The validator can resolve and kind-check relationships while retaining a
  clear boundary for human judgment.
- Downstream renderers and generators consume the typed IR rather than raw HCL.
- v0.1 models require migration; the normative specification defines the
  complete syntax and compatibility rules.
