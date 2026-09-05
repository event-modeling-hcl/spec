# ADR 0005: Canonical Flow and Typed IR

## Status

Accepted for the v0.2.0-rc.1 release candidate.

## Context

The v0.1 language allowed equivalent flow edges from either endpoint and
required a synthetic `query` step in State View scenarios. It also made authors
repeat obvious titles and gave downstream consumers only raw HCL plus diagnostics.
Those equivalent spellings make human and LLM-produced models needlessly
non-deterministic.

## Decision

v0.2 is a hard break from v0.1:

- Each flow edge has one source-oriented canonical form. Reverse forms are
  validation errors.
- State Views use `given { event = ... }` followed by `then { readmodel = ... }`.
  They require at least one given event and have no `when` or `query`.
- Titles are optional and are derived from labels in the typed model only.
- Validation continues directly on HCL for precise diagnostics. `model.Load`
  validates first, then decodes clean input into a normalized typed IR.
- The IR contains effective titles and one source-to-target edge list, and
  separates semantic attributes from presentation metadata.

## Consequences

Models have one canonical relationship spelling and downstream tools do not
need to inspect raw `from` versus `to` source. Existing v0.1 models require
migration. The formatter canonicalizes surface layout but does not synthesize
derived titles or reorder semantic blocks.
