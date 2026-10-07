# Event Modeling HCL Specification v0.4.0

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

```text
eventmodeling-hcl validate [--profile workshop|valid|strict] <model.em.hcl | folder>
eventmodeling-hcl fmt [-w] <model.em.hcl>
```

## Language Principles

- A block kind is the concept; labels are lower-snake-case identity.
- Model order is file name order, then source order inside each file. Blocks and
  scenario steps are never reordered, except that chapters set the workflow
  order of a folder model.
- Bounded contexts own events, aggregates, and field types.
- Relationships are unquoted HCL traversals. Each flow edge has one canonical
  spelling.
- Unknown syntax, unresolved references, and wrong-kind references are errors.
- Uncertainty is a `hotspot`, not a weakened contract.

## Grammar

```text
document        = { catalog | workshop_item | workflow }
catalog         = bounded_context | actor | team | system
workshop_item   = chapter | hotspot
workflow        = state_change | state_view | automation | translation
bounded_context = 'bounded_context' id '{' aggregate | field_type | event | attribute '}'
workflow_child  = command | readmodel | screen | processor | screen_image | table | scenario
scenario        = 'scenario' id '{' given | when | then | comment | attribute '}'
field           = 'field' name '{' attribute | subfield '}'
field_list      = 'fields' '=' '[' field_type_ref { ',' field_type_ref } ']'
subfield        = 'subfield' name '{' attribute | subfield '}'
```

All labels are quoted HCL labels. HCL comments are non-semantic; use a
`comment { description = ... }` block for a scenario note.

## Multi-file Models

A model path is either a file or a folder. A file is a one-file model, as in
v0.3.0. A folder is a folder model.

- A folder model uses every regular file directly in the folder whose name ends
  in `.em.hcl` and does not start with `.`. A symlink to a file counts.
  Subfolders and other files are ignored.
- Member files are sorted by file name, byte by byte, without the locale. Model
  order is file order, then source order inside each file.
- A folder with no member file is error `EM001`.
- A folder with exactly one member file behaves exactly like that file. The
  chapter and ordering rules below apply only to models with two or more files.
- The model is the union of the top-level blocks of all files. References
  resolve across files, and every check runs on the whole model. Each file must
  parse on its own, and a syntax error names the file it is in.
- The same top-level ID in two files is error `EM002`. The ID spaces are those
  of a single document. The detail names the first declaration as
  `file:line:column`. A block never spans files, so a `bounded_context` with its
  events, aggregates, and field types is declared in one file.
- All `chapter` blocks of a multi-file model must be in one file. Chapters in
  several files are error `EM013`. A workflow listed by two chapters is error
  `EM014`.
- The workflow order of a multi-file model is the order of the chapters in
  their file, then the order of each chapter's `workflows` list. The contiguous
  source-order chapter rule (`EM006`) does not apply.
- A workflow in no chapter is judgment diagnostic `EM407`. Such workflows
  follow all chaptered workflows, in model order. This includes a multi-file
  model with no chapters.
- `fmt` formats one file and never moves blocks between files.

The language has no `include` or `import` block, no subfolder membership, no
module or name space, and no way to split one block across files.

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
The workflow-qualified form is used by `hotspot.on`.

Reference lists are native HCL lists:

```hcl
to = [event.clinic.pet_registered]
```

Interpolation, functions, variables, dynamic indexes, and computed references
are invalid.

## Titles

`title` is optional for bounded contexts, events, workflows, workflow elements,
tables, scenarios, actors, owners, chapters, and screen images. When omitted,
the typed model derives it by title-casing the label: `pet_registered` becomes
`Pet Registered`. An explicit title wins. The formatter never writes a derived
title back into source. `readmodel.question`, `actor.auth_required`, hotspot
`question`, and chapter `workflows` retain their required status. A `field_type`
declaration retains its required built-in `type`; a plain `field` block may omit
`type` and infer it (see Domain Catalog and Fields).

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

`type` is optional on a plain `field` block. When omitted, the effective type is
the `field_type` resolved from the block's own name: a field owned by a
`bounded_context` (inside an `event` or nested as a `subfield`) resolves against
that context, and a field owned by a workflow element, table, or scenario step
resolves the unique document-wide `field_type` of that name. Absence, or a name
declared by more than one context, is an error; write an explicit `type` when
the field name differs from the field-type name or the name is ambiguous. A
`field_type` declaration still requires an explicit built-in `type`.

A `fields` list is a shorthand for several typed fields at once:

```hcl
fields = [field_type.clinic.pet_id, field_type.clinic.pet_name]
```

Each entry adds one field named for the traversal's last segment. The list takes
no per-field overrides; use a `field` block for those. When both appear, list
entries come first, then `field` blocks in source order, and a name may not
repeat across the two. The object form `fields = { ... }` is not supported.

Built-in types are `String`, `Boolean`, `Double`, `Decimal`, `Long`, `Custom`,
`Date`, `DateTime`, `UUID`, and `Int`. `cardinality` is `Single` or `List`;
field examples are native literals checked against their effective type.

## Workflow Patterns and Canonical Flow

| Workflow | Behavioral blocks | Canonical edge spellings |
| --- | --- | --- |
| `state_change` | `screen`, `command` | `screen.to -> command`; `command.to -> event` |
| `state_view` | `readmodel`, `screen` | `event -> readmodel.from`; `readmodel.to -> screen` |
| `automation` | `readmodel`, `processor`, `command` | `event -> readmodel.from` or `processor.from`; `readmodel.to -> processor`; `processor.to -> command`; `command.to -> event` |
| `translation` | `readmodel`, `processor`, `command` | same as automation; at least one consumed event is external |

The reverse spellings are invalid: `command.from = [screen...]`,
`screen.from = [readmodel...]`, `processor.from = [readmodel...]`, and
`command.from = [processor...]`. A translation consumes an event from an
external bounded context; an automation must not.

Commands, read models, screens, and processors may use semantic attributes
such as `aggregate`, `api_endpoint`, `external_trigger`, `triggers`, and
`service`. A read model additionally requires `question`; a screen may name an
`actor`.

Every workflow element — `screen`, `command`, `readmodel`, `processor` — plus
`table` blocks and scenario steps carry `field` blocks and the `fields` list
with the same syntax and semantics as an `event`. A screen has no enclosing
context, so its shorthand fields resolve their `field_type` by unique
document-wide name.

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
| automation/translation | event or readmodel | processor or command | event or error | exactly one `when`, one or more `then` |

`query` is removed. A State View describes `GIVEN event -> THEN read model`:

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
`chapter` names a non-empty list of workflows. In a one-file model the list is
contiguous in source order. This keeps chapters as lightweight facilitation
structure rather than introducing a separate hierarchy. In a folder model the
chapters live in one file and set the workflow order (see Multi-file Models).
`hotspot` records an open or resolved question and may attach to a catalog item,
workflow, owner, actor, or qualified element.

Workflow status is `created`, `planned`, `assigned`, `in_progress`, `review`,
`blocked`, `done`, or `informational`; hotspot status is `open` or `resolved`.

## Diagnostics and Profiles

Diagnostics have stable `EMxxx` codes: `EM0xx` structural, `EM1xx` reference
resolution, `EM2xx` flow, `EM3xx` scenarios, and `EM4xx` modeling judgment.
The CLI prints `file:line:column: Severity EMxxx: Summary: Detail`. A
diagnostic that points at source names the file of that source. In a folder
model the file name is the folder path joined with the file name.

Two structural errors belong to folder models: `EM013` (chapters in several
files) and `EM014` (workflow in several chapters). `EM407` (workflow outside
every chapter) is a judgment diagnostic for folder models.

`valid` is the default and keeps judgment diagnostics as warnings. `workshop`
makes all judgment diagnostics informational. `strict` escalates an unreasoned
command (`EM404`), an open hotspot (`EM406`), and a workflow outside every
chapter (`EM407`) to errors. Bed, left-chair, right-chair, and shelf smells
remain non-blocking judgment signals in every profile.

## Typed IR and Formatting

Validation remains the diagnostic boundary because HCL carries precise source
ranges. A conforming loader first validates and only decodes a clean model into
a normalized typed IR with effective titles, semantic and
presentation fields, ordered workflows/scenarios, and one `Edges` list whose
entries always run source to target. Downstream tools consume this model rather
than raw HCL.

The IR `Workflows` list is in source order for a one-file model. For a
multi-file model it is the chapter order followed by the unchaptered workflows
in model order. Catalog items, chapters, and hotspots follow model order.
Downstream output follows `Workflows`.

`fmt` formats one file. It canonicalizes whitespace and attribute order while
preserving block and scenario order and traversal expressions. Its attribute
order is metadata, ownership/status, semantic configuration, the `fields` list,
relationships (`from`, `to`), then nested blocks. Formatting is idempotent.

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

This language does not define cross-folder references, modules, JSON
conversion, context maps, or inferred causality.
