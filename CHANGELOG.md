# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Proposals

- [RFC 0003](rfcs/0003-hotspot-resolution.md) proposes an optional hotspot
  `resolution` string, independent of status, to preserve answers and reopened
  decisions. It is not part of the released language.

## [v0.5.0] - 2026-10-30

v0.5.0 is a breaking revision (RFC 0004, Uncoupled Authoring Controls). Each
authoring concern has its own control. A v0.4.0 model does not load under
v0.5.0 rules; `migrate` converts it without changing its meaning.

### Added

- Required top-level `board { workflows = [...] }` block. It is the only
  source of story order. A workflow that the board omits is off-board: it is
  valid, has no diagnostic, and appears in the IR off-board set in ID order.
- `EM015` for a missing or repeated `board` block and `EM016` for a workflow
  that the board lists twice. Both are errors in every profile.
- IR edges whose source is a catalog event carry the `external` value of the
  event's context. A translation is an automation with an external edge.
- `migrate [-w]` converts a v0.4.0 model: it writes the board in the old
  effective order, explicit field types, explicit titles, and `automation` for
  `translation`.
- A complete diagnostic registry in the specification, with definitions of the
  bed, left-chair, right-chair, and shelf signals.
- [Migration guide](guides/migrating-v0.4.md) for v0.4.0 models.

### Changed

- Every `field` and `subfield` requires `type`. A missing type is `EM009` in
  every profile. Name inference is removed.
- Titles are literal text. An omitted title is absent in the IR and is never
  derived from the label.
- Chapters are membership sets. Their list order has no meaning, they can live
  in any member file, and a repeated entry is `EM002`. `EM014` applies to every
  model.
- File layout has no meaning. One-file and folder models use identical rules.
  The IR orders catalog items, chapters, hotspots, workflow elements, and
  scenarios by ID, and workflows by the board.
- An `automation` may consume external events.
- The judgment profile assigns severity only. A model without core errors
  always yields the typed IR; a strict-profile error rejects policy and still
  makes `validate` fail.
- Clarified hotspot status semantics: omission means `open`, and only open
  hotspots emit `EM406`. Resolution preserves the question and attachment.

### Removed

- The `translation` workflow keyword.
- `EM006` (chapter source-order range), `EM011` and `EM012` (translation and
  automation externality), `EM013` (chapters in several files), and `EM407`
  (workflow outside every chapter). These codes are never reassigned.

### Fixed

- Current tooling instructions use the shipped `emhcl` executable.
- Clarified that an explicit empty title differs from omission, and that
  migration rejects the retired v0.4.0 chapter-rule violations.
- Corrected RFC 0004's independence assessment: selected authoring controls
  are locally diagonal; semantic reference and validation dependencies remain
  decoupled. Regrouping requirements is not a global independence proof.

## [v0.4.0] - 2026-10-07

v0.4.0 is an additive revision. A model can be a folder of `.em.hcl` files.
Every v0.3.0 document stays valid and keeps its meaning.

### Added

- Folder models (RFC 0002): a model path can be a folder. Every `.em.hcl` file
  directly in the folder is part of the model. Files are sorted by name, and
  references and IDs are global across files.
- `EM013` for chapters declared in several files of a multi-file model.
- `EM014` for a workflow listed by several chapters in a multi-file model.
- `EM407` for a workflow outside every chapter in a multi-file model. It is
  info in `workshop`, a warning in `valid`, and an error in `strict`.
- New `Multi-file Models` section with the rules for folder members, merging,
  identity, chapters, and ordering.

### Changed

- Model order is file name order, then source order inside each file.
- `EM002` names the first declaration as `file:line:column`.
- The contiguous source-order chapter rule (`EM006`) applies to one-file models
  only. In a multi-file model, chapters set the workflow order.
- Diagnostics name the file of the source they point at.
- The typed IR orders `Workflows` by chapters, then by model order for
  unchaptered workflows, in a multi-file model.
- The specification no longer says that a model is one document. It still does
  not define cross-folder references, modules, JSON conversion, context maps,
  or inferred causality.

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
