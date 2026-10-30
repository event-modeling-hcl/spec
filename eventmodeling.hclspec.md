# Event Modeling HCL Specification v0.5.0

## Status and Scope

This is the normative specification for native Event Modeling HCL. A model is
one `.em.hcl` file or a folder of `.em.hcl` files. The upstream [Event Modeling
Specification](https://github.com/dilgerma/event-modeling-spec) remains the
domain reference.

v0.2.0 is a breaking revision from v0.1.0 that makes flow and State View
scenarios canonical, makes human-facing titles optional, adds stable diagnostics
and validation profiles, and defines a typed semantic model for downstream tools.

v0.3.0 is additive: a `field` `type` is optional and infers the same-named
`field_type`, and a `fields` list declares several typed fields at once. Every
v0.2.0 document remains valid.

v0.4.0 is additive: a model can be a folder of `.em.hcl` files (RFC 0002). Every
v0.3.0 document remains valid and keeps its meaning.

v0.5.0 is a breaking revision (RFC 0004). It gives each authoring concern its
own control: a `board` block sets the story order, chapters are membership
sets, every field states its type, titles are never derived, file layout has no
meaning, the `translation` keyword merges into `automation`, and the judgment
profile never decides whether tools receive a model. Migrate a v0.4.0 model
with `migrate` (see Compatibility).

```text
emhcl validate [--profile workshop|valid|strict] <model.em.hcl | folder>
emhcl fmt [-w] <model.em.hcl>
emhcl migrate [-w] <model.em.hcl | folder>
```

## Language Principles

- A block kind is the concept; labels are lower-snake-case identity.
- Each concern has one explicit control. No control supplies a default for
  another concern.
- The `board` block is the only source of story order. Top-level block
  position, file names, and chapters never order the model. Scenario steps,
  field declarations, and explicit reference lists keep their source order.
- Bounded contexts own events, aggregates, and field types. A context alone
  states whether its contracts come from outside the modeled system.
- Relationships are unquoted HCL traversals. Each flow edge has one canonical
  spelling.
- Unknown syntax, unresolved references, and wrong-kind references are errors.
- Uncertainty is a `hotspot`, not a weakened contract.

## Grammar

```text
document        = { catalog | story | workshop_item | workflow }
catalog         = bounded_context | actor | team | system
story           = board
workshop_item   = chapter | hotspot
workflow        = state_change | state_view | automation
board           = 'board' '{' 'workflows' '=' '[' [ workflow_ref { ',' workflow_ref } ] ']' '}'
bounded_context = 'bounded_context' id '{' aggregate | field_type | event | attribute '}'
workflow_child  = command | readmodel | screen | processor | screen_image | table | scenario
scenario        = 'scenario' id '{' given | when | then | comment | attribute '}'
field           = 'field' name '{' 'type' '=' type_ref { attribute | subfield } '}'
field_list      = 'fields' '=' '[' field_type_ref { ',' field_type_ref } ']'
subfield        = 'subfield' name '{' 'type' '=' type_ref { attribute | subfield } '}'
type_ref        = built_in_type_string | field_type_ref
```

All labels are quoted HCL labels; `board` has no label. HCL comments are
non-semantic; use a `comment { description = ... }` block for a scenario note.

## Model Files

A model path is either a file or a folder. Both use identical semantic rules.

- A folder model uses every regular file directly in the folder whose name ends
  in `.em.hcl` and does not start with `.`. A symlink to a file counts.
  Subfolders and other files are ignored. File discovery does not deduplicate
  declarations by physical file identity.
- A folder with no member file is error `EM001`.
- The model is the union of the top-level blocks of all files. References
  resolve across files, and every check runs on the whole model. Each file must
  parse on its own, and a syntax error names the file it is in.
- The same top-level ID in two files is error `EM002`. The ID spaces are those
  of a single document. The detail names the first declaration as
  `file:line:column`, where files are compared byte by byte. A block never
  spans files, so a `bounded_context` with its events, aggregates, and field
  types is declared in one file.
- File names select discovery and diagnostic locations, not model order.
  Moving whole blocks between member files, or renaming members, preserves the
  typed model and the set of diagnostic codes and severities. Only source
  locations change.
- `fmt` formats one file and never moves blocks between files.

The language has no `include` or `import` block, no subfolder membership, no
module or name space, and no way to split one block across files.

## Board

A model has exactly one top-level `board` block. A missing or repeated board is
error `EM015`, even when two lists match. Its one required attribute,
`workflows`, is a list of `workflow.<id>` traversals:

```hcl
board {
  workflows = [workflow.register_pet, workflow.pet_directory]
}
```

Each entry names an existing workflow. A repeated entry is error `EM016`. The
list may omit workflows, and it may be empty. The list is the complete story
sequence for diagrams and other story output; no fallback uses file names,
block positions, chapter lists, or IDs.

A workflow that the list omits is off-board. It is part of the model and passes
every rule. The typed IR lists it in an off-board set in byte order of workflow
IDs. No profile reports an off-board workflow. A tool may list off-board
workflows separately but must not insert them into the story sequence. Adding a
workflow therefore needs no board edit.

A board edit changes only the story sequence. It does not change edges,
scenarios, chapter membership, titles, or files. The loader never repairs the
list.

## References and Identity

References are HCL traversals, not strings. The three scopes are:

| Scope | Form | Example |
| --- | --- | --- |
| Domain/catalog | qualified, or local inside its context where allowed | `event.clinic.pet_registered`, `aggregate.pet` |
| Workflow-local | local element | `command.register_pet` |
| Workflow-qualified | globally attached workflow element | `command.register_pet.submit` |

Document-wide catalog references include `bounded_context.<id>`, `actor.<id>`,
`team.<id>`, `system.<id>`, and `workflow.<id>`. Events, aggregates, and field
types are qualified as `<kind>.<context>.<id>` outside their owning context.
The workflow-qualified form is used by `hotspot.on`. The board and chapters use
`workflow.<id>`.

Reference lists are native HCL lists:

```hcl
to = [event.clinic.pet_registered]
```

Interpolation, functions, variables, dynamic indexes, and computed references
are invalid. Resolution is an exact lookup: a reference never searches for a
name, and adding an unreferenced declaration never changes an existing
resolution. Renaming an identity requires updating every reference to it,
including board and chapter entries.

## Titles

`title` is optional for bounded contexts, aggregates, events, workflows,
workflow elements, tables, scenarios, actors, owners, chapters, and screen
images. A title is a literal string. When omitted, the title is absent: the
typed model never derives one from the label, and the formatter never writes
one. A consumer shows the identity separately from the optional title. When a
title is absent it may show the identity, but it must not present that
identity as stored title text.
The literal empty string is a present title, not an omitted title. The IR must
preserve that distinction.

`readmodel.question`, `actor.auth_required`, hotspot `question`, board and
chapter `workflows`, and the `type` of every `field_type`, `field`, and
`subfield` are required.

## Domain Catalog and Fields

`bounded_context` owns `aggregate`, `field_type`, and canonical `event` blocks.
An external context (`external = true`) owns contracts outside the modeled
system. `owner` references a bounded context, team, or system.

An event is a past-tense fact. It may declare `aggregate`,
`aggregate_dependencies`, fields, and presentation metadata. A field uses the
canonical block syntax:

```hcl
field "pet_id" {
  type         = field_type.clinic.pet_id
  id_attribute = true
}
```

Every `field` and `subfield` requires `type`, wherever it appears: in events,
workflow elements, tables, scenario steps, and nested subfields. The value is a
built-in type string or a `field_type` traversal: `field_type.<context>.<id>`,
or `field_type.<id>` for a field owned by that same bounded context. Both are
exact lookups. A missing or invalid type is error `EM009`. A `field_type`
declaration requires a built-in `type`.

A `fields` list is a shorthand for several typed fields at once:

```hcl
fields = [field_type.clinic.pet_id, field_type.clinic.pet_name]
```

Each entry adds one field named for the traversal's last segment and typed by
the traversal. The list takes no per-field overrides; use a `field` block for
those. When both appear, list entries come first, then `field` blocks in source
order, and a name may not repeat across the two. The object form
`fields = { ... }` is not supported.

Built-in types are `String`, `Boolean`, `Double`, `Decimal`, `Long`, `Custom`,
`Date`, `DateTime`, `UUID`, and `Int`. `cardinality` is `Single` or `List`;
field examples are native literals checked against their type (`EM010`).

## Workflow Patterns and Canonical Flow

| Workflow | Behavioral blocks | Canonical edge spellings |
| --- | --- | --- |
| `state_change` | `screen`, `command` | `screen.to -> command`; `command.to -> event` |
| `state_view` | `readmodel`, `screen` | `event -> readmodel.from`; `readmodel.to -> screen` |
| `automation` | `readmodel`, `processor`, `command` | `event -> readmodel.from` or `processor.from`; `readmodel.to -> processor`; `processor.to -> command`; `command.to -> event` |

The reverse spellings are invalid: `command.from = [screen...]`,
`screen.from = [readmodel...]`, `processor.from = [readmodel...]`, and
`command.from = [processor...]`.

An `automation` may consume internal events, external events, or both. A
translation is an automation that consumes at least one event from an external
bounded context. The language has no `translation` keyword and no rule that
compares a workflow with the `external` flag. The typed IR marks every edge
whose source is a catalog event with the `external` value of that event's
context; a consumer that shows translation derives it from these marks.

Commands, read models, screens, and processors may use semantic attributes
such as `aggregate`, `api_endpoint`, `external_trigger`, `triggers`, and
`service`. A read model additionally requires `question`; a screen may name an
`actor`.

Every workflow element — `screen`, `command`, `readmodel`, `processor` — plus
`table` blocks and scenario steps carry `field` blocks and the `fields` list
with the same syntax and semantics as an `event`.

`screen_image` and `table` are presentation blocks. A `screen_image` attaches a
rough wireframe or mockup to a workflow through its `url`; a `table` records
illustrative tabular or example data beside a workflow. Neither has flow edges
or changes the typed model's behavior.

## Scenarios

Scenarios stay beside the workflow they specify. Each step has exactly one
typed target; `error` is a literal string.

| Workflow | Given | When | Then | Cardinality |
| --- | --- | --- | --- | --- |
| state change | event | command | event or error | exactly one `when`, one or more `then` |
| state view | event | none | readmodel or error | one or more `given`, zero `when`, one or more `then` |
| automation | event or readmodel | processor or command | event or error | exactly one `when`, one or more `then` |

Scenario rules depend on the workflow keyword and the step target kind, not on
the workflow's edges. A State View describes `GIVEN event -> THEN read model`:

```hcl
scenario "pets_are_listed" {
  given { event = event.pet_management.pet_added }
  then  { readmodel = readmodel.pets }
}
```

## Semantic and Presentation Attributes

The source syntax is unchanged, but the typed IR separates meaning from
presentation. Semantic attributes include `description`, `aggregate`,
`aggregate_dependencies`, `api_endpoint`, `service`, `creates_aggregate`,
`external_trigger`, `triggers`, `question`, and `actor`. Presentation
attributes are `group_id`, `tags`, `sketched`, `prototype`, `list_element`, and
screen-image `url`.

The vocabulary intentionally retains `aggregate_dependencies`,
`technical_attribute`, `id_attribute`, and `external_trigger`: they carry
contract, field, or triggering meaning that cannot reliably be inferred.

## Workshop Notation

`actor`, `team`, and `system` provide reusable ownership and persona records.

`chapter` names a group of workflows. Its required `workflows` list is
non-empty (`EM005`), and each entry names an existing workflow. The list is a
set: its order has no meaning, and a repeated entry is error `EM002`. A
workflow belongs to at most one chapter (`EM014`) and may belong to none
without a diagnostic. Chapters may live in any member file. A chapter may
contain off-board workflows. Chapters never change the board, and the board
never changes chapters. A grouped view may filter the board sequence by chapter
membership; it cannot replace the board sequence.

`hotspot` records an open or resolved question and may attach to a catalog
item, workflow, owner, actor, or qualified element.

Workflow status is `created`, `planned`, `assigned`, `in_progress`, `review`,
`blocked`, `done`, or `informational`; hotspot status is `open` or `resolved`.

Hotspot `status` is optional. Its effective value is `open` when omitted.
An open hotspot emits judgment signal `EM406`; a resolved hotspot does not.
Changing status does not change the hotspot's question or attachment.
Keep resolved hotspots when they preserve useful workshop information.

RFC 0003 proposes a separate `resolution` string to record the answer.
That attribute is not part of v0.5.0; see
[Hotspot Resolution](rfcs/0003-hotspot-resolution.md) for the proposal.

## Diagnostics and Profiles

Diagnostics have stable `EMxxx` codes: `EM0xx` structural, `EM1xx` reference
resolution, `EM2xx` flow, `EM3xx` scenarios, and `EM4xx` modeling judgment.
The CLI prints `file:line:column: Severity EMxxx: Summary: Detail`. A
diagnostic that points at source names the file of that source. In a folder
model the file name is the folder path joined with the file name.

Codes `EM000` to `EM303` are core diagnostics: they are errors in every
profile, and any of them prevents the typed IR. Codes `EM401` to `EM406` are
judgment signals: core rules emit them without a severity, and the selected
profile assigns one.

| Code | Kind | Condition |
| --- | --- | --- |
| `EM000` | core | HCL syntax or schema error before Event Modeling validation, including an unsupported block such as `translation`, an unsupported attribute, or a missing required attribute. |
| `EM001` | core | A model file cannot be read, or a folder has no member file. |
| `EM002` | core | A duplicate identity, or a repeated entry in one chapter. |
| `EM003` | core | A label is not lower snake case. |
| `EM004` | core | A block is not allowed in its workflow kind. |
| `EM005` | core | A chapter lists no workflow. |
| `EM007` | core | An attribute value has the wrong kind. |
| `EM008` | core | An enum attribute has an unknown value. |
| `EM009` | core | A field or subfield has no type or an invalid type, or a `field_type` has no built-in type. |
| `EM010` | core | An example does not match its field type or cardinality. |
| `EM014` | core | A workflow is in several chapters. |
| `EM015` | core | The model has no `board` block, or more than one. |
| `EM016` | core | The board lists a workflow more than once. |
| `EM101` | core | A reference has the wrong form or targets the wrong kind. |
| `EM102` | core | A reference names no declared element. |
| `EM201` | core | A flow edge uses a non-canonical spelling or a target kind the pattern does not allow. |
| `EM301` | core | A scenario has the wrong number of `given`, `when`, or `then` steps for its pattern. |
| `EM302` | core | A scenario step does not set exactly one target. |
| `EM303` | core | A scenario step target kind is not allowed for its pattern and step. |
| `EM401` | judgment | Bed: a screen connects to several commands. |
| `EM402` | judgment | Left chair: a command emits several events. |
| `EM403` | judgment | Right chair: a read model consumes several events. |
| `EM404` | judgment | A command has no reason: no incoming flow, `api_endpoint`, or `external_trigger`. |
| `EM405` | judgment | Shelf: with two or more workflows, one workflow holds every scenario and the others hold none. |
| `EM406` | judgment | A hotspot is open. |

`EM006`, `EM011`, `EM012`, `EM013`, and `EM407` are retired and are never
reassigned.

| Profile | `EM401`–`EM403`, `EM405` | `EM404`, `EM406` |
| --- | --- | --- |
| `workshop` | info | info |
| `valid` (default) | warning | warning |
| `strict` | warning | error |

The result of a load contains two separate facts: core validity and policy
acceptance. A judgment signal with error severity rejects policy; it is not a
core failure. `validate` exits unsuccessfully on either. A tool that renders or
exports still receives the typed IR when only policy rejects, and it reports
the rejection separately.

## Typed IR and Formatting

Validation remains the diagnostic boundary because HCL carries precise source
ranges. A conforming loader runs the core rules first and decodes every model
without core errors into a normalized typed IR, whatever the profile. The IR
holds literal titles (absent when omitted), semantic and presentation fields,
the board sequence, the off-board set, scenarios, and one `Edges` list whose
entries always run source to target. An edge whose source is a catalog event
carries the `external` value of that event's context. Downstream tools consume
this model rather than raw HCL. A loader never publishes a partial model and
never substitutes the result of an earlier load.

The IR `Workflows` list holds the board sequence followed by the off-board
workflows in byte order of their IDs; the board and off-board sets are also
available as ID lists. Downstream story output follows the board sequence.
Actors, owners, contexts and their aggregates, field types, and events,
chapters, hotspots, workflow elements, tables, screen images, and scenarios
are in byte order of their qualified IDs. Chapter membership is in workflow ID
order. Fields, scenario steps, and explicit reference lists keep source order.
The IR therefore does not depend on file names or block placement.

`fmt` formats one file. It canonicalizes whitespace and attribute order while
preserving block and scenario order, list order, and traversal expressions. Its
attribute order is metadata, ownership/status, semantic configuration, the
`fields` list, relationships (`from`, `to`), then nested blocks. It never adds
titles or types and never expands the `fields` list. Formatting is idempotent.

## Compatibility

v0.2 rejects reverse flow forms and `query`, and State View scenarios now need
at least one event `given` and no `when`. Migrate a v0.1 document as one
complete document: normalize labels; move contracts into bounded contexts;
replace generic slices and string relationships with native workflow blocks and
typed traversals; replace legacy specifications with workflow-local scenarios;
write canonical flow forms; and remove redundant titles. Format and validate
the result with the implementation CLI.

v0.3.0 adds only optional syntax; no v0.2.0 document needs changes.

v0.4.0 adds only folder models; no v0.3.0 document needs changes.

v0.5.0 is breaking. A v0.4.0 model does not load under v0.5.0 rules, and a
loader selects one language revision for the whole model. `migrate` reads a
v0.4.0-valid model and rewrites it without changing its meaning:

1. It adds one `board` block that lists every workflow in the v0.4.0 effective
   order, at the start of the file, or of the byte-first member of a folder.
2. It writes the v0.4.0 resolved type of every typeless field and subfield as a
   qualified traversal.
3. It writes every v0.4.0 derived title as an explicit `title`.
4. It keeps chapter lists as written; their order no longer has meaning.
5. It rewrites every `translation` block as `automation`. The old rules
   guarantee that each former translation keeps at least one external edge.

`migrate` stops with diagnostics, and writes nothing, when the input does not
parse, already has a board, has a typeless field that v0.4.0 could not resolve
uniquely, violates the v0.4.0 translation rules, or violates the old chapter
rules (one-file contiguous source order and one chapter file per folder).
It validates its output under v0.5.0 rules. Without `-w` it prints the result;
with `-w` it rewrites the changed files. `EM006`, `EM011`, `EM012`, `EM013`,
and `EM407` disappear from v0.5.0 validation, but migration still rejects
inputs that violate v0.4.0 core rules.

This language does not define cross-folder references, modules, JSON
conversion, context maps, or inferred causality.
