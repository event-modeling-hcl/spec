# Event Modeling HCL Specification

The authoritative specification for Event Modeling HCL v0.3.0, a native HCL
language for expressing Event Modeling workflows as validated source files.

This repository defines the language. The [Go implementation](https://github.com/event-modeling-hcl/eventmodeling-hcl)
provides the `eventmodeling-hcl` validator, formatter, and typed IR that enforce
and consume it.

## Start Here

- [Normative specification](eventmodeling.hclspec.md): grammar, references,
  canonical flow, scenarios, validation, and compatibility.
- [Learning guide](guides/learning-event-modeling-hcl.md): practice-first
  material for learning Event Modeling while authoring `.em.hcl`.
- [Migration guide](guides/migrating-v0.2.md): move an older model to the
  v0.2.0 language surface.
- [Decision records](adrs/README.md): historical language-design decisions.
- [Examples](examples/README.md): complete, independently valid models for the
  four patterns and a combined appointment/weather model.
- [RFC process](rfcs/README.md): how language changes are proposed and adopted.
- [Changelog](CHANGELOG.md): language history.

## Validate an Example

Install the CLI from the implementation repository, then run:

```text
eventmodeling-hcl fmt -w examples/state-change.em.hcl
eventmodeling-hcl validate examples/state-change.em.hcl
```

The specification is licensed under [Apache-2.0](LICENSE). Event Modeling
concepts are informed by the upstream [Event Modeling
Specification](https://github.com/dilgerma/event-modeling-spec) and Martin
Dilger's [Event Modeling Cheat Sheet](https://eventmodelers.ai/cheatsheet/).
