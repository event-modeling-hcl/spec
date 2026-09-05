# Event Modeling HCL Specification v0.2.0 (Draft)

## Status and Scope

This is the normative specification for native Event Modeling HCL. One model is
one `.em.hcl` document. The upstream [Event Modeling
Specification](https://github.com/dilgerma/event-modeling-spec) remains the
domain reference.

v0.2.0 is a breaking revision from v0.1.0 that makes flow and State View scenarios
canonical, makes human-facing titles optional, adds stable diagnostics and
validation profiles, and defines a typed semantic model for downstream tools.

```text
eventmodeling-hcl validate [--profile workshop|valid|strict] <model.em.hcl>
eventmodeling-hcl fmt [-w] <model.em.hcl>
```

## Language Principles

- A block kind is the concept; labels are lower-snake-case identity.
- Source order is model order. Blocks and scenario steps are never reordered.
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
subfield        = 'subfield' name '{' attribute | subfield '}'
```

All labels are quoted HCL labels. HCL comments are non-semantic; use a
`comment { description = ... }` block for a scenario note.

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
title back into source. `readmodel.question`, `actor.auth_required`, field
`type`, hotspot `question`, and chapter `workflows` retain their required
status.

## Domain Catalog and Fields

`bounded_context` owns `aggregate`, `field_type`, and canonical `event` blocks.
An external context (`external = true`) owns contracts outside the modeled
system. `owner` references a bounded context, team, or system.

An event is a past-tense fact. It may declare `aggregate`,
`aggregate_dependencies`, fields, and presentation metadata. A field uses the
one canonical block syntax:

```hcl
field "pet_id" {
  type         = field_type.clinic.pet_id
  id_attribute = true
}
```

`fields = { ... }` is not supported. Built-in types are `String`, `Boolean`,
`Double`, `Decimal`, `Long`, `Custom`, `Date`, `DateTime`, `UUID`, and `Int`.
`cardinality` is `Single` or `List`; field examples are native literals checked
against their effective type.

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
`chapter` names a non-empty, contiguous source-order list of workflows. This
keeps chapters as lightweight facilitation structure rather than introducing a
separate hierarchy. `hotspot` records an open or resolved question and may
attach to a catalog item, workflow, owner, actor, or qualified element.

Workflow status is `created`, `planned`, `assigned`, `in_progress`, `review`,
`blocked`, `done`, or `informational`; hotspot status is `open` or `resolved`.

## Diagnostics and Profiles

Diagnostics have stable `EMxxx` codes: `EM0xx` structural, `EM1xx` reference
resolution, `EM2xx` flow, `EM3xx` scenarios, and `EM4xx` modeling judgment.
The CLI prints `file:line:column: Severity EMxxx: Summary: Detail`.

`valid` is the default and keeps judgment diagnostics as warnings. `workshop`
makes all judgment diagnostics informational. `strict` escalates an unreasonsed
command (`EM404`) and an open hotspot (`EM406`) to errors. Bed, left-chair,
right-chair, and shelf smells remain non-blocking judgment signals in every
profile.

## Typed IR and Formatting

Validation remains the diagnostic boundary because HCL carries precise source
ranges. `internal/model.Load` first validates and only decodes a clean model.
It exposes a normalized typed IR with effective titles, semantic and
presentation fields, ordered workflows/scenarios, and one `Edges` list whose
entries always run source to target. Downstream tools consume this model rather
than raw HCL.

`fmt` canonicalizes whitespace and attribute order while preserving block and
scenario order and traversal expressions. Its attribute order is metadata,
ownership/status, semantic configuration, relationships (`from`, `to`), then
nested blocks. Formatting is idempotent.

## Compatibility

v0.2 rejects reverse flow forms and `query`, and State View scenarios now need
at least one event `given` and no `when`. Migrate a v0.1 document as one
complete document: normalize labels; move contracts into bounded contexts;
replace generic slices and string relationships with native workflow blocks and
typed traversals; replace legacy specifications with workflow-local scenarios;
write canonical flow forms; and remove redundant titles. Format and validate
the result with the implementation CLI.

This language validates one document at a time. It does not define multi-file
loading, cross-file references, JSON conversion, context maps, or inferred
causality.
