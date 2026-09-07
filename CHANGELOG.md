# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [v0.3.0] - 2026-09-07

v0.3.0 is an additive revision. A `field` block may omit `type` and infer the
same-named `field_type`, and a `fields` list declares several typed fields at
once. Every v0.2.0 document stays valid.

### Added

- Field shorthand (RFC 0001): a `field` block may omit `type` and infer the
  same-named `field_type`, resolved in the owning `bounded_context` for event
  and subfield fields and by unique document-wide name for workflow-element
  fields.
- `fields = [field_type.<...>]` list shorthand on events, workflow elements,
  tables, and scenario steps.
- Normative statement that `screen`, `command`, `readmodel`, `processor`,
  `table`, and scenario steps carry `field` blocks and the `fields` list.

### Changed

- `field.type` is optional on a plain `field` block; a `field_type` declaration
  still requires an explicit built-in `type`.
- The formatter orders the `fields` list with the semantic group, before `from`
  and `to`.

## [v0.2.0] - 2026-09-05

v0.2.0 is a breaking redesign for native HCL authoring. Models written for v0.1.0
were not compatible.

### Added

- Context-owned `aggregate`, `field_type`, and canonical `event` contracts.
- Direct `state_change`, `state_view`, `automation`, and `translation`
  workflow blocks.
- Typed HCL traversal references with scope, kind, and resolution checks.
- Native workflow-local `scenario` blocks with pattern-specific
  Given/When/Then targets.
- Reusable top-level actors, teams, and systems; screen actor references and
  bounded-context/workflow ownership.
- Contiguous `chapter` ranges and attachable `hotspot` questions.
- Complete workflow statuses from the Event Modeling cheat sheet.
- Warning diagnostics for commands without a visible reason and the bed, left
  chair, right chair, and shelf modeling smells.
- Explicit read-model questions and external-context translation validation.
- Stable `EMxxx` diagnostic codes and workshop, valid, and strict validation
  profiles.
- `fmt` command with idempotent HCL whitespace and canonical attribute ordering.
- `internal/model.Load`, a validation-gated typed IR with effective titles,
  normalized source-to-target edges, and semantic/presentation separation.
- Canonical flow and typed IR ADR, plus migration instructions.

### Changed

- Block labels use lower snake case so every identity is traversal-safe.
- Source order replaces explicit slice and scenario ordering attributes.
- Workflow element IDs are scoped to their owning workflow.
- A single `field` block accepts either a built-in type string or a reusable
  `field_type` traversal.
- Flows use `from` and `to`; event participation is derived from these links
  and scenario targets.
- Native HCL examples are checked against their effective field type and
  cardinality.
- All shipped examples now use the v0.2.0 syntax.
- Flow edges have one canonical spelling; reverse forms fail validation.
- State View scenarios use one or more event `given` steps followed by `then`
  read-model steps, with no `when`.
- Titles are optional and derived from labels in the typed IR when absent.

### Removed

- Generic `slice` blocks, `slice_type`, and redundant element `type` values.
- Slice-local event declarations and transitional `event_ref` blocks.
- Transitional `field_ref`, `inbound`, and `outbound` constructs.
- Legacy `specification`, `linked_id`, and step-type bookkeeping.
- Derived `index`, `spec_row`, and `slice_name` attributes.
- The unused vendored JSON schema and golden JSON reference fixture.
- Reverse `command.from`, `screen.from`, `processor.from` (from read models),
  and processor-to-command `command.from` flow spellings.
- The `query` scenario target.

## [v0.1.0] - 2026-09-02

- Initial native HCL Event Modeling Specification release.
- Strict `eventmodeling-hcl validate <model.em.hcl>` validator with
  source-located diagnostics.
- Go 1.25+ support and Linux, macOS, and Windows release archives.
- Slice-local events and a one-to-one representation of the upstream JSON
  schema.
