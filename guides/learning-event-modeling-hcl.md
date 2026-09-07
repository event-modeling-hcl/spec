# Event Modeling + `.em.hcl`
## A practice-first field guide for learning Event Modeling while authoring executable-looking models

> **Target:** after working through this guide, you should be able to run an Event Modeling conversation, identify the four slice patterns, encode the result as a valid `.em.hcl` document, and turn each important slice into precise pattern-specific scenarios (Given/When/Then for State Change; Given/Then for State View).
>
> **Normative language version:** Event Modeling HCL Specification **v0.3.0**.

---

## 0. How to use this guide

Do **not** read this like normal documentation.

Use this loop instead:

1. **Predict** — answer the prompt before looking at the example.
2. **Retrieve** — write the concept or HCL shape from memory.
3. **Compare** — inspect the worked example.
4. **Explain** — say why each block and reference exists.
5. **Produce** — change the example or build a neighboring one.
6. **Validate** — run the HCL validator.
7. **Revisit later** — repeat after a delay instead of rereading immediately.

This structure deliberately uses several learning effects supported by research:

- **Retrieval practice:** actively recalling information usually produces better long-term retention than simply rereading it.
- **Spacing:** revisiting material across separated sessions is generally better for durable retention than massing the same practice into one sitting.
- **Interleaving:** mixing similar-but-different problem types helps you learn to discriminate between them. This is especially useful here because `state_change`, `state_view`, `automation`, and `translation` look related but encode different causal structures.
- **Worked examples + fading:** first study a correct example, then complete a partially specified example, then create one independently.
- **Self-explanation:** explain *why* a model is valid, not merely *what* it contains.

A retrieval-practice study with fMRI evidence also found stronger engagement of regions associated with successful retrieval and semantic processing after retrieval practice across cognitive-ability groups. The practical recommendation here, however, rests mainly on the larger behavioral learning literature rather than on a simplistic "brain hack" claim.

### Suggested spaced schedule

This is a practical schedule, not a magic formula:

- **Session 1:** work through Sections 1-5.
- **Next day:** do the retrieval drill in Section 6 without rereading first.
- **~3 days later:** complete the faded HCL exercises.
- **~1 week later:** build the capstone from a blank file.
- **~2 weeks later:** rebuild one slice from memory and explain every reference aloud.

If you can reconstruct the model after forgetting some of it, that retrieval effort is useful practice.

### Current schema changes to memorize

If you learned an earlier draft, retrieve these five differences before continuing:

1. **One edge, one canonical spelling.** Workflow-local sources use `to`; catalog Events are consumed through the receiver's `from`. Reverse spellings are invalid.
2. **State View scenarios are GIVEN -> THEN.** They have one or more Event `given` steps, **no `when`**, and one or more Read Model / Error `then` steps. There is no `query` concept.
3. **Obvious titles are derived.** `pet_registered` already has the effective title `Pet Registered`; write `title` only to override the derived wording.
4. **Validation has profiles and stable diagnostics.** Use `workshop`, `valid` (default), or `strict`; diagnostics use stable `EMxxx` codes.
5. **Formatting and the typed IR are first-class.** `fmt` canonicalizes source presentation, while downstream tools consume the validated typed model rather than raw HCL.

---

# Part I — The Event Modeling mental model

## 1. Memorize the shape: **5 - 4 - 6 - 4**

A compact scaffold for the cheat sheet is:

- **5 elements**
- **4 patterns**
- **6 workshop stages**
- **4 anti-patterns / smells**

The cheat sheet also contains **20 Event Modeling rules** and **10 facilitation rules**, but the 5-4-6-4 scaffold gives you the structure into which those rules fit.

### Retrieval prompt

Before reading further, answer from memory if you already know Event Modeling:

1. What are the five elements?
2. What are the four patterns?
3. What does an Event represent that a Command does not?
4. What question must every Read Model answer?

Do not worry about being wrong. The attempt itself is part of the learning loop.

---

## 2. The five elements

### 2.1 Event — a fact that already happened

An Event is a concrete fact in the domain. It is named in the past tense.

Examples:

- `Appointment Added`
- `Pet Added`
- `Payment Received`
- `Weather Forecast Changed`

In `.em.hcl`, Events are **canonical contracts owned by a bounded context**:

```hcl
bounded_context "appointments" {
  event "appointment_added" {}
}
```

The block label is the identity (`appointment_added`). In the current schema, obvious human-facing titles are **derived automatically**: `appointment_added` becomes `Appointment Added`. Add an explicit `title` only when you want wording that differs from the label-derived default.

**Rule of thumb:** if the thing can still be rejected, it is probably not an Event yet.

---

### 2.2 Command — an intent to make something happen

A Command represents a request or intent. It can succeed or fail.

Examples:

- `Add Appointment`
- `Add Pet`
- `Cancel Subscription`

In HCL, Commands live **inside workflows** and point to the Event(s) they may produce:

```hcl
command "add_appointment" {
  to = [event.appointments.appointment_added]
}
```

A Command needs a reason to exist: an incoming flow, an API endpoint, or an explicit external trigger.

---

### 2.3 Read Model — an answer to a concrete question

A Read Model makes facts usable. It is not just "some projection" or "some DTO". The Event Modeling discipline is stricter:

> **No question, no Read Model.**

The HCL language makes that discipline explicit by requiring `question`:

```hcl
readmodel "calendar" {
  question = "Which appointments are on the calendar?"
  from     = [event.appointments.appointment_added]
}
```

A good Read Model is easy to test because you can state exactly what question it answers.

---

### 2.4 Screen — where an actor observes or initiates behavior

A Screen is a rough interaction surface: UI, wireframe, or other human-facing interaction point.

The cheat sheet emphasizes deliberately rough wireframes: keep the workshop focused on data and behavior, not visual design.

In HCL, a Screen can carry actor information, but a State View flow is declared canonically from the Read Model **to** the Screen:

```hcl
readmodel "calendar" {
  question = "Which appointments are on the calendar?"
  from     = [event.appointments.appointment_added]
  to       = [screen.calendar_ui]
}

screen "calendar_ui" {
  actor = actor.calendar_user
}
```

Actors are reusable catalog declarations. Their `title` can also be derived from the label:

```hcl
actor "calendar_user" {
  auth_required = true
}
```

---

### 2.5 Automation / gear — a machine reaction

On the visual cheat sheet, the gear means the computer reacts instead of a human.

There is an important HCL mapping to memorize:

> **Visual gear concept -> `processor` block.**  
> **Automation pattern -> `automation` workflow block.**

Example:

```hcl
automation "add_weather_forecast" {
  processor "weather_processor" {
    # from / to references omitted here
  }
}
```

This distinction prevents a common conceptual mistake: `automation` is not a nested element inside another workflow in v0.3.0; it is one of the four top-level workflow kinds.

---

# Part II — The four patterns

## 3. Learn the patterns by contrasting them

Interleaving works well when categories are similar enough to be confused. So do not learn each Event Modeling pattern in isolation. Compare them side by side.

| Pattern | Core question | Typical flow | Human? | External boundary? | HCL workflow |
|---|---|---|---|---|---|
| State Change | What does someone want to change? | Screen/API -> Command -> Event | Often | No requirement | `state_change` |
| State View | What does someone need to know? | Event -> Read Model -> Screen/UI | Often | No requirement | `state_view` |
| Automation | What should the system do next by itself? | Internal Event -> Read Model/Processor -> Command -> Event | No | **No external event input** | `automation` |
| Translation | How do we translate another context/system's fact into our language? | External Event -> Read Model/Processor -> Command -> Internal Event | No | **Yes** | `translation` |

### Retrieval cue

Cover the table and answer:

- Which pattern converts **intent into fact**?
- Which pattern converts **facts into an answer**?
- Which pattern is a **machine reaction to internal facts**?
- Which pattern is the same family of reaction but crosses an **external language/ownership boundary**?

---

## 4. State Change

### Mental model

A user or other trigger wants something to happen. The system evaluates the Command. If accepted, one or more Events record the resulting facts.

```text
Screen / API -> Command -> Event
```

### Minimal HCL shape

```hcl
actor "scheduler" {
  auth_required = true
}

bounded_context "appointments" {
  aggregate "appointment" {}

  event "appointment_added" {
    aggregate = aggregate.appointment
  }
}

state_change "schedule_appointment" {
  screen "schedule_appointment_ui" {
    actor = actor.scheduler
    to    = [command.add_appointment]
  }

  command "add_appointment" {
    aggregate = aggregate.appointments.appointment
    to        = [event.appointments.appointment_added]
  }
}
```

### What to notice

1. The Event is declared once inside the owning bounded context.
2. The workflow **references** the Event; it does not redeclare it.
3. `screen.schedule_appointment_ui -> command.add_appointment` is written once as `screen.to`.
4. `command.add_appointment -> event.appointments.appointment_added` is written once as `command.to`.
5. References are **unquoted traversals**, not strings.
6. Matching `title` attributes are omitted because the typed model derives them from labels.

### API-triggered commands

An API-triggered Command uses `api_endpoint` instead of inventing a fake Screen:

```hcl
command "add_pet" {
  api_endpoint = "POST /owners/{ownerId}/pets"
  to           = [event.pet_management.pet_added]
}
```

A Command must have a reason: a canonical incoming flow, an `api_endpoint`, or `external_trigger = true`.

## 5. State View

### Mental model

Facts already exist. A Read Model folds or interprets those facts so a user/API can answer one question.

```text
Event -> Read Model -> Screen
```

### Minimal HCL shape

```hcl
state_view "view_calendar" {
  readmodel "calendar" {
    question = "Which appointments are on the calendar?"
    from     = [event.appointments.appointment_added]
    to       = [screen.calendar_ui]
  }

  screen "calendar_ui" {
    actor = actor.calendar_user
  }
}
```

The canonical direction matters:

- catalog Event -> Read Model is written as `readmodel.from = [event...]`;
- Read Model -> Screen is written as `readmodel.to = [screen...]`;
- reverse `screen.from = [readmodel...]` is invalid.

### The discipline that matters

Bad:

```hcl
readmodel "data" {
  question = "What data do we need?"
}
```

That question is too vague to constrain implementation or testing.

Better:

```hcl
question = "Which appointments do not yet have a weather forecast?"
```

The question is a design tool. It tells you what information belongs in the projection and what does not.

**Scenario cue:** a State View is specified as **GIVEN Event(s) -> THEN Read Model**. There is no `query` concept and no `when` step in a State View scenario.

## 6. Automation

### Mental model

The system reacts to **its own internal facts** and issues a new Command without a user screen.

A common shape is:

```text
Internal Event -> Read Model -> Processor -> Command -> Event
```

HCL example:

```hcl
automation "add_weather_forecast" {
  readmodel "appointments_without_weather_forecast" {
    question = "Which appointments still need a weather forecast?"
    from     = [event.appointments.appointment_added]
    to       = [processor.weather_processor]
  }

  processor "weather_processor" {
    to = [command.add_weather_forecast]
  }

  command "add_weather_forecast" {
    to = [event.weather.weather_predicted_for_appointment]
  }
}
```

Notice the canonical source-to-target spelling: `readmodel.to -> processor`, then `processor.to -> command`. Reverse forms such as `processor.from = [readmodel...]` and `command.from = [processor...]` are invalid.

An `automation` must **not** consume an Event from an external bounded context. If it does, the workflow is a Translation.

## 7. Translation

### Mental model

Another context or external system speaks in its own language. Your system should not simply leak that language everywhere.

A Translation takes an external fact and turns it into a Command/Event in the receiving context's language.

```text
External Event -> Read Model / Processor -> Command -> Internal Event
```

First mark the source context as external:

```hcl
system "weather_provider" {
  external = true
}

bounded_context "weather_provider" {
  external = true
  owner    = system.weather_provider

  event "weather_forecast_changed" {}
}
```

Then translate it:

```hcl
translation "translate_weather_change" {
  readmodel "changed_predictions" {
    question = "Which external weather predictions changed?"
    from     = [event.weather_provider.weather_forecast_changed]
    to       = [processor.translator]
  }

  processor "translator" {
    to = [command.translate_changed_weather]
  }

  command "translate_changed_weather" {
    to = [event.weather.updated_weather_prediction]
  }
}
```

A Translation must consume at least one Event from an external bounded context. The same canonical edge rule applies as in Automation.

A Translation can also feed an external Event directly into a Processor when no Read Model is needed:

```hcl
processor "translator" {
  from = [event.partner.payment_captured]
  to   = [command.confirm_order]
}
```

# Part III — From workshop to `.em.hcl`

## 8. The six workshop stages and their HCL destination

The cheat sheet's workshop is a progression from discovery to testable rules.

| Workshop stage | Goal | What you discover | Where it ends up in HCL |
|---|---|---|---|
| 1. Brainstorming | collect events | facts that happen | `event` blocks inside `bounded_context` |
| 2. The plot | find the story | business-time order | workflow source order; chapters when useful |
| 3. Storyboarding | common understanding | actor-visible screens | `actor`, `screen`, optionally `screen_image` |
| 4. Input / Output | information flow | Commands, Read Models, arrows | `command`, `readmodel`, `processor`, `from`, `to` |
| 5. Swimlanes | ownership | teams/systems/contexts that own data | `bounded_context`, `team`, `system`, `owner`, `external` |
| 6. Scenarios | business rules | pattern-specific scenarios: State Change uses Given/When/Then; State View uses Given/Then | `scenario`, `given`, `when`, `then`, `comment` |

Two anchor questions from the cheat sheet are particularly useful during discovery:

- **What is the first Event? What is the last Event?**
- **What happens next?**

When you reach scenarios, repeatedly ask whether there is a business rule you still have not covered.

---

## 9. Workshop mode and authoring mode are different

### Workshop mode

Optimize for shared understanding:

- start with Events;
- talk about facts and intent, not frameworks;
- avoid polishing diagrams;
- keep slices small;
- park uncertainty as a hotspot;
- avoid implementation arguments unless they affect business behavior.

### Authoring mode

Now become precise:

- identify bounded-context ownership;
- give contracts stable identities;
- add fields and reusable field types;
- add typed references;
- make every Read Model answer a concrete question;
- encode scenarios;
- validate the file.

Do not let the precision of HCL pull implementation detail *back into* the discovery workshop too early.

---

# Part IV — The `.em.hcl` language

## 10. The document model

A `.em.hcl` file contains three broad categories:

```text
catalog declarations
workshop notation
workflows
```

### Catalog declarations

- `bounded_context`
- `actor`
- `team`
- `system`

Inside a bounded context:

- `aggregate`
- `field_type`
- `event`

### Workshop notation

- `chapter`
- `hotspot`

### Workflows

- `state_change`
- `state_view`
- `automation`
- `translation`

A current v0.3.0 model is **one `.em.hcl` document**.

### Source syntax vs typed model

`.em.hcl` is the human/LLM authoring syntax. After validation, downstream tooling should consume the normalized typed model / IR rather than reason directly from raw HCL. The typed model exposes effective derived titles and a canonical source-to-target `Edges` list.

The IR also distinguishes semantic information from presentation information. For example, `aggregate`, `from`, `to`, `question`, and `actor` affect the modeled behavior/contracts, while `group_id`, `tags`, `sketched`, `prototype`, and `list_element` are presentation/workshop metadata.

---

## 11. Identities, derived titles, and source order

### Block labels are identities

```hcl
state_change "add_pet" {}
```

- identity: `add_pet`
- effective display title: `Add Pet`

Labels use `lower_snake_case`. Do not repeat identity using `id`, `name`, `type`, `slice_type`, or an index attribute.

### Titles are usually derived

For labeled declarations, matching human-facing titles are optional. The typed model title-cases the label:

```text
pet_registered       -> Pet Registered
students_to_welcome  -> Students To Welcome
```

Use an explicit title only when you intentionally want different wording or capitalization:

```hcl
event "payment_failed" {
  title = "Card Payment Was Declined"
}
```

The formatter does **not** write derived titles back into source. Required semantic data stays required: for example `readmodel.question`, `actor.auth_required`, field `type`, hotspot `question`, and chapter `workflows`.

### Source order is model order

Do not add bookkeeping such as:

```hcl
index    = 4
spec_row = 12
```

The file itself carries the order. Keep workflows in business-time order so the file reads like the Event Model from left to right. The formatter preserves block and scenario-step order.

## 12. Typed references: the most important HCL syntax habit

The language deliberately distinguishes literal data from relationships.

### Quoted values are data

```hcl
description = "Registers a new pet."
title       = "Register a Pet" # explicit override; usually optional
```

### Unquoted traversals are references

```hcl
to    = [event.pet_management.pet_added]
actor = actor.clinic_staff
```

### Do not do this

```hcl
to = ["event.pet_management.pet_added"]
```

That is a string, not a typed reference.

### Useful reference forms

| Target | Form |
|---|---|
| bounded context | `bounded_context.clinic` |
| actor | `actor.clinic_staff` |
| team | `team.clinic_team` |
| system | `system.partner` |
| workflow | `workflow.add_pet` |
| Event | `event.pet_management.pet_added` |
| aggregate | `aggregate.pet_management.pet` |
| local aggregate while inside owning context | `aggregate.pet` |
| field type | `field_type.pet_management.pet_id` |
| local field type while inside owning context | `field_type.pet_id` |
| local workflow element | `command.add_pet` |
| workflow-qualified element for hotspot | `command.add_pet.add_pet_command` |

The last form is useful when a top-level hotspot needs to point into a particular workflow.

---

## 13. Bounded contexts own domain contracts

Events, aggregates, and field types belong to a bounded context.

```hcl
bounded_context "pet_management" {
  aggregate "pet" {}

  field_type "pet_id" {
    type         = "Int"
    id_attribute = true
    example      = 5
  }

  event "pet_added" {
    aggregate = aggregate.pet

    field "pet_id" {
      type = field_type.pet_id
    }
  }
}
```

Notice the local references inside the owning context:

```hcl
aggregate = aggregate.pet
 type      = field_type.pet_id
```

Outside that context, use the qualified form:

```hcl
aggregate.pet_management.pet
field_type.pet_management.pet_id
event.pet_management.pet_added
```

---

## 14. Aggregates

An aggregate is a context-owned consistency boundary.

```hcl
aggregate "pet" {
  title       = "Pet"
  description = "Consistency boundary for pet details."
}
```

`title` and `description` are optional for aggregates in v0.3.0.

Commands and Events may reference aggregates, and they may declare aggregate dependencies when behavior spans another consistency boundary:

```hcl
aggregate_dependencies = [aggregate.owner_management.owner]
```

Do not treat aggregates as a substitute for Event Modeling. The behavior timeline still comes first.

---

## 15. Reusable field types

Use a `field_type` when the same ubiquitous-language concept appears in multiple contracts.

```hcl
field_type "owner_id" {
  type         = "Int"
  example      = 42
  id_attribute = true
}
```

Then reuse it. When the field name matches the `field_type` name, drop the
`type` and let it infer:

```hcl
field "owner_id" {}
```

The inferred `field_type` is the same-named one in the field's own bounded
context (for a field inside an `event` or a `subfield`) or, for a field on a
workflow element such as a `screen` or `command`, the unique `field_type` of
that name anywhere in the document. Write the `type` explicitly when the names
differ or the bare name is ambiguous:

```hcl
field "created_by" {
  type = field_type.owner_management.owner_id
}
```

To attach several typed fields at once, list their field types:

```hcl
fields = [field_type.owner_management.owner_id, field_type.owner_management.owner_name]
```

Each entry becomes one field named after the last segment of the reference. Use
a `field` block instead when a field needs `id_attribute`, `example`,
`optional`, or `pii`. List entries come first, then any `field` blocks.

For one-off technical or transport data, a built-in type can be inline:

```hcl
field "request_id" {
  type = "UUID"
}
```

A `field_type` declaration always states an explicit built-in type; only plain
`field` blocks infer.

Supported built-in types in v0.3.0:

`String`, `Boolean`, `Double`, `Decimal`, `Long`, `Custom`, `Date`, `DateTime`, `UUID`, `Int`.

Fields are required by default. Use:

```hcl
optional = true
```

only when absence is genuinely valid.

Use:

```hcl
pii = true
```

for personally identifiable information.

---

## 16. Lists and structured data

A custom reusable field type can contain nested subfields:

```hcl
field_type "owner_pets" {
  type        = "Custom"
  cardinality = "List"

  example = [{
    id        = 5
    name      = "Mochi"
    birthDate = "2020-01-12"
    type      = "Cat"
  }]

  subfield "id" {
    type         = "Int"
    id_attribute = true
  }

  subfield "name" {
    type = "String"
  }
}
```

Examples are native HCL literals, and the validator checks that examples match the effective type.

---

## 17. One edge, one canonical declaration

The current schema does **not** allow you to choose either endpoint. Each semantic edge has one canonical spelling. This reduces ambiguity for humans, diffs, formatters, and LLM generation.

### Rule 1 — workflow-local source: write `to` on the source

```hcl
screen "add_pet_form" {
  to = [command.add_pet]
}

command "add_pet" {
  to = [event.pet_management.pet_added]
}
```

Do **not** reverse the first edge onto the Command:

```hcl
# Invalid
command "add_pet" {
  from = [screen.add_pet_form]
}
```

### Rule 2 — catalog Event source: write `from` on the receiver

Catalog Events do not contain workflow-specific edges, so the receiving element records the incoming relationship:

```hcl
readmodel "pets" {
  question = "Which pets are registered?"
  from     = [event.pet_management.pet_added]
  to       = [screen.pets]
}

screen "pets" {}
```

The canonical patterns are:

- State Change: `screen.to -> command`; `command.to -> event`
- State View: `event -> readmodel.from`; `readmodel.to -> screen`
- Automation/Translation: `event -> readmodel.from` or `processor.from`; `readmodel.to -> processor`; `processor.to -> command`; `command.to -> event`

Reverse forms such as `screen.from = [readmodel...]`, `processor.from = [readmodel...]`, and `command.from = [processor...]` are invalid.

### Retrieval rule

When unsure where an edge goes, ask:

> **Who is the source?**

If the source is a workflow element, put `to` on it. If the source is a catalog Event, put `from` on the receiving workflow element.

# Part V — Scenarios: make the slice testable

## 18. Scenario grammar is pattern-specific

A `scenario` lives beside the workflow it specifies. Its `title` is optional and is derived from the label when omitted. Source order is scenario order.

The important change is that **not every pattern has a `when` step**:

| Workflow | Given | When | Then | Cardinality |
|---|---|---|---|---|
| State Change | Event | Command | Event or Error | zero or more `given`, exactly one `when`, one or more `then` |
| State View | Event | **none** | Read Model or Error | one or more `given`, **zero `when`**, one or more `then` |
| Automation / Translation | Event or Read Model | Processor or Command | Event or Error | exactly one `when`, one or more `then` |

Each step has exactly one typed target. `error` is a literal string.

There is **no `query` target or Query concept** in the language.

## 19. State Change scenario

Mental shape:

```text
Given Event(s)
When  Command
Then  Event or Error
```

Example:

```hcl
scenario "add_pet_success" {
  given {
    event = event.owner_management.owner_registered
  }

  when {
    command = command.add_pet
  }

  then {
    event = event.pet_management.pet_added
  }
}
```

Error path:

```hcl
scenario "add_pet_validation_error" {
  when {
    command = command.add_pet
  }

  then {
    error = "Pet name is required"
  }

  comment {
    description = "A pet must have a name before it can be registered."
  }
}
```

A semantic scenario note belongs in a `comment` block. Normal HCL comments are not semantic model content.

## 20. State View scenario

Mental shape:

```text
Given Event(s)
Then  Read Model or Error
```

This mirrors the Event Modeling examples directly: **Given Student Registered, then Students to Welcome**. There is no artificial Query or `when` step.

```hcl
scenario "registered_student_needs_welcome" {
  given {
    event = event.students.student_registered
  }

  then {
    readmodel = readmodel.students_to_welcome
  }
}
```

A State View scenario must have at least one Event `given`, **no `when` blocks**, and one or more `then` steps. A `query = ...` attribute is unknown syntax and is rejected.

## 21. Automation / Translation scenarios

For an Automation or Translation scenario:

- `given` targets an Event or Read Model;
- there is exactly one `when`;
- `when` targets a Processor or Command;
- `then` targets an Event or Error.

This lets the scenario specify machine-driven behavior without inventing a fake human Screen.

# Part VI — Workshop notation in HCL

## 22. Actors

```hcl
actor "clinic_staff" {
  title         = "Clinic staff"
  auth_required = true
}
```

Screens can reference actors to preserve the actor-lane information from the workshop.

---

## 23. Teams and systems

```hcl
team "clinic_team" {
  title = "Clinic Team"
}

system "weather_provider" {
  title    = "Weather Provider"
  external = true
}
```

These declarations can own bounded contexts and encode the ownership knowledge discovered in swimlanes.

---

## 24. Hotspots

Do not guess when the domain is unclear.

```hcl
hotspot "weather_source" {
  question = "Which provider is authoritative for changed forecasts?"
  status   = "open"
  on       = workflow.translate_weather_change
}
```

A hotspot is durable model information: an unresolved question, blocker, or dispute that should remain visible until resolved.

The visual workshop uses red notes; HCL uses a `hotspot` block.

---

## 25. Chapters

Chapters group **contiguous** workflow ranges.

```hcl
chapter "pet_registration" {
  title = "Pet Registration"
  workflows = [
    workflow.show_owner_details,
    workflow.add_pet,
    workflow.list_pet_types,
  ]
}
```

The validator rejects a non-contiguous chapter.

---

## 26. Workflow status

Allowed workflow status values:

- `created`
- `planned`
- `assigned`
- `in_progress`
- `review`
- `blocked`
- `done`
- `informational`

Example:

```hcl
state_change "add_pet" {
  title  = "Add Pet"
  status = "planned"
}
```

The cheat sheet uses status to communicate implementation state while keeping the slice itself as the unit of behavior.

---

# Part VII — The anti-patterns: train your eyes

## 27. Left chair

Shape:

```text
1 Command -> many Events
```

Possible meaning: the Command is doing too much or mixing several business capabilities.

This is **not automatically invalid**. It is a smell to investigate.

Ask:

> If I split this Command by user intent, do the Events naturally separate?

---

## 28. Right chair

Shape:

```text
many Events -> 1 Read Model
```

Possible meaning: the Read Model is answering several questions at once.

Ask:

> Can I state the Read Model's question in one precise sentence?

If not, split the view by question.

---

## 29. Bed

Shape:

```text
1 Screen -> many Commands
```

Possible meaning: the screen is bundling unrelated intents.

Ask:

> Is this one user goal or several independent actions merely placed on the same UI?

UI layout alone should not define your behavioral slices.

---

## 30. Shelf

Shape:

```text
1 workflow -> many scenarios
other workflows -> none
```

Possible meaning: the team wrote scenarios for one convenient slice and stopped specifying the rest of the model.

Ask:

> Which important slices still rely on implicit business rules?

---

# Part VIII — What the validator can and cannot do

## 31. Hard errors, diagnostics, and validation profiles

The validator rejects problems such as:

- invalid HCL or unknown syntax;
- invalid labels or nesting;
- missing required semantic attributes;
- wrong literal types and invalid examples;
- duplicate identities;
- unresolved or wrong-kind references;
- non-canonical / invalid flow directions;
- invalid pattern-specific scenario structure or targets;
- non-contiguous chapters;
- incorrect Automation/Translation externality.

Run the default `valid` profile:

```text
eventmodeling-hcl validate my-model.em.hcl
```

Or choose explicitly:

```text
eventmodeling-hcl validate --profile workshop my-model.em.hcl
eventmodeling-hcl validate --profile valid my-model.em.hcl
eventmodeling-hcl validate --profile strict my-model.em.hcl
```

Diagnostics use stable `EMxxx` codes: `EM0xx` structural, `EM1xx` references, `EM2xx` flow, `EM3xx` scenarios, and `EM4xx` modeling judgment. Treat diagnostics as part of the authoring loop, not a final ceremony.

After validation, canonicalize the source:

```text
eventmodeling-hcl fmt -w my-model.em.hcl
```

Formatting normalizes whitespace and attribute order but preserves semantically meaningful block and scenario order.

## 32. Warnings, profiles, and human judgment

Some Event Modeling quality checks need judgment rather than hard rejection:

- Command with no incoming flow, API endpoint, or explicit external trigger (`EM404`);
- left chair;
- right chair;
- bed;
- shelf;
- open hotspot (`EM406`).

Profile behavior:

- `workshop`: judgment diagnostics are informational, so incomplete discovery remains easy to work with;
- `valid` (default): judgment diagnostics are warnings;
- `strict`: an unreasoned Command (`EM404`) and open hotspot (`EM406`) become errors; the four visual smells remain non-blocking judgment signals.

A valid file can still be a poor model.

> **Syntax and reference correctness are machine-checkable. Business clarity is not fully machine-checkable.**

Use strictness to make an agent-ready model more explicit; do not use permissiveness to hide uncertainty. Unknown business facts belong in `hotspot` blocks.

# Part IX — The 20 Event Modeling rules, organized for memory

Instead of memorizing a flat list, chunk them into five groups.

## 33. Facts and time

1. Start with Events.
2. Model facts rather than speculative ideas.
3. Read business time from left to right.
4. If order is unclear, capture a hotspot.
5. Name things by intent.

### HCL consequence

Declare canonical past-tense Events, preserve meaningful source order, and use `hotspot` rather than inventing certainty.

---

## 34. Use the four patterns deliberately

6. Keep to the four Event Modeling patterns.
7. Distinguish State Change, State View, Automation, and Translation.
8. Every Command needs a reason.
9. Do not add Commands merely to fill a diagram.
10. Every Read Model answers a question.
11. Without a question, do not create a Read Model.

### HCL consequence

The language gives you four workflow block kinds, typed flow directions, `api_endpoint`, `external_trigger`, and mandatory `readmodel.question`.

---

## 35. Treat uncertainty as information

12. Do not guess.
13. Unknowns become hotspots.

### HCL consequence

Use a `hotspot` block and resolve it later without weakening contracts everywhere else.

---

## 36. Keep slices small

14. Keep slices small.
15. Aim for one business capability per slice.
16. Prefer simplicity.
17. Suspicious complexity often signals a modeling problem.

### HCL consequence

Each workflow should be independently valuable and independently testable. Use anti-pattern warnings as prompts to split overloaded slices.

---

## 37. Optimize for shared understanding

18. Optimize for conversation.
19. Shared understanding matters more than pretty diagrams.
20. Model behavior rather than static structure.

### HCL consequence

Do not turn `.em.hcl` into an object-model dump. The file should still read as a story of behavior and information flow.

---

# Part X — A practical authoring algorithm

## 38. Start from a blank `.em.hcl` file

Use this sequence.

### Step 1 — Write only the Events in plain language

Example:

```text
Appointment Added
Weather Predicted for Appointment
Weather Forecast Changed
Updated Weather Prediction
```

Do not think about classes, tables, endpoints, Kafka topics, or controllers yet.

### Step 2 — Put them in business-time order

Ask:

- What is first?
- What is last?
- What happens next?

Record uncertainty as hotspots.

### Step 3 — Assign ownership

Which bounded context owns each fact?

Example:

```text
Appointments       -> Appointment Added
Weather            -> Weather Predicted for Appointment
Weather Provider   -> Weather Forecast Changed   [external]
Weather            -> Updated Weather Prediction
```

### Step 4 — Declare contexts, Events, and reusable field types

Now begin HCL.

### Step 5 — Identify slices

For each transition, choose **one of four** patterns.

Do not invent a fifth causal shape.

### Step 6 — Add screens, Commands, Read Models, and processors

Add only the elements required by the pattern.

### Step 7 — Add canonical flows

Use typed traversals and write each edge exactly once in its canonical direction:

- workflow-local source -> `to` on the source;
- catalog Event source -> `from` on the receiver.

### Step 8 — Add fields

Prefer reusable `field_type` for domain concepts that recur.

### Step 9 — Add scenarios

Happy path first, then business-rule failures.

### Step 10 — Format and validate

```text
eventmodeling-hcl fmt -w my-model.em.hcl
eventmodeling-hcl validate my-model.em.hcl
```

Before handing the model to a software-generating agent, also run:

```text
eventmodeling-hcl validate --profile strict my-model.em.hcl
```

### Step 11 — Review smells

Search for:

- left chair;
- right chair;
- bed;
- shelf;
- vague Event names;
- vague Read Model questions;
- Commands with no reason;
- external facts modeled as internal automation.

---

# Part XI — Worked example -> faded example -> independent example

## 39. Worked example: Pet registration

Read the whole slice once. Then close it and redraw the flow from memory. Notice how the current schema removes redundant titles while keeping semantic constraints explicit.

```hcl
actor "clinic_staff" {
  auth_required = true
}

bounded_context "owner_management" {
  event "owner_registered" {}
}

bounded_context "pet_management" {
  aggregate "pet" {}

  field_type "pet_name" {
    type    = "String"
    example = "Mochi"
    pii     = true
  }

  event "pet_added" {
    aggregate = aggregate.pet

    field "pet_name" {
      type = field_type.pet_name
    }
  }
}

state_change "add_pet" {
  screen "add_pet_form" {
    actor = actor.clinic_staff
    to    = [command.add_pet]
  }

  command "add_pet" {
    to = [event.pet_management.pet_added]

    field "pet_name" {
      type = field_type.pet_management.pet_name
    }
  }

  scenario "add_pet_success" {
    given {
      event = event.owner_management.owner_registered
    }

    when {
      command = command.add_pet
    }

    then {
      event = event.pet_management.pet_added
    }
  }

  scenario "add_pet_validation_error" {
    when {
      command = command.add_pet
    }

    then {
      error = "Pet name is required"
    }
  }
}
```

### Self-explanation prompts

Answer without looking back:

1. Why is `pet_added` not declared inside `state_change "add_pet"`?
2. Why is `pet_name` a `field_type` rather than just a string literal everywhere?
3. Why is `event.pet_management.pet_added` qualified but `command.add_pet` local?
4. What makes `add_pet_validation_error` a State Change scenario?
5. Which element gives the Command a reason to exist?
6. Which titles are omitted, and how will their effective titles be derived?

---

## 40. Faded example: complete a State View

Fill every `???` before opening the answer. Pay special attention to **canonical flow direction** and the absence of `when`.

```hcl
state_view "show_pet_details" {
  readmodel "pet_details" {
    question = ???
    from     = [???]
    to       = [???]
  }

  screen "pet_details_screen" {
    actor = ???
  }

  scenario "pet_details_loaded" {
    given {
      event = ???
    }

    then {
      readmodel = ???
    }
  }
}
```

<details>
<summary>Answer</summary>

```hcl
state_view "show_pet_details" {
  readmodel "pet_details" {
    question = "What are the current details of this pet?"
    from     = [event.pet_management.pet_added]
    to       = [screen.pet_details_screen]
  }

  screen "pet_details_screen" {
    actor = actor.clinic_staff
  }

  scenario "pet_details_loaded" {
    given {
      event = event.pet_management.pet_added
    }

    then {
      readmodel = readmodel.pet_details
    }
  }
}
```

</details>

## 41. Independent example: choose the pattern first

Problem:

> An external payment provider emits `PaymentCaptured`. Your Orders context should react by issuing `ConfirmOrder`, producing `OrderConfirmed`.

Before writing HCL, answer:

1. State Change, State View, Automation, or Translation?
2. Which bounded context must be marked external?
3. What is the incoming Event?
4. What Command is issued in your language?
5. What Event is produced in your language?

<details>
<summary>Pattern answer</summary>

This is a **Translation**, because the initiating Event belongs to an external bounded context/system.

A likely causal shape is:

```text
PaymentCaptured [external]
    -> payment read model / translator processor
    -> ConfirmOrder
    -> OrderConfirmed [internal]
```

</details>

Write the HCL yourself before comparing it to any example.

---

# Part XII — Error-spotting drills

## 42. Interleaved validity quiz

For each item decide:

- **invalid** — validator-level problem;
- **valid but suspicious** — Event Modeling warning/smell;
- **valid**.

### A

```hcl
event "order_placed" {
  title = "Order Placed"
}
```

<details><summary>Answer</summary>
Invalid. Events are bounded-context-owned contracts and must be inside a `bounded_context`.
</details>

### B

```hcl
to = ["event.orders.order_placed"]
```

<details><summary>Answer</summary>
Invalid. Relationships are typed, unquoted HCL traversals.
</details>

### C

```hcl
readmodel "order_summary" {
  title = "Order Summary"
}
```

<details><summary>Answer</summary>
Invalid. A Read Model requires a concrete `question`.
</details>

### D

```text
One command -> five semantically unrelated events
```

<details><summary>Answer</summary>
Potentially valid HCL, but a **left chair** smell. Investigate whether several capabilities are hidden inside one Command.
</details>

### E

```text
One screen -> four unrelated commands
```

<details><summary>Answer</summary>
Potentially valid HCL, but a **bed** smell.
</details>

### F

A `translation` consumes only `event.orders.order_placed`, where `orders` is internal.

<details><summary>Answer</summary>
Invalid under the v0.3.0 Translation externality rule. A Translation must consume at least one Event from an external bounded context.
</details>

### G

A **State Change** scenario contains two `when` blocks.

<details><summary>Answer</summary>
Invalid. State Change scenarios require exactly one `when`, and it targets a Command.
</details>

### H

A State View scenario contains:

```hcl
when {
  query = readmodel.order_summary
}
```

<details><summary>Answer</summary>
Invalid twice over. State View scenarios have **zero `when` blocks**, and `query` is not part of the language. Use one or more Event `given` steps followed by one or more `then { readmodel = ... }` steps.
</details>

---

# Part XIII — Facilitation rules you should actually use

## 43. Before the workshop

Make sure:

- there is a facilitator;
- the scope/context is explicit;
- the right domain experts are present;
- the session is small enough to sustain attention.

## 44. During the workshop

Protect the conversation from common failure modes:

- implementation arguments too early;
- polishing wireframes;
- debates that consume the session;
- unanswered uncertainty that silently becomes an assumption;
- modeling a huge domain in one sitting.

Event Modeling is primarily a **communication technique**. The HCL file is valuable because it preserves and sharpens the shared model, not because textual syntax is inherently superior to a board.

---

# Part XIV — A 15-minute daily practice loop

## 45. Minute 0-2 — retrieval

From a blank page write:

```text
5 elements:
4 patterns:
4 anti-patterns:
6 workshop stages:
```

No notes.

## 46. Minute 2-5 — one contrast

Choose two patterns and state the difference in one sentence.

Examples:

- State Change vs State View
- Automation vs Translation

## 47. Minute 5-10 — HCL generation

Write one minimal workflow from memory.

Rotate:

- Monday: State Change
- Tuesday: State View
- Wednesday: Automation
- Thursday: Translation
- Friday: one success + one error scenario

## 48. Minute 10-13 — validator feedback

Run:

```text
eventmodeling-hcl validate practice.em.hcl
```

Do not immediately patch errors blindly. First predict why the validator complained.

## 49. Minute 13-15 — self-explanation

Answer aloud:

1. What business question does this slice answer?
2. Why is this the correct one of the four patterns?
3. What owns the Event data?
4. What would make this slice too large?
5. Which scenario would break first if my assumption were wrong?

---

# Part XV — Compact `.em.hcl` checklist

## 50. Catalog

- [ ] Every Event belongs to a `bounded_context`.
- [ ] Events are concrete past-tense facts.
- [ ] Shared ubiquitous-language data concepts use `field_type`.
- [ ] Aggregates model actual consistency boundaries rather than arbitrary entities.
- [ ] External systems/contexts are marked `external = true` where appropriate.
- [ ] Actors, teams, and systems have stable lower-snake-case identities.

## 51. Workflows

- [ ] Every workflow is one independently useful/testable slice.
- [ ] Workflow kind is exactly one of `state_change`, `state_view`, `automation`, `translation`.
- [ ] Each Command has a reason.
- [ ] Each Read Model has one concrete `question`.
- [ ] Automation consumes internal facts.
- [ ] Translation consumes at least one external Event.
- [ ] Flows use valid element directions for the workflow kind.
- [ ] Each edge is expressed once.

## 52. References

- [ ] Relationships are unquoted traversals.
- [ ] Context-owned Events use `event.<context>.<event>`.
- [ ] Workflow-local elements use forms such as `command.<id>`.
- [ ] No dynamic/computed references, function calls, or interpolated references.

## 53. Fields

- [ ] Every `field` / `subfield` has a `type`.
- [ ] `optional = true` means absence is valid, not merely inconvenient.
- [ ] `pii = true` is set where appropriate.
- [ ] `example` values match the effective type.
- [ ] `cardinality = "List"` is used only for list-valued data.

## 54. Scenarios

- [ ] Every important slice has scenarios.
- [ ] `when` cardinality matches the pattern (State Change and Automation/Translation: exactly one; State View: none).
- [ ] At least one `then`.
- [ ] Happy path exists.
- [ ] Important error/business-rule path exists.
- [ ] State Change: When -> Command.
- [ ] State View: Given Event(s) -> Then Read Model (no `when`, no `query`).
- [ ] Automation/Translation: machine action is modeled with Processor/Command targets.
- [ ] Semantic notes use `comment` blocks.

## 55. Workshop quality

- [ ] Unknowns are hotspots, not guesses.
- [ ] No unexplained left chair.
- [ ] No unexplained right chair.
- [ ] No unexplained bed.
- [ ] No shelf-like scenario imbalance.
- [ ] Workflow order still reads like the business story.

---

# Part XVI — Current v0.3.0 boundaries

The current specification explicitly does **not** provide:

- multi-file model loading;
- cross-file reference resolution;
- context-map syntax;
- HCL formatting;
- JSON conversion / round-tripping;
- inferred causal relationships that were not authored.

That matters when designing repository tooling: a folder full of `.em.hcl` files can be managed by tooling around the language, but **v0.3.0 itself validates one model document at a time**.

---

# Part XVII — Mastery test

## 56. Closed-book questions

Try these without looking up the answers.

1. Why is an Event different from a Command?
2. What single attribute makes Read Models more disciplined in `.em.hcl`?
3. Where are Events declared?
4. Why are Event references not strings?
5. What is the local reference form for a Command inside its workflow?
6. What is the fully qualified reference for `pet_added` in `pet_management`?
7. What is the difference between Automation and Translation?
8. What does the visual gear map to in HCL?
9. What is the left-chair smell?
10. What is the right-chair smell?
11. What is the bed smell?
12. What is the shelf smell?
13. How many `when` blocks must a State Change scenario contain?
14. What can a State Change `then` target?
15. What is the State View scenario shape, and how many `when` blocks does it contain?
16. When should an unknown become a hotspot?
17. What does `external = true` change semantically?
18. What does `source order is model order` let you avoid?
19. What commands format a model and validate it with the strict profile?
20. Name three things the validator cannot replace human judgment about.

### Mastery criterion

You are ready to use this in real work when you can:

- answer at least ~16/20 from memory;
- create one State Change and one State View without documentation;
- distinguish Automation from Translation immediately;
- encode one success and one failure scenario;
- validate the file and understand the diagnostics rather than just fixing them mechanically.

---

# Part XVIII — Capstone

## 57. Build this from a blank file

Domain: subscription billing.

Facts:

- `Subscription Started`
- `Trial Ending Soon`
- external provider: `Payment Captured`
- `Subscription Activated`
- `Payment Failed`

Actors/systems:

- customer
- billing team
- external payment provider

Capabilities:

1. Customer starts a subscription.
2. Customer views subscription status.
3. The system reminds customers shortly before a trial ends.
4. An external payment capture is translated into activation of the subscription.

Your task:

1. Identify bounded contexts.
2. Declare Events.
3. Choose one of the four patterns for each capability.
4. Add Commands / Read Models / Screens / Processors.
5. Add at least one Read Model question per State View.
6. Add one success scenario to every workflow.
7. Add at least two error scenarios across the model.
8. Add one hotspot for a deliberately unresolved business rule.
9. Add one chapter covering a contiguous group of workflows.
10. Validate the file.

### Reflection

After it validates, ask:

- Is every workflow one business capability?
- Did I accidentally model UI layout instead of behavior?
- Did I put external-provider language inside my own context instead of translating it?
- Does every Read Model answer one clear question?
- Are the scenarios strong enough that another engineer or coding agent could implement the behavior without guessing?

---

# Appendix A — Four workflow templates

These templates intentionally omit derivable titles and use only canonical flow spellings.

## State Change

```hcl
state_change "workflow_id" {
  screen "screen_id" {
    actor = actor.some_actor
    to    = [command.command_id]
  }

  command "command_id" {
    to = [event.context.event_id]
  }

  scenario "success" {
    when { command = command.command_id }
    then { event = event.context.event_id }
  }
}
```

## State View

```hcl
state_view "workflow_id" {
  readmodel "readmodel_id" {
    question = "What exact question does this answer?"
    from     = [event.context.event_id]
    to       = [screen.screen_id]
  }

  screen "screen_id" {
    actor = actor.some_actor
  }

  scenario "view_is_updated" {
    given { event = event.context.event_id }
    then  { readmodel = readmodel.readmodel_id }
  }
}
```

## Automation

```hcl
automation "workflow_id" {
  readmodel "readmodel_id" {
    question = "Which internal facts require action?"
    from     = [event.internal_context.event_id]
    to       = [processor.processor_id]
  }

  processor "processor_id" {
    to = [command.command_id]
  }

  command "command_id" {
    to = [event.internal_context.result_event]
  }
}
```

## Translation

```hcl
translation "workflow_id" {
  readmodel "readmodel_id" {
    question = "Which external facts require translation?"
    from     = [event.external_context.external_event]
    to       = [processor.translator]
  }

  processor "translator" {
    to = [command.command_id]
  }

  command "command_id" {
    to = [event.internal_context.internal_event]
  }
}
```

# Appendix B — Sources and evidence behind this guide

## Event Modeling sources

- **Event Modeling Cheat Sheet**, Nebulit / eventmodelers.ai: https://eventmodelers.ai/cheatsheet/
- **Event Modeling Cheat Sheet PDF** supplied with this guide request.
- **Event Modeling HCL Specification v0.2.0** supplied with the schema update. This is treated as the normative source for `.em.hcl` syntax, canonical flow, scenario rules, diagnostics, validation profiles, formatting, and typed IR behavior.
- **Migrating to v0.2.0** supplied with the schema update informed the before/after authoring guidance.
- The supplied `complete.em.hcl` is used as a current executable reference for canonical flow and model structure.

## Learning-science sources retrieved through SciSpace

The learning structure uses conservative, well-supported findings rather than pop-neuroscience claims.

1. **Zepeda, C. D., Een, E., & Butler, A. C. (2024). _The Mnemonic Effects of Retrieval Practice_.** Oxford Research Encyclopedia of Education. DOI: `10.1093/acrefore/9780190264093.013.858`  
   - Retrieval practice improves long-term retention and transfer across many kinds of learners and materials.

2. **Jonsson, B., Wiklund-Hörnqvist, C., Stenlund, T., Andersson, M., & Nyberg, L. (2021). _A learning method for all: The testing effect is independent of cognitive ability_.** Journal of Educational Psychology. DOI: `10.1037/EDU0000627`  
   - Behavioral and fMRI evidence supports retrieval practice across cognitive-ability groups.

3. **_Distributed practice in verbal recall tasks: A review and quantitative synthesis_ (2006).** Psychological Bulletin. DOI: `10.1037/0033-2909.132.3.354`  
   - A major meta-analysis showing that spacing and desired retention interval interact; durable memory generally benefits from distributed practice.

4. **Firth, J., Rivers, I., & Boyle, J. (2021). _A systematic review of interleaving as a concept learning strategy_.** DOI: `10.1002/REV3.3266`  
   - Interleaving shows benefits for memory and transfer, especially when distinctions between categories/items are subtle.

5. **Renkl, A. (1999). _Learning mathematics from worked-out examples: Analyzing and fostering self-explanations_.** European Journal of Psychology of Education. DOI: `10.1007/BF03172974`  
   - Worked examples become substantially more useful when learners actively self-explain the solution steps.

6. **_The Power of Successive Relearning: Improving Performance on Course Exams and Long-Term Retention_ (2013).** Educational Psychology Review. DOI: `10.1007/S10648-013-9240-4`  
   - Successive relearning combines retrieval with spaced repetitions and improves durable learning.

---

# One-page memory summary

```text
EVENT MODELING
==============

5 ELEMENTS
Event       = fact that happened
Command     = intent we want to happen
Read Model  = answer derived from facts
Screen      = how an actor observes/acts
Gear        = machine reaction -> processor in HCL

4 PATTERNS
State Change = Screen/API -> Command -> Event
State View   = Event -> Read Model -> Screen
Automation   = internal Event -> RM/Processor -> Command -> Event
Translation  = external Event -> RM/Processor -> Command -> internal Event

6 WORKSHOP STAGES
1 Brainstorm events
2 Find the plot
3 Storyboard screens
4 Add input/output
5 Add ownership/swimlanes
6 Add scenarios

4 SMELLS
Left chair  = 1 Command -> many Events
Right chair = many Events -> 1 Read Model
Bed         = 1 Screen -> many Commands
Shelf       = scenarios concentrated in one slice

HCL RULES TO REMEMBER
- Events/field types/aggregates belong to bounded contexts.
- Workflow kinds are state_change/state_view/automation/translation.
- Relationships are unquoted typed traversals with ONE canonical edge spelling.
- Workflow-local source -> `to`; catalog Event source -> receiver `from`.
- Read Models require a concrete question.
- State Change: GIVEN* -> exactly one WHEN Command -> THEN Event/Error.
- State View: GIVEN Event+ -> NO WHEN -> THEN Read Model/Error.
- There is no Query concept or `query` target.
- Matching titles are derived from labels; explicit titles are overrides.
- Translation consumes an external Event; Automation must not.
- Unknowns become hotspots.
- Source order is model order.
- Format: eventmodeling-hcl fmt -w <model.em.hcl>
- Validate: eventmodeling-hcl validate [--profile workshop|valid|strict] <model.em.hcl>

MOST USEFUL QUESTION
What happens next?
```
