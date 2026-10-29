# RFC 0004: Uncoupled Authoring Controls

## Status

Accepted for v0.5.0. This RFC describes a breaking revision of `.em.hcl`.
The normative rules are merged into the v0.5.0 specification.
"Current" in this RFC means v0.4.0.

## 1. Summary and Motivation

This RFC gives each authoring concern its own control.
A control is a rule that selects one outcome.
Uncoupled means that each control changes only its own outcome.

The proposal gives field binding, board order, chapter membership, file layout,
judgment policy, titles, workflow patterns, contract origin, output order, and
workshop records separate controls.
Every sibling design matrix in section 6 is diagonal.

The current rules connect these outcomes in several places.
The evidence comes from the [current analysis](../axiomatic-design-analysis.md)
and the [v0.4.0 specification](../eventmodeling.hclspec.md):

| Current rule | Unwanted effect | Proposed replacement |
| --- | --- | --- |
| A typeless workflow field searches every context. | A new type in another context can break an existing field. | Require an explicit type binding. |
| Chapters and file names set workflow order. | Regrouping workflows or renaming files can change the board. | Give one `board` block the story order. |
| Source order sets the board in a one-file model. | Declaring a workflow places it on the board. | Unlisted workflows stay off the board. A new workflow needs no board edit. |
| Chapter rules change at two member files. | Adding an unrelated file changes chapter diagnostics. | Use one chapter rule for every model path. |
| The `translation` keyword restates the context `external` flag. | Changing a context's flag invalidates the workflows that consume it (`EM011`, `EM012`). | Merge `translation` into `automation`. The flag is the only origin statement. |
| The chosen profile controls construction of the IR in the implementation. | An open question can prevent tools from receiving a model. | Construct the IR from objective validity alone. |
| Omitted titles derive from identity labels. | An identity change also changes the readable title. | Keep titles as optional text without derivation. |

The design keeps every rule that makes one construct agree with another.
A typed reference still agrees with its declaration.
An example still conforms to its field type.
A scenario still fits its workflow pattern.
Section 6 shows where each agreement lives: inside one leaf requirement (FR1)
or under one parent control (FR7).
No requirement moves into a constraint.
No check on behavior is dropped to clear a matrix entry.
The one rule removed for independence is `EM011`/`EM012`.
It compared two statements of one fact.
Section 2.7 removes the second statement, so the comparison has nothing left
to compare.

### 1.1 Boundary and Constraints

The boundary includes source files, discovery, validation, formatting, and the
intermediate representation (IR). The IR is the normalized model that tools read.
Domain experts, model authors, tool authors, and teams that review models are
the stakeholders.

The proposal keeps native HCL, typed traversals, context-owned contracts,
canonical edges, and pattern-specific scenarios.
It keeps three workflow patterns: `state_change`, `state_view`, and
`automation`.
A translation becomes an automation that consumes an external event.
The IR shows this with a derived mark (section 2.7).
The proposal adds no deployment system, event executor, or scenario runner.
It does not adopt the `resolution` attribute from RFC 0003.
That proposal remains independent.

The workload includes single files and folders with any finite number of
members that the implementation can process. No latency or model-size bound
exists in the current specification. This RFC makes no new performance claim.
All independence claims concern accepted edits of structurally valid models.
Section 6.2 states the range.
Malformed syntax and broken references remain errors.

### 1.2 Needs and Traceability

These needs and criteria are proposed design targets.
They are not measured user-research results.
FR0 is the parent of FR1 through FR10.

FR0: Let authors change separate model concerns without unrelated repair work,
while invalid behavior still fails.
DP0: One explicit control for each concern, with no cross-concern defaults.
Junctions combine the outcomes (section 4.4).

| Need | Functional requirement and acceptance criterion | Design parameter |
| --- | --- | --- |
| N1: Grow the catalog without unrelated field repairs. N7: Keep behavior precise. | FR1 typed integrity: Each reference resolves to exactly one element of the expected kind. Each field and subfield states its type. Each example conforms to its bound type and cardinality. Adding an unreferenced declaration, even with a repeated short name, leaves every existing resolution identical. | DP1: A closed, qualified namespace. IDs are unique in their spaces. Traversals resolve by exact lookup. Every field has an explicit type. Literals are checked against the bound type. There is no search, inference, or default. |
| N2: Change the board story without changing groups or storage. | FR2 board story: The story sequence equals `board.workflows` exactly. A board edit changes no binding, membership, layout, flow, scenario, or title. | DP2: One `board.workflows` list. It selects the story workflows and orders them. |
| N3: Change story groups without moving the board. | FR3 grouping: A chapter membership edit leaves the story sequence unchanged. | DP3: Chapters own membership sets, not order. |
| N4: Split and rename files without model changes. | FR4 layout: Moving whole blocks among member files preserves the normalized model and diagnostic code/severity set. Source locations can change. | DP4: File union with no source-order meaning between top-level blocks. |
| N5: Apply team policy without losing a valid model. | FR5 policy: A profile edit changes judgment severity and policy status only. Core validity and the IR stay identical. | DP5: A profile severity map, applied to judgment signals after core validation. |
| N6: Change readable names without identity repair. | FR6 titles: A title edit changes display text only. An identity rename does not derive a new title. | DP6: Optional literal titles, with no derived title in the IR. |
| N7: Keep behavior precise. | FR7 pattern behavior: Each workflow is a valid instance of its pattern: allowed elements, canonical edges, and scenario shapes. Invalid flows and invalid scenarios prevent a core model. | DP7: A pattern grammar that the workflow keyword selects: `state_change`, `state_view`, or `automation`. |
| N9: See which contracts come from outside the system. | FR8 contract origin: Each contract's origin is stated once, by its owning context. No workflow keyword or workflow rule restates it. | DP8: The context `external` flag, as the only origin statement. |
| N8: Keep text and tool output deterministic. | FR9 determinism: Two formatting passes match. Formatting changes no IR. Equivalent file layouts give identical ordered IR. | DP9: Canonical order rules: a per-file formatter and fixed IR sort keys. |
| N10: Keep workshop records without behavior change. | FR10 workshop records: Actors, teams, systems, owners, hotspots, and workflow status add no edges, scenarios, order, or membership. | DP10: Workshop record blocks, unchanged from v0.4.0. |

FR1 and FR7 carry the agreement rules.
They stay in scope. Section 6.3 shows their internal structure.

## 2. Proposed Normative Language Changes

These rules apply only to the proposed revision.
All v0.4.0 rules remain in force unless a rule below replaces them.
Each comparison shows v0.4.0 on the left and the proposal on the right.
The code cells use HCL. Short fragments omit unchanged surrounding blocks.
Section 5.1 supplies a complete model for each revision.

### 2.1 Explicit Field Binding

Every `field` and `subfield` block requires `type`.
The value is an existing built-in type string or a `field_type` traversal.
Outside a bounded context the traversal is fully qualified,
`field_type.<context>.<id>`.
A field owned by a context keeps the v0.4.0 local form `field_type.<id>`;
it is an exact lookup in that context, not a search.
The requirement applies inside events, workflow elements, tables, and scenario
steps, including nested subfields.

A `field_type` declaration still requires a built-in type.
The `fields` list remains valid, because each entry already binds a qualified
type. Its last traversal segment still supplies the field name.
Duplicate field names remain errors.
List entries still precede field blocks, as in v0.4.0.

Adding `billing.pet_id` exposes the difference below.
The screen has no enclosing context, so its current implicit field becomes
ambiguous. The proposed field keeps its explicit binding.

<table>
<thead><tr><th>Current v0.4.0: catalog growth breaks a screen</th><th>Proposed: the binding stays local to its declaration</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
bounded_context "clinic" {
  field_type "pet_id" {
    type = "UUID"
  }
}

# Added by another author.
bounded_context "billing" {
  field_type "pet_id" {
    type = "String"
  }
}

state_change "register_pet" {
  screen "entry" {
    field "pet_id" {
      # Inference searches both contexts.
      # Result: EM009.
    }
  }
}
</pre>
</td><td valign="top">
<pre lang="hcl">
bounded_context "clinic" {
  field_type "pet_id" {
    type = "UUID"
  }
}

# The same catalog addition.
bounded_context "billing" {
  field_type "pet_id" {
    type = "String"
  }
}

state_change "register_pet" {
  screen "entry" {
    field "pet_id" {
      type = field_type.clinic.pet_id
      # The binding stays unchanged.
    }
  }
}
</pre>
</td></tr></tbody>
</table>

v0.4.0 already permits the explicit binding on the right.
The proposal requires it instead of retaining global inference as an alternative.
Changing the referenced type still affects consumers.
For example, a new built-in type can make an existing example invalid (`EM010`).
That effect stays inside FR1: the type and its uses are parts of one namespace.
This removes the global search, not type dependencies.

### 2.2 One Explicit Board Order

A model requires exactly one unlabeled top-level `board` block.
The block has exactly one required attribute, `workflows`.
That value is a list of `workflow.<id>` traversals.
Each entry names an existing workflow.
A workflow appears at most once.
The list can omit workflows, and it can be empty.

The list is the complete story sequence for diagrams and other story output.
No fallback uses file names, block positions, chapter lists, or IDs.
A workflow that the list omits is off-board.
It is part of the model and passes through every core rule.
The IR lists it in an off-board set, in byte order of workflow IDs.
No profile gives an off-board workflow a diagnostic.
A tool can list off-board workflows separately.
It must not insert them into the story sequence.

Adding a workflow requires no board edit.
The new workflow stays off-board until an author places it.
Removing or renaming a workflow repairs its board entry, like every other
reference to that workflow (section 6.2).

In a folder with two member files, removing the first workflow from the chapter
also moves it behind the directory. The proposed board keeps the story order.
Assume the workflow declarations from section 5.1 are present.

<table>
<thead><tr><th>Current v0.4.0: a group edit moves the board</th><th>Proposed: a group edit leaves the board alone</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
# Before: both workflows are chaptered.
chapter "registration" {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}

# Replace the chapter above with:
chapter "registration" {
  workflows = [workflow.pet_directory]
}
# register_pet becomes unchaptered.
# Board: pet_directory, register_pet.
# EM407 also appears.
</pre>
</td><td valign="top">
<pre lang="hcl">
# This block does not change.
board {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}

# Make the same group edit.
chapter "registration" {
  workflows = [workflow.pet_directory]
}
# Board: register_pet, pet_directory.
# No chapter coverage diagnostic.
</pre>
</td></tr></tbody>
</table>

The two current chapter blocks show alternatives, not simultaneous declarations.

Adding a workflow shows the second difference.
In a current one-file model, a new workflow block takes the board position of
its source location.
In the proposal, the board stays the same.

<table>
<thead><tr><th>Current v0.4.0: a declaration places a workflow</th><th>Proposed: a declaration leaves the board alone</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
# One file. Insert a new workflow
# between the two existing ones.
state_view "pet_count" {
  readmodel "count" {
    question = "How many pets are registered?"
    from     = [event.clinic.pet_registered]
  }
}
# Board: register_pet, pet_count,
# pet_directory.
</pre>
</td><td valign="top">
<pre lang="hcl">
# The same declaration, in any file.
state_view "pet_count" {
  readmodel "count" {
    question = "How many pets are registered?"
    from     = [event.clinic.pet_registered]
  }
}
# Board: register_pet, pet_directory.
# Off-board: pet_count.
</pre>
</td></tr></tbody>
</table>

A board permutation changes workflow order only.
It does not change edge direction, scenario order, or chapter membership.
Consumers must not require chapter members to be contiguous.
A grouped view can filter the board list by chapter membership.
It cannot replace the board list in the normalized model.

### 2.3 Chapters Own Membership Only

A chapter keeps its identity, optional title, and required nonempty `workflows`
list. Each traversal must name an existing workflow.
The list denotes a set. Its source order has no model meaning.
Repeated entries in the same chapter are errors.
A workflow belongs to at most one chapter, as in v0.4.0.
A workflow can belong to no chapter without a diagnostic.
A chapter can contain off-board workflows.
Board placement and chapter membership never constrain each other.

Chapters can live in different member files.
There is no contiguity rule and no one-file exception.
Chapter order in the IR is byte order of chapter IDs.
Changing a chapter never updates `board.workflows`.

Reverse the chapter list while keeping source blocks in their original order.
In a current one-file model, this produces `EM006`.
In a current multi-file model, it changes board order instead.

<table>
<thead><tr><th>Current v0.4.0: list order changes validity or the board</th><th>Proposed: membership has no order</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
# Source workflows: register_pet,
# then pet_directory.
chapter "registration" {
  title = "Registration"
  workflows = [
    workflow.pet_directory,
    workflow.register_pet,
  ]
}
# One file: EM006.
# Multiple files: directory comes first.
</pre>
</td><td valign="top">
<pre lang="hcl">
board {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}

chapter "registration" {
  title = "Registration"
  workflows = [
    workflow.pet_directory,
    workflow.register_pet,
  ]
}
# Accepted in either file mode.
# Registration still comes first.
</pre>
</td></tr></tbody>
</table>

### 2.4 File Layout Has No Story Meaning

File discovery keeps the v0.4.0 rules.
A file path loads one file. A folder loads its direct, visible `.em.hcl`
regular files, including symlinks to files.
Subfolders remain outside the model.
An empty folder still produces `EM001`.

Every file must parse alone.
The union owns one set of global declarations.
Duplicate identities remain errors, and blocks cannot span files.
File names select discovery and diagnostic locations, not model order.
The one-file and many-file cases use identical semantic rules.

Several collections use byte order of their complete qualified IDs.
These include catalog items, chapters, hotspots, off-board workflows, local
workflow elements, tables, screen images, and scenario declarations within a
workflow.
Chapter membership lists normalize by workflow ID.
The story sequence comes only from `board.workflows`.
Order inside explicit lists remains significant unless this RFC defines a set.
Scenario steps and field declarations keep their internal source order.
Renaming a file does not reorder those internal sequences.

A rename preserves meaning only when the file remains a member.
A rename to `.hidden.em.hcl` removes a member and is not an independent layout
edit. Adding another path to the same symlink target can introduce duplicates.
File discovery does not deduplicate declarations by physical file identity.

The following comparison adds an actor-only second file.
Assume the original file contains the workflows from section 5.1 without chapters.
Moving to two files changes current diagnostics despite unchanged behavior.

<table>
<thead><tr><th>Current v0.4.0: an unrelated file changes acceptance</th><th>Proposed: file count does not select chapter rules</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
# model.em.hcl already holds both workflows.
# Add people.em.hcl:
actor "auditor" {
  auth_required = true
}
# Two files now select folder chapter rules.
# Both workflows receive EM407.
# Under strict, validation fails.
</pre>
</td><td valign="top">
<pre lang="hcl">
# model.em.hcl already holds both workflows
# and their board:
board {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}

# Add people.em.hcl:
actor "auditor" {
  auth_required = true
}
# Board and policy acceptance stay unchanged.
</pre>
</td></tr></tbody>
</table>

### 2.5 Titles Are Text, Not Derived Identity

`title` remains optional on the constructs that accept it in v0.4.0.
If present, it is a literal string.
If absent, the IR records an absent title.
The loader and formatter never invent one from a label.

A consumer must expose identity separately from the optional title.
If a title is absent, it can show the identity as the identity.
It must not claim that this fallback is stored title text.

The comparison renames an identity label without adding a title.
Only the current revision also changes the effective title.

<table>
<thead><tr><th>Current v0.4.0: identity also supplies title text</th><th>Proposed: title presence and text are separate</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
# Before:
actor "receptionist" {
  auth_required = true
}
# Effective title: Receptionist.

# Rename the label to front_desk.
# Effective title also becomes Front Desk.
</pre>
</td><td valign="top">
<pre lang="hcl">
# Before:
actor "receptionist" {
  auth_required = true
}
# Title: absent.

# Rename the label to front_desk.
# Title stays absent.
# Identity remains visible separately.
</pre>
</td></tr></tbody>
</table>

An explicit `title = "Front desk"` already prevents derived-title changes in
v0.4.0. The proposal removes derivation for omitted titles too.
In both revisions, an identity rename still requires reference updates.

### 2.6 Separate Core Validity from Team Policy

The core loader runs syntax, structure, reference, flow, and scenario rules.
A core error prevents construction of the IR.
The active judgment profile has no role in this decision.

Core rules also emit judgment signals: `EM401` to `EM405` from pattern rules
and `EM406` from hotspot records.
A signal carries a code and a source range, not a severity.
The policy evaluator assigns each signal its severity under the selected
profile.
The existing profiles keep their meanings for the surviving judgment codes.
The result contains two separate facts: core validity and policy acceptance.
An error-severity judgment diagnostic means policy rejection, not core failure.

`validate --profile strict` exits unsuccessfully on either core failure or
policy rejection. A tool that constructs diagrams still receives the IR when
only policy fails. It renders the model and reports the rejection separately.
Policy rejection cannot remove a current model or retain a stale model instead.
If a command writes a requested artifact despite policy rejection, its exit
status still reports that rejection.

The source is identical in this comparison.
The change is the contract between the core loader and policy evaluation.
Assume the hotspot attaches to an otherwise valid model.

<table>
<thead><tr><th>Current implementation: policy can suppress the model</th><th>Proposed: policy reports rejection without hiding the model</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
hotspot "notification_channel" {
  question = "Which channel sends reminders?"
  status   = "open"
  on       = workflow.register_pet
}
# serve --profile strict:
# EM406 has error severity.
# The loader provides no current core IR.
</pre>
</td><td valign="top">
<pre lang="hcl">
hotspot "notification_channel" {
  question = "Which channel sends reminders?"
  status   = "open"
  on       = workflow.register_pet
}
# Proposed serve --profile strict:
# EM406 still has error severity.
# The current core IR remains available.
# The view reports policy rejection.
</pre>
</td></tr></tbody>
</table>

This current behavior comes from the implementation, not a precise profile
contract in the v0.4.0 specification.
Changing status to `resolved` changes policy results, not behavior.
This RFC does not add a separate answer field.

### 2.7 Automation Covers Boundary Crossing

The proposed revision has three workflow keywords: `state_change`,
`state_view`, and `automation`.
The `translation` keyword is removed.
An `automation` keeps the v0.4.0 elements, edges, and scenario rules that
`automation` and `translation` shared.
It can consume internal events, external events, or both.

The owning context's `external` flag is the only statement of a contract's
origin.
No workflow rule reads the flag, so `EM011` and `EM012` retire.
The IR records origin on every edge whose source is a catalog event.
The edge carries the `external` value of that event's owning context.
A consumer that shows translation derives it with one view rule:
an automation with at least one external edge is a translation.
This rule is for display only. No rule uses it to accept or reject a model.

The comparison changes the origin of the consumed event.
The workflow body is the same as `examples/translation.em.hcl`.

<table>
<thead><tr><th>Current v0.4.0: the origin is stated twice</th><th>Proposed: the origin is stated once</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
bounded_context "weather_provider" {
  external = true

  event "weather_forecast_changed" {
  }
}

bounded_context "weather" {
  event "weather_prediction_updated" {
  }
}

translation "translate_weather_forecast" {
  processor "weather_translator" {
    from = [event.weather_provider.weather_forecast_changed]
    to   = [command.update_weather_prediction]
  }

  command "update_weather_prediction" {
    to = [event.weather.weather_prediction_updated]
  }
}
# Set external = false: EM011.
# Use the automation keyword instead: EM012.
</pre>
</td><td valign="top">
<pre lang="hcl">
bounded_context "weather_provider" {
  external = true

  event "weather_forecast_changed" {
  }
}

bounded_context "weather" {
  event "weather_prediction_updated" {
  }
}

automation "translate_weather_forecast" {
  processor "weather_translator" {
    from = [event.weather_provider.weather_forecast_changed]
    to   = [command.update_weather_prediction]
  }

  command "update_weather_prediction" {
    to = [event.weather.weather_prediction_updated]
  }
}
# IR: the processor edge is external.
# Set external = false: the mark changes.
# The workflow stays valid.
</pre>
</td></tr></tbody>
</table>

The methodology guides keep translation as a modeling concept.
Section 6.8 lists the guide updates that adoption needs.
A source reader no longer sees the keyword. Tools must show the derived mark.
Section 6.7 names the measurement that tests this cost.

### 2.8 Agreement Rules Stay Inside One Branch

The three workflow patterns keep their existing elements and canonical edges.
Scenario targets and counts still depend on the workflow keyword.
Examples still conform to the referenced field type and cardinality.
Wrong-kind and unresolved references remain errors.

These rules are not dependencies between sibling controls.
Reference, type, and example agreement are parts of FR1.
FR1 is one leaf with one mechanism, the qualified namespace.
Pattern, edge, and scenario agreement are parts of FR7.
The workflow keyword is the parent control of FR7, and it selects the grammar
for its children.
A keyword change replaces that parent for one workflow. Its children are then
checked again under the new grammar.
Section 6.3 gives both structures.

## 3. Compatibility and Migration

This proposal requires an explicit breaking release.
It does not change the meaning of current v0.4.0 documents in current tools.
There is no mixed-mode model or per-file dialect selection.
A future implementation selects one language revision for the whole load.
No compatibility aliases preserve the old inference or ordering rules or the
`translation` keyword.

Migration reads the complete model under v0.4.0 rules before rewriting it.
An invalid or ambiguous input stops migration with source diagnostics.
The migrator never guesses which type a typeless field means.

The migration performs these steps:

1. Load the old model with the current `valid` profile.
2. Copy the old effective workflow order into one `board.workflows` list.
   The list names every workflow, so no workflow becomes off-board.
3. Write the resolved type of every typeless field and subfield as an explicit value.
4. Preserve every effective title as an explicit title string.
5. Preserve chapter memberships without assigning them any order.
6. Rewrite every `translation` keyword as `automation`. The block body does not change.
7. Load the result under the proposed rules.
8. Compare semantic content, titles, scenarios, memberships, workflow order, and
   boundary marks.
   Each former translation must have at least one external edge.
   Each former automation must have none.

The old rules guarantee the check in step 8 for valid inputs (`EM011`, `EM012`).
The migration report lists each rewritten translation.

The migrator places `board` at the start of the input file for a file model.
For a folder model, it uses the byte-first member file.
It does not create a second board or overwrite an unrelated file.
This placement has no semantic meaning.

The migration report separates model preservation from diagnostic changes.
Retired chapter and translation diagnostics disappear, and policy no longer
gates the IR.
Those changes are intentional, so diagnostics are not required to match across
language revisions.

## 4. Validation, Formatter, and Typed-IR Impact

### 4.1 Diagnostic Contract

The proposed revision keeps existing codes for their surviving meanings.
It retires `EM006`, `EM011`, `EM012`, `EM013`, and `EM407` and never reassigns
them.
`EM014` still rejects a workflow in several chapters.
The proposal reserves the following new codes for specification adoption:

| Code | Condition | Severity |
| --- | --- | --- |
| EM015 | Missing or repeated `board` block. | Core error in every profile. |
| EM016 | The board repeats a workflow. | Core error in every profile. |
| EM009 | A field or subfield omits its required type, or uses an invalid type. | Core error in every profile. |
| EM002 | A duplicate identity or a repeated chapter member. | Core error in every profile. |
| EM101 / EM102 | A malformed, wrong-kind, or unresolved board, chapter, or field reference. | Core error in every profile. |

A `translation` block uses the existing unsupported-block diagnostic.
Unknown board attributes use the existing attribute diagnostic.
Missing `board.workflows` also uses the required-attribute diagnostic.
An omitted workflow is not a diagnostic in any profile.
The loader must not repair the list automatically.
Diagnostics retain precise source ranges.
For duplicate declarations, byte-sorted file order selects the first location.
This diagnostic reporting order does not order the model.

### 4.2 Formatter Contract

`fmt` remains a per-file operation.
It preserves board lists, scenario steps, traversals, and field declaration order.
It does not move blocks or expand the `fields` list.
It keeps chapter lists as written even though their order is not semantic.

The board has only the `workflows` attribute.
Existing attribute groups continue to apply to other blocks.
Two formatting passes must produce identical bytes.

### 4.3 Typed-IR Contract

The IR keeps the v0.4.0 shape, with these changes:

- The story sequence comes from `board.workflows`.
- A separate off-board set lists every unlisted workflow, in byte order of
  workflow IDs.
- Each edge whose source is a catalog event carries the `external` value of
  that event's owning context.
- Titles are present only when the source states them.
- Workflow kinds are `state_change`, `state_view`, and `automation`.

### 4.4 Module Responsibilities and Ownership

These are logical responsibilities, not separate services.
All state below is per load, except the formatter output file.
A tool must not combine declarations from different load attempts.

| Module and FR leaves | Inputs and owned state | Outputs and invariant | Failure contract |
| --- | --- | --- | --- |
| Source assembly, FR4 | Model path and member bytes. Owns source locations and the declaration union. | One model snapshot. File layout does not set semantic order. | Read or parse failure returns diagnostics and no core model. |
| Binding, FR1 | Declaration union. Owns ID spaces, resolved references, type bindings, and literal checks. | Each accepted reference has one target of the expected kind. Each literal conforms to its bound type. | Missing, duplicate, or wrong targets, missing types, and bad literals stop the core model. |
| Pattern rules, FR7 | Bound workflows. Owns pattern diagnostics and the `EM401` to `EM405` signals. | Each workflow fits the grammar of its keyword. Signals have no severity. | Any objective violation stops the core model. |
| Board projection, FR2 | The bound board list. Owns the story sequence. | The sequence equals the list. No workflow repeats. | A missing or repeated board, or a repeated or unknown entry, stops the core model. |
| Chapter projection, FR3 | Accepted chapter membership sets and workflow IDs. Owns group membership. | At most one chapter per workflow. Membership does not set board order. | Bad membership stops the core model. No coverage warning exists. |
| Title projection, FR6 | Optional literal titles. Owns title presence and text. | No derived titles. Identity remains separate. | Invalid title syntax is a core error. |
| Origin record, FR8 | Context `external` flags. Owns the origin of each contract. | One origin statement per contract. No workflow rule reads it. | An invalid flag value is a core error. |
| Workshop records, FR10 | Actors, teams, systems, owners, hotspots, and workflow status. Owns these records and the `EM406` signal. | No record adds an edge, scenario, order, or membership. | A bad attachment is a reference error under FR1. |
| IR assembly, FR9.2 | Accepted projections. Owns the immutable normalized result, the off-board set, and the boundary marks. | Deterministic collections, explicit story order, and canonical edges. | No IR on core failure. Never substitute an old result. |
| Policy evaluator, FR5 | Read-only judgment signals and the selected profile. Owns severities and policy status. | Cannot mutate, gate, or suppress the IR. | Policy rejection changes status and diagnostics only. |
| Formatter, FR9.1 | One syntactically valid source file. Owns replacement text. | Stable formatting without a model rewrite. | Syntax failure reports diagnostics without overwriting source. |

### 4.5 Integration

A summation junction (S) combines outcomes without changing their controls.
A control junction (C) enforces a required order.
There is no feedback junction (F) in this proposal.
Fixing an invalid model is author work, not an automatic retry loop.

| Composition | Junction | Required order or invariant |
| --- | --- | --- |
| Member file parsing | S | All member files contribute to the same load snapshot. |
| Union, then binding | C | Resolve only after every declaration is available. |
| Binding, then pattern rules, board, chapters, titles, origins, and workshop records | C, then S | Each branch reads bound identities and owns separate state. A failure in any core branch rejects the complete core model. |
| Off-board set | S | Declared workflows minus the board list, sorted by ID. Neither input changes. |
| Boundary marks | S | Each event-sourced edge (FR7) carries the origin of its source contract (FR8). Neither input changes. |
| Accepted projections, then IR assembly | C | Publish one complete result, never a partial semantic model. |
| IR and judgment signals, then severity, then policy status | C | The profile maps each signal to a severity. Any error severity rejects policy. Policy reads the current result and cannot gate its construction. |
| Board order and chapter sets in a view | S | Show both without changing either stored outcome. |

The off-board set, the boundary marks, and policy status are combined
outcomes.
They are not sibling requirements. Each changes when one of its inputs
changes, and no junction writes back to an input.
This runtime order does not prove functional independence.
Section 6 makes that argument.

## 5. Examples and Acceptance Tests

### 5.1 Complete Models Side by Side

Both models describe the same registration and directory behavior.
The current model relies on inferred field types and source order.
The proposal records those choices explicitly.
The left model is current source, and the right model targets this RFC.

<table>
<thead><tr><th>Current v0.4.0: implicit binding and source order</th><th>Proposed: explicit binding and independent board order</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
actor "receptionist" {
  title         = "Front desk"
  auth_required = true
}

bounded_context "clinic" {
  field_type "pet_id" {
    type = "UUID"
  }

  event "pet_registered" {
    fields = [field_type.clinic.pet_id]
  }
}

# Source order supplies board order.
state_change "register_pet" {
  title = "Register a pet"

  screen "entry" {
    actor  = actor.receptionist
    fields = [field_type.clinic.pet_id]
    to     = [command.submit]
  }

  command "submit" {
    to = [event.clinic.pet_registered]

    field "pet_id" {
      # Searches the whole catalog.
    }
  }

  scenario "registration_succeeds" {
    when {
      command = command.submit
    }
    then {
      event = event.clinic.pet_registered
    }
  }
}

state_view "pet_directory" {
  title = "Find registered pets"

  readmodel "pets" {
    question = "Which pets are registered?"
    from     = [event.clinic.pet_registered]
    to       = [screen.list]
  }

  screen "list" {
    actor = actor.receptionist
  }

  scenario "pet_is_visible" {
    given {
      event = event.clinic.pet_registered
    }
    then {
      readmodel = readmodel.pets
    }
  }
}

chapter "registration" {
  title     = "Registration"
  workflows = [workflow.register_pet]
}

hotspot "notification_channel" {
  question = "Which channel sends reminders?"
  status   = "open"
  on       = workflow.register_pet
}
</pre>
</td><td valign="top">
<pre lang="hcl">
board {
  workflows = [workflow.register_pet, workflow.pet_directory]
}

actor "receptionist" {
  title         = "Front desk"
  auth_required = true
}

bounded_context "clinic" {
  field_type "pet_id" {
    type = "UUID"
  }

  event "pet_registered" {
    fields = [field_type.clinic.pet_id]
  }
}

state_change "register_pet" {
  title = "Register a pet"

  screen "entry" {
    actor  = actor.receptionist
    fields = [field_type.clinic.pet_id]
    to     = [command.submit]
  }

  command "submit" {
    to = [event.clinic.pet_registered]

    field "pet_id" {
      type = field_type.clinic.pet_id
    }
  }

  scenario "registration_succeeds" {
    when {
      command = command.submit
    }
    then {
      event = event.clinic.pet_registered
    }
  }
}

state_view "pet_directory" {
  title = "Find registered pets"

  readmodel "pets" {
    question = "Which pets are registered?"
    from     = [event.clinic.pet_registered]
    to       = [screen.list]
  }

  screen "list" {
    actor = actor.receptionist
  }

  scenario "pet_is_visible" {
    given {
      event = event.clinic.pet_registered
    }
    then {
      readmodel = readmodel.pets
    }
  }
}

chapter "registration" {
  title     = "Registration"
  workflows = [workflow.register_pet]
}

hotspot "notification_channel" {
  question = "Which channel sends reminders?"
  status   = "open"
  on       = workflow.register_pet
}
</pre>
</td></tr></tbody>
</table>

### 5.2 File Split and Chapter Edit

Split each complete model into member files without changing its blocks.
Move the chapter into `story.em.hcl` and the actor into `people.em.hcl`.
In the proposed model, move the board into `story.em.hcl` too.
The current model gains `EM407` for the unchaptered directory.
The proposed model keeps its board, memberships, and policy results.

Now add the directory to the chapter with the reverse list below.
In the current folder model, that list also reverses the board.
In the proposal, only membership changes.

<table>
<thead><tr><th>Current v0.4.0: adding a member also moves it</th><th>Proposed: membership changes without moving it</th></tr></thead>
<tbody><tr><td valign="top">
<pre lang="hcl">
chapter "registration" {
  title = "Registration"
  workflows = [
    workflow.pet_directory,
    workflow.register_pet,
  ]
}
# Folder board: directory, registration.
</pre>
</td><td valign="top">
<pre lang="hcl">
board {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}

chapter "registration" {
  title = "Registration"
  workflows = [
    workflow.pet_directory,
    workflow.register_pet,
  ]
}
# Board stays: registration, directory.
</pre>
</td></tr></tbody>
</table>

### 5.3 Acceptance Scenarios

These are implementation acceptance criteria, not reported passing tests.
Each independence test compares all other normalized fields, not only the
expected changed field.
The DP column names the control that the scenario varies.

| DP | Scenario | Required result |
| --- | --- | --- |
| DP1 | Add `billing.pet_id` to the complete example. | Every existing type binding stays identical. |
| DP1 | Omit `type` from a field or nested subfield. | `EM009` in every profile. No inferred type. |
| DP1 | Change the built-in type of a `field_type` that an example uses. | `EM010` at the example. Board, memberships, flow, scenarios, and titles match. |
| DP1 | Rename a workflow and repair every reference to it. | Board position, chapter membership, and hotspot attachment stay the same. Only the identity changes. |
| DP1 | Introduce an unresolved event target under any profile. | No core IR. A profile cannot make a broken reference valid. |
| DP2 | Reverse `board.workflows`. | Workflow order reverses. Edges, chapter sets, fields, titles, and scenarios match. |
| DP2 | Remove a workflow from the board. | The workflow moves to the off-board set. No diagnostic. Everything else matches. |
| DP2 | Repeat a board workflow. | `EM016`, with no fallback order. |
| DP2 | Use an unknown workflow in the board. | A reference error, not a synthesized workflow. |
| DP2 | Declare two boards, or none. | `EM015`, even when two lists match. |
| DP2 | Use an empty board in a model with workflows. | Accepted core model. Every workflow is off-board. |
| DP3 | Reverse a chapter list. | Normalized membership, board order, and behavior match. |
| DP3 | Add the directory to the chapter. | Only chapter membership changes. |
| DP3 | Remove all chapters. | Board and behavior match. No `EM407`. |
| DP3 | Put an off-board workflow in a chapter. | Accepted. The board stays the same. |
| DP4 | Add an actor-only member file. | Only the actor collection changes. No chapter or board diagnostic appears. |
| DP4 | Split, merge, or rename member files without editing blocks. | Semantic content and diagnostic code/severity sets match. Source locations can differ. |
| DP4 | Move chapters into separate files. | No `EM013`. Duplicate membership still produces `EM014`. |
| DP4 | Hide a member file or move it to a subfolder. | Discovery changes. Missing declarations produce ordinary errors. No independence claim applies. |
| DP5 | Select `workshop`, `valid`, then `strict` with an open hotspot. | Identical core IR each time. `EM406` changes severity and policy acceptance only. |
| DP6 | Change a title. | Only optional display text changes. |
| DP6 | Remove a title. | Absent title in the IR. No title-cased default. |
| DP7 | Declare a new workflow without editing the board. | The story sequence stays the same. The new workflow is off-board. |
| DP7 | Add a scenario to a workflow. | Edges and element sets match. |
| DP7 | Add an edge between existing elements. | Existing scenarios keep their validity. |
| DP7 | Change a `state_change` keyword to `state_view` and keep its command. | A pattern error for the command. The parent control changed, so its children are checked again. |
| DP7 | Change a State View scenario to contain `when`. | The existing scenario rule rejects it. |
| DP7 | Use a `translation` block. | The unsupported-block diagnostic. |
| DP8 | Set `external = true` on a context that an automation consumes. | The automation stays valid. Only the boundary marks on its edges from that context change. |
| DP8 | Set `external = false` on the provider in section 2.7. | The workflow stays valid. The derived translation view no longer applies. |
| DP9 | Format twice, then load. | Second output is identical. The normalized model matches the first load. |
| DP10 | Change workflow status or an actor's attributes. | Edges, scenarios, board, and memberships match. |
| Migration | Migrate valid one-file and folder examples. | Old effective order, field types, titles, scenarios, memberships, and boundary marks survive. |
| Migration | Migrate a translation example. | The keyword becomes `automation`. At least one edge is external. |
| Migration | Migrate an ambiguous typeless field. | Stop with diagnostics. Never choose a context silently. |

### 5.4 Proposal Verification

All twenty HCL code cells parse with the HCL v2.24.0 parser.
The complete current model passes the existing CLI with the expected `EM406`
warning. Adding `billing.pet_id` produces `EM009` at its implicit command field.
An explicit binding removes that error, as section 2.1 describes.
The current translation cell in section 2.7 passes the existing CLI.
With `external = false` it produces `EM011`.
The same body under the `automation` keyword produces `EM012`.
Inserting the current `pet_count` cell of section 2.2 between the two
workflows of the complete current model exports the order that its comment
states.

The ten tables place current and proposed source side by side.
Proposed-language cells need the future implementation for semantic acceptance.

These results cover syntax and retained behavior only.
They do not test proposed board semantics, migration, profile separation,
boundary marks, or consumer changes. Those require an implementation of this
revision.

## 6. Axiomatic Design, Alternatives, and Open Questions

### 6.1 Actual Influence Model of v0.4.0

A functional requirement (FR) states an outcome.
A design parameter (DP) selects the mechanism for that outcome.
The matrices use FR rows and DP columns.
`X` means a material influence, `0` means none within the stated range, and
`?` means that evidence is missing.
This is an architecture adaptation of Axiomatic Design, not a linear equation
for the language.

The existing analysis found these actual influences:

| Current outcome | Type inference | Chapter lists | File count/names | Context `external` flag | Judgment profile |
| --- | --- | --- | --- | --- | --- |
| Field bindings | X | 0 | X | 0 | 0 |
| Board order | 0 | X | X | 0 | 0 |
| Chapter acceptance | 0 | X | X | 0 | 0 |
| Automation and translation acceptance | 0 | 0 | 0 | X | 0 |
| Availability of the IR | X | X | X | X | X |

The file influence on field binding applies when membership changes which
short-name candidates exist. A pure rename of the same members does not change
type binding. The flag influence on acceptance comes from `EM011` and `EM012`
(analysis probe P2).
The IR row includes core rejection after an invalid binding, chapter rule, or
pattern rule, not just the profile gate.
This rectangular matrix illustrates shared controls.
It does not by itself classify the full current design.
The rest of section 6 describes the proposed design only.

### 6.2 Level 1: Uncoupled Controls

The matrix uses the authoring reading of the method.
A DP is the construct that an author edits, together with the rule that reads
it.
A cell asks: does an accepted edit of DP_j change the outcome of FR_i?

The range bounds every cell:

- Each edit is accepted: it satisfies its own contract.
  A board edit lists existing workflows without repeats.
  A file edit keeps the same member declarations and internal sequences.
  A chapter edit preserves valid references and exclusive membership.
- A rename or removal includes the repair of every use of the name.
  References in boards, chapters, hotspots, edges, and scenarios are uses of
  DP1. A rename edits that text, but each list keeps the same element at the
  same position.
- The language vocabulary is fixed.
  Adding a block kind or attribute to the language is a language revision.
  It needs a formatter slot (analysis, branch FR8) and is outside this range.
- The source tree is a consistent snapshot during a load.
- Malformed syntax is outside the range. Section 6.4 covers failures.

These are bounds on valid edits, not a removal of FR1 or FR7.
An edit outside the bounds fails under FR1 or FR7, and it is reported there.

| Outcome | DP1 namespace | DP2 board | DP3 chapters | DP4 layout | DP5 profile | DP6 titles | DP7 pattern grammar | DP8 origin flag | DP9 order rules | DP10 workshop records |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FR1 typed integrity | X | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FR2 board story | 0 | X | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FR3 grouping | 0 | 0 | X | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FR4 layout | 0 | 0 | 0 | X | 0 | 0 | 0 | 0 | 0 | 0 |
| FR5 policy | 0 | 0 | 0 | 0 | X | 0 | 0 | 0 | 0 | 0 |
| FR6 titles | 0 | 0 | 0 | 0 | 0 | X | 0 | 0 | 0 | 0 |
| FR7 pattern behavior | 0 | 0 | 0 | 0 | 0 | 0 | X | 0 | 0 | 0 |
| FR8 contract origin | 0 | 0 | 0 | 0 | 0 | 0 | 0 | X | 0 | 0 |
| FR9 determinism | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | X | 0 |
| FR10 workshop records | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | X |

This matrix is uncoupled under the stated range.
There is no required order for these edits.
Each zero follows from an enforceable rule:

- DP1 resolves by exact lookup. It cannot search unrelated names, so catalog
  growth changes no binding. A rename keeps every list position (range).
  Pattern rules check edge kinds, and a rename keeps kinds.
- DP2 is read only by board projection. It cannot rewrite chapter membership,
  source layout, or flow. The smell signals read edges and scenario placement,
  not board position [Code, `internal/validator/smells.go`].
- DP3 cannot replace the board list or produce coverage diagnostics.
  `EM407` is retired.
- DP4 cannot contribute any semantic ordering between top-level blocks.
  One-file and folder models use identical rules, so `EM006` and `EM013` are
  retired.
- DP5 has read-only access to signals. It runs after IR assembly and cannot
  gate it.
- DP6 cannot rewrite identity or reference values. No rule reads a title.
- DP7 rules read element kinds, edges, and scenario steps. They read no origin
  flag, board, chapter, title, or file. A new workflow is off-board, so the
  story sequence stays the same.
- DP8 is read by no acceptance rule. `EM011` and `EM012` are retired.
  Only the boundary-mark junction reads it.
- DP9 sets whitespace, attribute order, and sort keys. It changes no content.
- DP10 records add no edges, scenarios, order, or membership.
  A hotspot attachment is a DP1 use.

FR4 measures physical placement only.
Its source diagnostic locations change with placement, as its criterion permits.
FR5 measures the profile mapping.
Judgment signals change when their own inputs change. For example, resolving
a hotspot removes `EM406`.
That edit is a DP10 edit, and policy status is a combined outcome (section 4.5).

### 6.3 Level 2: Branches

Each branch below is either a leaf or a diagonal sibling set.

**FR1 is a leaf.**
Its parts are unique declarations, exact lookup, required types, and literal
checks. They form one keyed table that one binder reads.
A split into children would pair a declaration with its uses.
For example, a rule for literal conformance depends on the bound type.
Such a split gives a triangular matrix.
This RFC therefore does not split FR1.
The diagonal claim rests on this leaf boundary.
The cost is visible: a declaration edit can need repairs in many places, and
each repair stays inside FR1.
The leaf is clear at this level: the binding module, its owned state, its
errors, and its acceptance rows in section 5.3 are defined.

**FR7 has a parent control and three children.**
The workflow keyword (DP7) selects one pattern grammar.
The children are derived inside the selected grammar:

| FR | Outcome | DP |
| --- | --- | --- |
| FR7.1 | Each element is allowed by the pattern. | DP7.1: the element set of the pattern |
| FR7.2 | Each edge uses its canonical spelling and direction. | DP7.2: the edge table of the pattern |
| FR7.3 | Each scenario step fits the pattern. | DP7.3: the scenario table of the pattern, with targets and counts |

| | DP7.1 | DP7.2 | DP7.3 |
| --- | --- | --- | --- |
| FR7.1 | X | 0 | 0 |
| FR7.2 | 0 | X | 0 |
| FR7.3 | 0 | 0 | X |

This matrix is uncoupled for a selected pattern:

- Adding an element adds no edge and no scenario step.
- Edge rules check the spelling for a pair of element kinds. Scenarios add no
  edges.
- Scenario rules use the pattern, the step, and the target kind. They do not
  read edges [Code, `scenarioTargetAllowed` in
  `internal/validator/scenarios.go`].
  A scenario target must resolve, and that is a DP1 use.

A keyword change is not an edit inside this matrix.
It replaces the parent control for one workflow.
Its children are then derived again under the new grammar.
This is the zigzag step of the method, not coupling between siblings.
Before this RFC, the `external` flag also influenced FR7, through `EM011` and
`EM012`. Section 2.7 removes that influence.

**FR5 has two children.**

| FR | Outcome | DP |
| --- | --- | --- |
| FR5.1 | Each judgment signal has the severity that the profile states. | DP5.1: the profile severity map |
| FR5.2 | The profile never changes core validity or the IR. | DP5.2: policy runs after IR assembly, with read-only access |

| | DP5.1 | DP5.2 |
| --- | --- | --- |
| FR5.1 | X | 0 |
| FR5.2 | 0 | X |

The position of policy does not choose a severity.
A map edit cannot reach the IR, because DP5.2 gives policy no write path.

**FR9 has two children.**

| FR | Outcome | DP |
| --- | --- | --- |
| FR9.1 | Two formatting passes match, and formatting changes no IR. | DP9.1: whitespace and attribute-order rules for each file |
| FR9.2 | Equivalent inputs give identical ordered IR. | DP9.2: IR sort keys: qualified-ID byte order, board order for the story, and source order for steps, fields, and explicit lists |

| | DP9.1 | DP9.2 |
| --- | --- | --- |
| FR9.1 | X | 0 |
| FR9.2 | 0 | X |

The formatter does not read IR order.
Formatting keeps every list and block order, so the IR keys see the same input.
Probe P6 of the analysis showed this for v0.4.0 [Observed].
This RFC keeps the formatter rules that P6 tested.

**FR2, FR3, FR4, FR6, FR8, and FR10 are leaves.**
Each has one list, flag, or set of blocks, one owning module (section 4.4), and
acceptance rows in section 5.3.
Chapter exclusivity (`EM014`) compares two chapters. Both are parts of DP3.
The workshop records keep the uncoupled matrix of the analysis (FR5.1 to FR5.3).

### 6.4 Cross-Boundary Checks

Local diagonal matrices do not prove independence across branches.
These shared items connect branches:

| Shared item | Owner | Who reads it | Effect on other FRs |
| --- | --- | --- | --- |
| Global ID spaces | FR1 | Every branch that names an element | None for accepted edits. A rename keeps list positions (section 6.2). |
| The one `board` block | FR2 | Board projection, off-board junction | None. The off-board set is a combined outcome. |
| The declaration union | FR4 | Binding | Layout cannot change content. Duplicates fail under FR1. |
| Event-sourced edges and origin flags | FR7, FR8 | Boundary-mark junction | None. The junction writes nothing back. |
| Judgment signals | FR7, FR10 | Policy evaluator | None. Severity and status are combined outcomes. |
| The core-failure gate | IR assembly | Every consumer | Fault propagation, described below. |

A dangling hotspot attachment remains a reference error.
An invalid title remains a syntax or attribute error.
Duplicate identities across files still reject the union.
These failures can block the whole model, despite independent valid edits.
This is fault propagation, not functional coupling.
An accepted edit of one DP still changes only its own FR.
A rejected edit of any DP prevents publication of all FRs together.

The proposed snapshot prevents mixing successful projections from different
loads. It does not define an atomic read across files that other processes edit.
Implementations must detect read failures and never publish a partial load.
A consistent filesystem snapshot or a quiescent source tree is an assumption
for split/rename comparisons.

Shared memory, CPU, and parser limits can affect every branch.
This RFC gives no resource-isolation or availability guarantee.
A large list, an unreadable file, or a parser failure can prevent all output.
The diagonal matrix is not a fault-isolation claim.

### 6.5 Alternatives Against the Same Requirements

| Alternative | Assessment |
| --- | --- |
| Use chapters as the order source in every file mode. | Removes the file-count switch, but fails FR2 and FR3 independence. Group edits still reorder the board. |
| Sort workflows by ID instead of adding a board. | Meets file-layout independence, but fails N2 when the desired story differs from ID order. |
| Give each workflow an order number. | Can meet FR2, but requires tie rules and distributed edits. A list gives one visible permutation. |
| Require an exhaustive board list. | Meets FR2, but a new workflow fails the board until an author lists it. FR2 gains an `X` under DP7, and the matrix becomes triangular. Rejected. |
| Append unlisted workflows to the board in ID order. | A rename moves an unlisted workflow. Identity then sets order, like derived titles. Rejected. |
| Add a judgment code for off-board workflows. | Brings back a coverage signal like `EM407`. The IR off-board set already shows these workflows. Not selected. |
| Resolve fields through an element's aggregate. | Does not cover screens, tables, or scenario steps uniformly. Fails the same FR1 criterion across all carriers. |
| Keep global inference and freeze the catalog. | Prevents N1's catalog growth scenario. It is not a feasible alternative. |
| Keep `translation` and `EM011`/`EM012`. | Keeps a redundant control. FR7 keeps an `X` under DP8. Rejected. |
| Keep both keywords and drop the cross-check. | Diagonal, but the two statements can disagree without a diagnostic. A model could then show a wrong pattern. Rejected. |
| Keep `translation` and remove the context flag. | Each workflow then restates origin. Two workflows could state different origins for one event. Rejected. |
| Merge `translation` into `automation` and derive a boundary mark. | Meets FR7 and FR8 independently. Removes a keyword from the source. Selected. |
| Separate profiles but still gate the IR with policy errors. | Renames responsibilities without removing the FR5 side effect. |
| Remove typed references and pattern rules. | Can erase matrix entries, but fails FR1 and FR7 and weakens N7. Rejected. |
| Split FR1 into declaration, lookup, type, and literal children. | Each child pairs a declaration with its uses, so the child matrix is triangular. Not selected. FR1 stays a leaf. |

The explicit controls are the selected candidate.
The recommendation is provisional on author effort, reader comprehension, and
consumer support.
It is not a numerical Information Axiom result.

### 6.6 Change Scenarios

Section 5.3 varies each DP at least once.
Each row predicts that one FR changes and that all other normalized fields
match.
A failure of any row is evidence of an influence that the matrix omits.
The matrix must then be corrected. A test must not hide the result.

### 6.7 Information Axiom and Evidence Limits

The Information Axiom compares probability of meeting the same requirements.
Its measure is `I = -log2(p)`.
Here, `p` means joint success across the required outcomes.
Fewer attributes, files, or modules do not establish lower information content.

There are no measured success probabilities for this proposed language.
Do not assign scores or assume independent success events.
A mistaken board migration or a shared parser failure can break several
requirements together.

Compare feasible alternatives with the same models and editing tasks.
Use single-file and folder models with repeated field-type names, chaptered and
unchaptered workflows, off-board workflows, external contracts, and unresolved
workshop questions.
Record completion time, repair edits, preserved bindings, preserved order, and
correct policy outcomes for each complete task.
Ask readers to identify each translation from the board, with the keyword and
with the derived mark only. This is measurement M3 of the analysis.
Use the same session length and correctness criteria for every candidate.
A task succeeds only when all required outcomes hold together.
These observations can support a joint probability estimate with uncertainty.

### 6.8 Open Decisions and Acceptance Gate

The language owners must assign a breaking release and accept the new syntax.
They must also accept these costs:

- A `board` block in every model, and off-board workflows without a diagnostic.
- Absent-title support in consumers.
- Removal of the `translation` keyword. Consumers must show the derived
  boundary mark.

The RFC selects concrete rules for each cost rather than leaving their
semantics to implementations.

Before release, the specification must include the complete diagnostic
registry, including the retired codes and new reservations.
The implementation must update discovery, validation, formatting, IR,
consumers, migration, examples, and the acceptance scenarios together.
The guides must describe translation as an automation that consumes an
external event. This affects the methodology guide (sections 6 and 7), the
learning guide, and the v0.2 migration guide.
No current-release examples or guides change until that cutover is accepted.

Adoption requires a migration comparison on the shipped examples and real
multi-file models. It also requires the cross-effect comparisons in section
5.3. Parsing the HCL examples alone does not establish proposed-language
conformance or whole-system independence.
