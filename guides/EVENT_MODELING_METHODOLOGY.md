# Event Modeling — The Complete Methodology

> A technology-agnostic consolidation of every Event Modeling rule, guideline, heuristic, checklist and worked example found in the Eventmodelers Build Kits repository (modeling skills, kit instructions, build-kit patterns, API domain model, improvement notes).
> Tooling, endpoints, frameworks, databases, coordinates and agent mechanics have been removed; what remains is the method itself.
> Where the sources disagree, the main text states the operative rule and **Appendix C** lists the tension.

---

## Table of Contents

1. [Foundations](#1-foundations)
2. [Building Blocks — Elements, Naming, Fields](#2-building-blocks--elements-naming-fields)
3. [The Canvas — Chapters, Lanes, Columns, Connections](#3-the-canvas--chapters-lanes-columns-connections)
4. [Slices and Patterns](#4-slices-and-patterns)
5. [The Modeling Process (Steps 0–11)](#5-the-modeling-process-steps-011)
6. [Deep Dive: Automations and Todo Lists](#6-deep-dive-automations-and-todo-lists)
7. [Deep Dive: Translating External Events](#7-deep-dive-translating-external-events)
8. [Deep Dive: Read-Model Design](#8-deep-dive-read-model-design)
9. [Deep Dive: Specifications (GWT and Storylines)](#9-deep-dive-specifications-gwt-and-storylines)
10. [Deep Dive: Entity Timelines / Stream Boundaries](#10-deep-dive-entity-timelines--stream-boundaries)
11. [Deep Dive: Conway's Law and Ownership](#11-deep-dive-conways-law-and-ownership)
12. [Quality: Shapes, Completeness, Validation](#12-quality-shapes-completeness-validation)
13. [Collaboration, Facilitation and Governance](#13-collaboration-facilitation-and-governance)
14. [Alternative Entry Points](#14-alternative-entry-points)
15. [From Model to Software](#15-from-model-to-software)
16. [Planning and Estimation](#16-planning-and-estimation)
17. [Worked Reference Examples](#17-worked-reference-examples)
- [Appendix A — Master Checklists](#appendix-a--master-checklists)
- [Appendix B — Glossary](#appendix-b--glossary)
- [Appendix C — Known Tensions in the Sources](#appendix-c--known-tensions-in-the-sources)

---

## 1. Foundations

### 1.1 What an event model is

An event model is a left-to-right timeline that tells the story of a business process as a sequence of **facts that happened**, together with the **intent** that caused them, the **information** derived from them, and the **actors** (people or automations) that see that information and act on it.

The information flow every model follows:

```
SCREEN / AUTOMATION  →  COMMAND  →  EVENT  →  READ MODEL  →  SCREEN / AUTOMATION  → …
   (who initiates)      (intent)     (fact)     (projection)     (who sees / decides)
```

- **Screens / automations** are entry points that trigger intent.
- **Commands** express business intent in business language and can be rejected.
- **Events** are business facts — the result of a successful command.
- **Read models** project events into the shape a specific query needs.

The model covers: timeline events, commands, read models, screens, automations/processors, specifications (GWT scenarios and storylines), explicit slices, and comments/questions.

### 1.2 Offline-first thinking

Model the process **as it would work without software** first, then translate to elements:

- How would this work manually, with people, on paper?
- Who acts, and what triggers each action?
- What information do they need before they can act?

Question any step that exists only because of the system — a loading spinner, a cache refresh, a session check is not a business step and does not belong on the timeline. Every anti-pattern in §2.7 is what it looks like when this principle is skipped.

### 1.3 Causality, not strict sequence

- Every EVENT traces to the COMMAND that produced it.
- Every COMMAND traces to exactly one SCREEN (a user decision) or AUTOMATION (a system reaction).
- A process starts with a **read** (READ MODEL feeding a SCREEN) or an **AUTOMATION reacting to an existing EVENT** — never with an unmotivated command.
- Do not chain two state changes without a new trigger between them: two commands in a row with nothing issuing the second one is a gap, not a shortcut.

### 1.4 Two postures: Modeling Mode vs. Critic Mode

| Mode | Steps | Posture |
|---|---|---|
| **Modeling Mode** | brainstorming, plotting, storyboarding, inputs, automation chains, outputs, scenarios, external-event translation | Explore and build. Capture the process as completely as you can. A naming slip or incomplete precondition is flagged and moved past — don't stall or over-correct early. |
| **Critic Mode** | validation, structural checklist, completeness, business review, stream-design review | Review what exists. Apply every rule strictly. Surface every violation, gap and inconsistency; don't soften a finding because the model "mostly works". Record findings as comments/tasks rather than silently fixing, unless the step explicitly permits fixes. |

**Never mix them in one pass**: a modeling step is not the place for a full audit, and a critic step is not the place to quietly add missing structure instead of flagging it.

### 1.5 Core principles at a glance

1. Events are immutable business facts in past tense; corrections are new events.
2. Commands are rejectable business intent; exactly one issuer each.
3. Read models are disposable, rebuildable projections; they never drive command validation.
4. Every field has lineage — "a field with no mapping is a gap, not a detail to fill in later."
5. Connections read forward (left→right, or downward in a column). One narrow exception: automation todo lists.
6. One event per column — a column is one moment in time.
7. A slice is one command, one read model, or one automation — never combined. Slices communicate only via events.
8. Every automation has its own todo-list read model. External facts are translated before domain work reacts to them.
9. Every command has scenarios covering all applicable behavior types; every read model has at least one view specification.
10. The model is the source of truth for implementation; if a derived artifact is wrong, fix the model.

---

## 2. Building Blocks — Elements, Naming, Fields

### 2.1 EVENT

- A **business fact that already happened**.
- **Naming**: past tense, business language, specific, typically 2–4 words.
  - Valid: `OrderPlaced`, `PaymentAuthorized`, `UserRegistered`, `InvoiceSent`, `AccountSuspended`.
  - Invalid: `SidebarOpened`, `RequestCompleted`, `ApiCalled` (UI state / machinery); `PlaceOrder` (imperative); `UserUpdated`, `RecordDeleted`, `StatusChanged`, `DocumentCreated` (generic CRUD — be specific); `The payment was successfully received` (too long).
  - Describe actual happenings: `OrderConfirmed`, not `OrderMayBeConfirmed`; `PaymentInitiated`/`PaymentAuthorized`, not the state-like `PaymentPending`.
- **Immutable**: never modify or delete an event once created. A correction is a new event (`OrderTotalCorrected`, not an edited `OrderCreated`).
- Exists **only if the triggering command succeeded**.
- Contains **only captured facts** — no computed or derived values that recalculate as source data changes (those belong in a read model). Instead of `OrderCreated.totalTax`, capture items/amounts and compute tax in a projection.
- **Event order matters** — it tells the story.
- **Granularity**: one event per meaningful state change. Prefer `UserUpdatedProfile` over separate `FirstNameChanged`, `LastNameChanged` for a single profile-update action. Two events must never mean the same thing.
- Each event belongs to **exactly one entity/timeline**. Another entity may consume it via a read model or automation, but never owns the same fact. Apparent shared ownership signals a naming or boundary mistake.
- Every event should carry a timestamp of when it happened (missing "last updated" data is fixed by including timestamps on events).

### 2.2 COMMAND

- **Business intent** — what an actor wants to do.
- **Naming**: imperative, business language. Valid: `PlaceOrder`, `ConfirmPayment`, `CancelSubscription`. Invalid: `LoadOrders`, `FetchData` (queries), `OpenDialog` (UI-only).
- **Can be rejected**; succeeds only if its documented preconditions hold.
- **Outcomes**: on success it records **one or more events**. If a precondition doesn't hold, it is **rejected** — nothing happened, so **no event**; the rejection is specified as an error scenario. Distinguish this from a **failure that is itself a business fact** — payment declined, inventory reservation failed, a processor's outcome that the business tracks or retries — which **is** recorded as an event (`PaymentFailed`, `InventoryFailed`). No silent failures.
- **Issued by exactly one SCREEN or AUTOMATION — never two, never zero** ("A COMMAND never stands alone"). Even an externally-triggered integration whose external decision logic is out of scope needs an automation issuer.
- **Attributed to one specific role/actor** from the Role Catalog — never a generic "User".
- Checked against its **own documented preconditions**, never against a read model.
- A screen represents one committed decision, so it triggers **exactly one** command (§12.1). If a page offers several actions, each action is its own screen state/column.

### 2.3 READ MODEL

- A **projection built from events**, shaped for one specific query. Its only sources are events; replaying the same events always yields the same projection; it can be regenerated at any time; building it has no side effects.
- **Naming**: noun phrase for the data, not the machinery. Valid: `OrderSummary`, `InvoiceList`, `ActiveReservationView`. Invalid: `OrderSummaryProjector`, `InvoiceListRepository`.
- Consumed by screens (display) or automations (decision).
- **Never drives command validation.**
- Must have a real query purpose; remove projections that exist only for convenience.
- **List-shaped vs. single-record**: a read model whose result is many rows (each shaped by the model's fields) is *list-shaped* — a property of the whole read model, distinct from a single field having List cardinality. Every automation todo list is list-shaped; so are natural row sets such as `ProductList`, `InvoiceList`. This decides whether specifications assert rows / explicitly-empty lists or one accumulated record.
- "Optional": no individual command inherently requires one — but every human role must see at least one, every view screen needs one, every non-blank input screen needs one, and every automation needs its todo list (§8.1).

### 2.4 SCREEN

- What a **human** sees and acts on. Name it as a user would: `Dashboard`, `OrderOverviewPage` — not `OrderOverviewComponent`, `ProjectorView`.
- A screen represents one committed decision → it triggers **at most one command** (see "the bed", §12.1).
- When no human interacts, it is not a screen — model an AUTOMATION.
- A screen's title is the page name: same-titled screens across slices compose one real page.
- A screen must have real visible content and field definitions with lineage; a title-only screen is a placeholder, not a completed step.

### 2.5 AUTOMATION (processor)

- An **automated actor** — processor, scheduler, or system reacting to events.
- **Naming**: what it does, in business language: `BillingScheduler`, `InventoryReserver`, `Send Welcome Notification` — not `OrderServiceHandler`.
- Shape: **READ MODEL (todo list) → AUTOMATION → COMMAND → EVENT(s)**. It reads state, decides, issues a command.
- "Processors don't directly process events — they maintain a todo list driven by events."
- Recognise an automation moment when: the system (not a user gesture) triggers the action; no human sees a UI at that moment.
- Deadlines and timers (reminders, "deadline passed", "submissions closed") are automations, not human screens.

### 2.6 Supporting elements

| Element | Meaning |
|---|---|
| **Scenario / specification** | Given/When/Then behavior spec or storyline for the column's command or read model. Lives in the spec lane. |
| **Slice boundary** | Marks one column as an independently buildable slice; carries title and status. |
| **Comment** | Attached to an element. A *question* is a comment worded as a question; stays open until answered (resolving = answering, not deleting). Task comments carry required fixes. |
| **Hotspot** | A red feedback note next to the element it concerns: a pain point, unresolved question or dispute. **Not an event.** |
| **Note (feedback lane)** | Free-text reasoning, decisions, provenance, chapter summary. |
| **Linked copy** | A command/event/read model reused elsewhere as the *same* underlying element (§3.7). |
| **Context** | A bounded context grouping chapters; a chapter with no context acts as its own context. |
| **Chapter / timeline** | Interchangeable terms: one coherent story/process (§3.1). |

### 2.7 Element anti-patterns

| Anti-pattern | Example | Fix |
|---|---|---|
| Data-loading command | `LoadOrders`, `FetchData` | Model as a read model |
| UI-interaction event | `SidebarOpened`, `ButtonClicked` | Drop unless the business genuinely cares |
| Technical event | `ApiCalled`, `ResponseReceived` | Find the business fact underneath |
| Calculated event | running total, average, `InventoryLevelRecalculated`, `SellerRatingCalculated`, `CalculationPerformed(metric=4.5)` | Read model (with its own derived history if needed) |
| CRUD event | `UserUpdated`, `RecordDeleted` | Specific business fact |
| Implementation-flavored names | `…Projector`, `…Repository`, `…Handler`, `…Component` | Business names |
| Generic actor | command issued by "User" | Specific catalog role |

### 2.8 Event vs. read model — decision test

Apply in order:

1. Did an actor perform an action? → **event** (customer confirmed an order).
2. Is it a pure calculation? → **read model** (inventory total).
3. Is it immutable once created? → **event** (`PaymentAuthorized`).
4. Does it recalculate multiple times? → **read model** (changing total sales).
5. Is it an independent fact (e.g. `OrderFlagged` for manual review)? → **event**.
6. Is it derived from other events? → **read model** (`OrderStatus`).

Never model as events: inventory level totals, transaction sums, account balances, search indexes, sums/counts/averages, scheduled pure calculations. Separate "what happened" from "how we view the facts" — modeling recalculation as events risks circular dependencies and replay problems. Derived-state history belongs in the projection's history, not in recalculation events.

Domain classification examples:

| Domain | Facts (events) | Derived (read models) |
|---|---|---|
| E-commerce | `OrderCreated`, `OrderConfirmed`, `PaymentAuthorized`, `OrderShipped` | `OrderTotal`, `InventoryLevel`, `ShippingCost` |
| Banking | `AccountOpened`, `DepositReceived`, `WithdrawalProcessed`, `FundsTransferred` | `AccountBalance`, `InterestCalculated` |
| Subscriptions | `SubscriptionCreated`, `PaymentProcessed`, `PlanUpgraded`, `SubscriptionCancelled` | `MonthlyRecurringRevenue`, `ChurnRate` |
| Healthcare | `PatientRegistered`, `AppointmentScheduled`, `ProcedureCompleted`, `BillGenerated` | `PatientAge`, `AverageCost` |

**Processor outputs** are classified as: a new domain fact → event (`PaymentAuthorized`); a pure calculation → read-model update; an informational notification → neither.

**When a derived condition deserves its own event** — ask "is this fact worth a new event?" as a *business* decision, never as a trick to reduce fan-in. It deserves one only when **both** hold: (1) a domain expert recognises and names it as a fact in its own right, and (2) a later process/automation/context gains value by reacting to it. Then model it via todo list → automation → command → event, triggered by the raw internal events. A display-only condition stays a projection regardless of fan-in. Consolidate only business-redundant causes of the same outcome (`CopyReservationReleased`, `CopyReturned`, `CopyReturnedFromRepair` → `CopyMarkedAvailable`), never distinct meanings (`CopyReserved`, `CopyCheckedOut`, `CopySentForRepair`, `CopyReportedLost`, `CopyWithdrawn` stay distinct — a generic `CopyMarkedUnavailable` would erase reasons consumers need).

### 2.9 Fields

Every COMMAND, EVENT, READ MODEL and SCREEN carries fields. Field properties:

| Property | Meaning |
|---|---|
| name | Domain language (`memberId`, not `userId`; `dueDate`, not `due_at`) |
| type | Text, Boolean, whole number (small / large), floating number, **Decimal (prefer for money)**, Date (no time), DateTime (ISO 8601), unique identifier, Custom/structured (with sub-fields) |
| cardinality | **Single** by default (also when unsure); **List** only for genuinely repeated values (line items, multi-select) |
| sub-fields | Nested structure |
| identity attribute | Marks the entity identifier(s). Two or more ⇒ a compound identity (e.g. `email` + `courseId` for a subscription) |
| optional | Not required on input; may be absent in a read model (never invent a default) |
| generated | Value computed by the system rather than supplied |
| technical attribute / PII | Marks non-business or sensitive data |
| example | Concrete realistic value |
| mapping | Lineage — where the value comes from (§2.10) |

**Event payload discipline (initial modeling)**: include identity key(s) plus the one or two essential facts that make the event meaningful; enrich later. An event that is a bare label cannot support completeness review or scenarios. Payload-free (identity-only) events are acceptable when the name conveys the meaning. Don't pad.

**Every command/read-model field must trace to a source**; include only fields actually shown, captured or needed — no speculative fields.

### 2.10 Field lineage (mapping) vocabulary

**Command fields**

| Origin | Mapping | Generated? | Example |
|---|---|---|---|
| User typing/selection | user input (or `<Command>.<field>` on the screen) | No | `ReserveBike.bikeId` |
| Authenticated session | `session:<field>` | No | `session:customerId` |
| Prior event | `<Event>.<field>` | No | `BikeReserved.bikeId` |
| System computation | `derived:<expression>` | **Yes** | new identifier, current time |
| External payload | external-payload field | No | provider transaction reference |

User-supplied values are never generated; system-derived values always are.

**Read-model fields**

| Mapping | Meaning | Generated? | Example |
|---|---|---|---|
| `<Event>.<field>` | Directly projected value | No | `BikeReserved.customerId` |
| `latest:<Event>.<field>` | Value from most recent event of that type | No | `latest:BikeStatusChanged.toStatus` |
| `aggregate:<Event>.<field>` | Aggregate over several events | Yes | `aggregate:RentalEnded.durationMinutes` |
| `derived:<expression>` | Calculated from other projection fields | Yes | `derived:sum(lineItems.amount)` |

**Screen fields**

| Role | Mapping | Example |
|---|---|---|
| Captured command input | `<Command>.<field>` | `ReserveBike.bikeId` |
| Session value | `session:<field>` | `session:customerId` |
| Pre-populated from prior event | `<Event>.<field>` | `BikeReserved.stationId` |
| Displayed read-model value | `<ReadModel>.<field>` | `ActiveReservationView.status` |
| Display-only calculation | `derived:<expression>` (generated) | `derived:formatDuration(durationMinutes)` |

**Lineage rules**

- A mapping may reference **only elements actually connected** by an arrow (EVENT→READMODEL for read models; SCREEN→COMMAND for commands; READMODEL→SCREEN for screens). If the source isn't connected, add the arrow or flag the gap — **never invent connections**.
- Name an intended source read model on a screen even before that read model is designed; the missing read model is then a completeness gap for the outputs step.
- Every event field either appears in the command (same name or documented rename) or is derivable from command fields + system state (e.g. `reservationId` generated, `reservedAt` = now) — document the derivation.
- An unmappable field means missing data, a missing event, or a modeling error. Investigate (missing event field, missing screen field, broken connection) **before proceeding**.
- "Every input becomes event data": command inputs must not disappear.

### 2.11 Example data

- Inspect connected COMMAND/EVENT/READ MODEL fields first; reuse values across a chain (the email in a command stays the same email in its event). Keep one **canonical value pool** per chapter (e.g. `customerId = cust-123`, `email = jane@example.com`). When several numbered example sets exist, the same number across elements represents **one coherent scenario** (e.g. every "sample 2" is "a long-time customer"), not independently chosen personas.
- Never overwrite an existing non-empty example; fill only absent ones.
- One short realistic value per field, domain-specific; never placeholders like "foo"/"test".
- Heuristics: email → `jane.smith@example.com`; ids → short domain ids `ORD-2024-0042`; amounts → `149.99`; dates/`…At` → ISO 8601 `2024-03-15T10:30:00Z`; status → plausible business value; booleans → `true/false`; counts → small integers; lists → 1–2 representative items.

### 2.12 Propagating attribute changes

- A field added/renamed on one element is carried through its **whole chain** (Screen → Command → Event → Read Model → Screen), as far as the chain actually runs — not just the one element, and not every element merely in the same column range.
- Rename changes only the name; preserve type, cardinality, examples, identity flag.
- Treat a chain-wide change as one logical edit: if part of the chain is locked (§13.7), change nothing until confirmed.
- Obvious typos (`custoemrId`) and plainly wrong flags (identity flag off on the entity's own id) are fixed directly and carried through every connected element.

---

## 3. The Canvas — Chapters, Lanes, Columns, Connections

### 3.1 Chapters (timelines)

- **"A chapter tells a story — a user journey, not an operation."** One coherent business process / bounded context that stands alone as a narrative and would naturally belong to one team or domain expert (e.g. *Catalogue Management*, *Reservation*, *Overdue & Payments*, *Owner & Pet Care*, *Visit Booking*).
- Creating, finding, viewing and updating the same thing usually form one story.
- **Over-fragmentation signs**: title is one verb + one noun or names one page; the chapter has one or two slices; the next chapter begins with the entity the current one just produced. **When in doubt, merge** — a dozen slices forming one journey is fine; five chapters of two slices each is not.
- Rough size: ~6–15 columns per chapter; beyond that, split at a natural phase boundary.
- Every event must eventually belong to a dedicated, **named** chapter. Free-floating events are allowed during open brainstorming but must be assigned before plotting.
- Stack chapters vertically without overlap, related chapters adjacent.
- **Divergent journey → separate chapter**: the actor chooses differently *before* the process starts and downstream screens/commands differ (checkout with saved card vs. guest checkout).
- **Decision point → same chapter**: one command outcome or rule resolves into mutually exclusive outcomes while the story stays the same (payment authorized vs. failed). Test: *"does this branch start a genuinely different story, or does it just decide how this story ends?"*

### 3.2 Lanes (rows)

Vertical order, top to bottom:

| Lane | Elements | Represents |
|---|---|---|
| **Actor** | SCREEN, AUTOMATION | Who/what initiates — a human via a screen, a system via an automation |
| **Interaction** | COMMAND, READ MODEL | Intent going in, or query result coming out |
| **Event swimlane** | EVENT | The recorded fact and whose story it belongs to |
| **Specification** | SCENARIO | GWT/storyline for this column's command or read model |
| **Feedback / notes** | notes | Reasoning, decisions, summaries |

- **One actor lane per human role**, labelled with the Role Catalog name. Never put two human roles' screens in the same actor row. Every catalog role (including the first) gets its own labelled lane; add a lane only when a genuinely new human role appears.
- **All automations share one default actor lane**, regardless of which system they narrate. Never create per-processor physical lanes; system groupings are narrative only.
- **Event swimlanes are used sparingly.** Normally one default event swimlane holds all facts of the bounded context. The **only** valid reason for a second event swimlane is marking **another system's events crossing into this chapter** (integration triggers), labelled for that system. A human role, visual grouping or business rule never justifies a new event swimlane. Don't create a swimlane per team.

### 3.3 Columns (time)

- A column is **one moment in time**. Time runs left → right.
- **One EVENT per column — hard rule**, across all swimlanes.
- At most **one** COMMAND, READ MODEL, SCREEN and AUTOMATION per column across all rows; the interaction cell holds a command **or** a read model, never both.
- **Never more than one SCREEN per column**, even in different actor lanes. If another role needs a screen related to the same event, insert a new column right after.
- A column belongs to at most one slice.
- Reuse genuinely empty columns before creating new ones; remove leftover empty gaps; keep the sequence contiguous and chronological.

### 3.4 Allowed connections

| From → To | Meaning |
|---|---|
| SCREEN → COMMAND | User issues intent |
| AUTOMATION → COMMAND | System issues intent |
| COMMAND → EVENT | Intent produces fact |
| EVENT → READ MODEL | Fact feeds projection |
| READ MODEL → SCREEN | Projection displayed |
| READ MODEL → AUTOMATION | Projection (todo list) drives automation |

Nothing else. Specifications are never connected. Connections only pair elements **within the same chapter**; to use an element from another chapter, place a **linked copy** (§3.7).

### 3.5 Connections read forward

- A connection goes **downward within the same column** (actor → interaction → swimlane → spec) or **forward to a later column** — **never backward**.
- Hence elements that belong together share a column whenever possible: issuing screen/automation + command + produced event; view screen + its read model.
- If the natural column is occupied, **insert a new column** immediately before or after (whichever keeps every connection forward) rather than wiring across a gap.
- **The single exception**: an `EVENT → READ MODEL` connection may point backward **only when that read model already feeds an AUTOMATION** (a todo list). Such a read model is a live, continuously-listening projection, not a point-in-time snapshot, so it may collect a later closing event. Establish `READ MODEL → AUTOMATION` first. A read model that only feeds a screen **never** qualifies.
- Wide fan-in never justifies a backward arrow. A connection to an event that no field uses is removable regardless of position.
- **Proximity is not causality**: never wire to whatever happens to be in a neighbouring column. Wire only intended, semantically justified relationships.
- Real connections win over layout inference. When reading an unwired (hand-built/imported) chapter, infer from layout but distinguish inferred from wired relationships. A chapter with many placed elements and zero connections is almost always missing wiring.

### 3.6 Placement rules (canonical layout)

| Element | Placement |
|---|---|
| Command | Interaction lane, **same column as its (first) resulting event** |
| Resulting event | Own swimlane, command's column. Additional events from the same command occupy **adjacent columns immediately after**, in the **same swimlane** (one system doing several things, not several systems) |
| Input screen | Its role's actor lane, **same column** as command + event |
| Automation | Shared automation actor lane, **same column** as the command it issues |
| Automation's todo-list read model | Interaction lane, **one column before** the automation (its own interaction cell holds the command) |
| View screen | Its role's actor lane, **same column** as its primary read model (downward arrow) |
| Read model whose screen column is occupied (by a command) | New column **immediately before** the screen — don't move an established screen to resolve it |
| Read model fed by a just-placed event | Interaction lane immediately after the source event's column — **never bunched at the end of the timeline** |
| Additional read models for one consumer | Further **left** of the primary, never to its right |
| Consumer of a read model | In the read model's column or the **next** column (both forward, both normal) |

**Place by story, not by type**: screen → command → event → the read model and view screen that event feeds → next slice. Never lay out all events, then all commands, then all read models — it forces retroactive insertions and breaks the narrative.

Storyboard positions are provisional; input/output steps may reposition screens to align with commands/read models. After every element-creating step, check for unplaced elements: place valid ones, remove genuine duplicates; never advance with unplaced elements.

### 3.7 Linked copies

- A **linked copy** is a COMMAND, EVENT or READ MODEL that mirrors another element elsewhere — the **same underlying fact/element**, not a new one. Screens cannot be linked copies.
- Needed because connections only pair elements within one chapter; also whenever an element is **reused** within the same chapter.
- **Never place an unlinked duplicate of an already-recorded fact**: either connect forward to the original or mark the repeat as a linked copy.
- **Exception**: a translation chain's internal event is a genuine new fact in this domain's language — not a copy, even when it shares the external event's name.
- A copy inherits type, title and all field metadata from the origin and records its origin. Copies of copies are not allowed.
- A copy may later diverge in the specific fields a newly connected event drives (e.g. `status`); the link asserts identity, it doesn't freeze values.
- **Never delete the original** once copies exist. Linked copies are intentional — never "duplicates" to clean up, and they imply **no slice** of their own.

### 3.8 Updating a read model that already feeds an earlier screen

When a later event changes data an earlier read model shows on a screen (e.g. a cancellation affecting an "active items" view several columns earlier):

1. **Do not** wire the later event backward into the existing read model.
2. Place a **linked copy** of the read model in a new column **immediately after** the later event.
3. Connect the later event forward into the copy; update only the fields that event changes; inherited fields stay.
4. Place a matching **ordinary** screen (same title as the earlier one) in that column showing the updated data; optionally highlight what changed.
5. Leave the earlier read model/screen untouched — it correctly shows that earlier moment. Never delete it.

### 3.9 Narrative continuity

- Keep **one actor's perspective** across consecutive columns as much as possible. Switch roles only on a genuine handoff (Member requests a reservation → Librarian acts on it). Ask *"whose turn is it in the story?"*
- Consecutive columns for one role while another lane is empty is expected. Don't checkerboard roles for symmetry.
- Keep the chapter's story continuous **in its own swimlane**. An event in another system's swimlane is **a handover, not a relocation**: a single isolated column, and the **very next column** resumes the chapter's own swimlane. A long run of external events suggests they need their own chapter. Adjacent events in different lanes without a trigger relationship mean: revisit plotting.


---

## 4. Slices and Patterns

### 4.1 What a slice is

A **slice** is the thinnest possible vertical cut through the model — **exactly one COMMAND, one READ MODEL, or one AUTOMATION's command, never combined**. If "Place Order" needs both `PlaceOrder` and `OrderDetailView`, that is two slices.

- Slices are **independently deployable** and communicate **only via events** — never by sharing state or reading each other's state. An automation issuing its modeled command, which is then judged by that command's own rules (§15.2), is the modeled interaction, not a direct call.
- Slices are **derived, not invented**: "Slices already exist in the timeline." Every command implies a state-change slice, every read model a state-view slice, every automation an automation slice — **except linked copies**, which imply no slice.
- Name a slice **exactly after its defining element** (an automation slice may alternatively take its issued command's name). Never generic names ("State Change", "Order Management").
- One slice = one column = one reviewable, independently buildable unit of work.

### 4.2 The patterns

```
STATE CHANGE   SCREEN/AUTOMATION → COMMAND → EVENT(s)
STATE VIEW     EVENT(s) → READ MODEL → SCREEN/AUTOMATION
AUTOMATION     EVENT(s) → TODO-LIST READ MODEL → AUTOMATION → COMMAND → EVENT(s)
TRANSLATION    EXTERNAL EVENT → TODO-LIST READ MODEL → TRANSLATION AUTOMATION → COMMAND → INTERNAL EVENT
```

| Pattern | Contains | Typical elements present |
|---|---|---|
| State change | Write side: command checked against state from past events → new events or rejection | screen + command + event |
| State view | Read side: events projected into queryable information; processes no commands, emits no events | screen + read model (the source event normally already exists earlier) |
| Automation | Reaction to events via a todo list; issues commands | automation + command + event (+ todo list one column before) |
| Translation | Specialised automation turning an external/other-system fact into an internal fact (§7) | external event, todo list, translation automation + command + internal event |

An "internal" slice may legitimately have no screen (e.g. automation-only); don't flag a missing screen if the slice is intentionally internal.

### 4.3 Valid transitions between slices

- state-view → state-change
- state-change → state-view
- state-change → automation
- automation → state-change
- automation → state-view

Never state-change → state-change without a new trigger (screen or automation) between them. A timeline starts with a state-view or an automation reacting to an existing event.

### 4.4 Cross-slice dependencies

- Record dependencies as **"depends on events from X"**, never "depends on slice X".
- *Command slice → event → command slice*: `PlaceOrder` produces `OrderPlaced`; `ConfirmOrder` validates against that fact through its own state.
- *Command slice → event → read-model slice*: `PlaceOrder` produces `OrderPlaced`; `OrderDetailView` projects it — the most common dependency.
- Slice B depends on slice A iff B consumes an event A produces — determinable mechanically by diffing produced vs. consumed event names.
- Slices on different events have no dependency.

### 4.5 Slice definition record

For each slice record: name and type; command + purpose (state-change/automation) or read model + what it shows (state-view); produced events and when; consumed events and why; upstream producers and downstream consumers with their event contracts.

### 4.6 Choosing the next slice

- First make existing, unsliced commands/read models/automations explicit as slices. Inventing the next capability is the fallback when nothing is left to slice.
- When inventing: use an explicitly requested capability if any; otherwise follow the existing narrative left-to-right and pick what **most directly continues the story**: the next lifecycle stage; an affordance implied by an existing screen (a button with nothing behind it); an entity's missing create/update/cancel/detail; a missing notification; an action missing its confirmation view.
- If several are equally plausible, state the assumption, choose, and model it — the model is cheap to rename or discard.
- Complete the new slice fully, including a real screen in the chapter's established visual style.

---

## 5. The Modeling Process (Steps 0–11)

```
0 Scope → 1 Brainstorm events (+Role Catalog, chapters) → 2 Plot → 3 Storyboard → 4 Inputs
  → 4b Automation chains → 5 Outputs → 6 Conway's Law → 7 Scenarios → 8 Completeness
  → 9 Validation → 10 Slicing → 11 Reasoning documentation
```

Short form: **events → commands/screens → read models → scenarios → slices**.

Process rules:

- Enter mid-workflow at the **first incomplete step**; don't rerun completed steps.
- After every step, record 2–4 key bullets (artifacts, decisions, gates), what the next step must carry forward, and open questions; maintain a trail of step, status, one-line output.
- Never cut required elements (todo lists, projections, translation chains) to save effort or dodge layout problems — solve the placement. Any real scope trade-off is made explicit.
- In a full run, plot **every** timeline (Step 2) before storyboarding; from then on detail one chapter at a time. Document-driven modeling (§14.1) completes each chapter end to end instead of doing all chapters' events first (see Appendix C #24).
- Correct architecture beats optimised mechanics: in one observed modeling round, a single upfront design error caused more rework than four other steps combined. Stricter rules legitimately increase element and column counts — that's substance, not waste.

### Step 0 — Scope

Skip if domain, scope and goal are already clear. Otherwise establish:

1. The domain/process in 2–3 sentences.
2. Requirements state: written stories/specs, rough ideas, or an existing system to reverse-engineer.
3. Goal: learning, production implementation, design validation, team documentation.
4. Constraints: timeline, external integrations, team size.
5. Starting point: new model vs. existing artifacts.

### Step 1 — Brainstorm events (with Role Catalog and chapters)

**Interview** (skip only if requirements are detailed **and** the domain expert is identified):

- Requirements completeness: written stories/specs, documented rules, rough list, verbal? Rough input ⇒ probe missing scenarios; state undocumented rules explicitly.
- Domain expertise: expert-led, engineering-only (invite an expert), mixed (clarify decision-making)?
- Complexity: where is complexity/error risk (payments, transitions, rules)? Ask what edge cases exist and what can go wrong — hidden events live here.
- Rules/constraints: e.g. "cancel within 24 hours", "authorize before confirm". For each, ask what signals a violation.

**Role Catalog (mandatory, first)**:

- All **human roles** (Customer, Seller, Admin, Support Agent, Reviewer) and **system actors** (Payment Gateway, Inventory System, Notification Service, Scheduler).
- Per entry: domain name (never "User Type B"), one-line description, key state-changing actions, explicit **cannot-do** boundary. System actors additionally: internal vs. external, what triggers them, how they deliver facts.
- Rules: no command attributed to "User"; every command has exactly one catalog issuer; every human role needs ≥1 command and ≥1 read model (otherwise it's decorative); every actor mentioned in events must be in the catalog.

**Workflow**:

1. Catalog roles and permissions.
2. Identify entities, their identity keys (`orderId`, `paymentId`) and the commands affecting them — logical event groupings, not attribute inventories.
3. Map processes: user steps, decision points, integrations.
4. Extract state changes (customer places order → `OrderCreated`).
5. Record rules, validations, invariants with conditions and consequences ("ship only if payment confirmed", not "process payments"). Make initiators explicit ("customers create orders, sellers confirm stock, the system cancels if payment fails"). Cover boundaries/errors.
6. Discover and name chapters; assign every event to one.

**Candidate event sources**: state changes (order confirmed, user signed up, payment failed), milestones (shipment left warehouse, contract signed), decisions with outcomes (approved, rejected, expired), handoffs between parties or systems. Ignore implementation steps. Inspect existing events first to avoid duplicates; for each candidate: add if new, rename if better understood, insert in the right narrative position, remove if proven wrong.

**Gate**: Role Catalog exists; all known processes covered; every event in a named chapter.

**Discovery checklist**: past-tense state-change names; meaningful fields only; distinct catalog responsibilities; event-to-actor traceability; no CRUD events; errors and boundaries covered; no empty columns; ≥1 recognisable flow; no overlapping semantics; every event in a named chapter; chapters stacked without overlap; no unjustified swimlanes; continuous own-lane story with isolated external handovers.

### Step 2 — Plot events

- Arrange **all** discovered events of **one named timeline per pass** in chronological, causal order; don't create chapters here (boundaries were fixed in Step 1 — if a branch turns out to be a distinct story, return to Step 1).
- For each event record: what must already have happened, its trigger, its precondition. (`OrderConfirmed` follows `OrderCreated`, triggered by customer confirmation, requires Draft.)
- Show decision outcomes and alternatives as sibling branches, not just the happy path; logical flow matters more than exact timing; parallel outcomes are fine.
- One event per column; skip none.
- Summarise per chapter: ordered event list, critical path, decision points, terminal events.

**Plotting checklist**: one named timeline; no new chapter boundaries; clear predecessor per event; explicit dependencies; alternatives shown; coherent narrative; no event without trigger; clear terminal states; complete compensation/cancellation flows; business-sensible order; every brainstormed event represented.

### Step 3 — Storyboard

**Interview** (skip if UI references, critical fields and preferences are known): existing UI vs. sketches vs. from scratch; target platform; which fields matter most and **"what decisions do users make based on this data?"**; desired fidelity.

**Workflow**:

1. For each system state on the timeline, design a screen: trigger action, command produced, resulting event, fields captured.
2. Show state transitions: after each event the next screen displays the fields just set alongside the next possible action.
3. List every displayed field with its originating event.
4. Show data entering and leaving the UI: input → command → event → next screen.
5. Organise screens by Role Catalog role (one labelled lane per human role).
6. Place automations where no human interacts (todo-list metaphor: triggering events add items, the processor checks conditions, success/failure produce events and done/failed item states).
7. Flag displayed data without a clear source as comments.

**Rules**:

- Every screen has **real rendered content** (realistic mockup by default; low-fidelity wireframes only when explicitly requested; choose fidelity once per storyboard). Command screens have at least one primary action and labels matching command/event fields.
- Every screen has explicit **fields with lineage mappings** (§2.10) — fieldless screens are placeholders.
- Render **one plain screen per screen state** here; component splitting happens in Step 5 (components are defined by read models).
- Every human role has its own lane and **at least one screen** (else add screens or remove the role).
- One screen per column; narrative continuity (§3.9).
- Common screen patterns: **input** (form → submit → event → confirmation screen); **status** (current state from read model, actions depend on state); **error** (command rejected, no event, message, retry/alternative).

**Gate**: every human role has ≥1 screen.

**Storyboard checklist**: real content; real field labels; ≤1 screen per column; actor perspective preserved; every displayed field has a source, every action a command, every command an event; alternative and error states shown; one labelled lane per human role; automations in the shared lane; todo-list patterns visible.

**Principles**: User-centric · Data traceability · Completeness · Clarity · Consistency · Narrative continuity.

### Step 4 — Identify inputs (commands)

**Interview** (skip if actions/commands/triggers are known): which actions are user-initiated, processor-automated, or mixed; which external systems send triggers and with what data (external triggers are processor commands, never UI commands).

**Workflow**:

1. Extract a command from **each user action**; attribute to a specific role; define name, input fields, validations, produced event.
2. Identify processor-triggered actions (external notifications, scheduled work); attribute to the source system; apply the **external-event guard** (below).
3. For each command define: source, typed inputs, validations, **stream-state preconditions** (required prior events, current status), success event, every distinct failure outcome.
4. Document every input's origin (UI context, form selection, conditional on another input — e.g. `paymentMethod` = card ⇒ card number/CVV/expiry required).
5. Trace each input into event data; record inputs that never reach an event.
6. Produce a **command catalog**: UI-issued vs. processor-issued, each with role/source, trigger, inputs, resulting event. No undocumented commands.

**Placement and wiring**: confirm the input screen and resulting event share a column (move/insert as needed); wire SCREEN→COMMAND and COMMAND→EVENT within the column; validate there is exactly one real issuer; remove stray edges.

**External-event guard**:

- *No external event modeled yet* (a genuine unmodeled notification): place automation + command together, producing a new internal event.
- *An event already exists in another system's swimlane*: it already happened elsewhere. **Never** place a local command in its column or connect a local command as its producer ("an external system's own event cannot be the event this domain's command produces"). Catalog the command as deferred to Step 4b.

**Gate**: every UI action maps to a named, actor-attributed command.

**Input checklist**: every UI/processor action → command; specific actor; inputs documented and validated; preconditions and implicit context explicit; success and failure outcomes documented; consistent naming; processor triggers explicit with todo-list pattern and failure/retry handling.

**Principles**: Source clarity · Input completeness · Explicit validation · State awareness · Event mapping.

### Step 4b — Design automation chains

Immediately after inputs, before outputs, whenever automations exist (skip only if none). Give every automation its todo-list read model and resolve every externally-triggered process into a translation chain. See §6 and §7.

**Gate**: every automation has an incoming todo-list connection; no worker todo list is opened directly by another system's event.

### Step 5 — Identify outputs (read models)

**Interview** (skip if queries, consumers and freshness are clear): what data each consumer queries and required freshness — **real-time (sub-second)**, **near-real-time (seconds)**, **periodic (minutes/hours)**; sub-second consumers get dedicated, highly optimised read models. Which fields are calculated/aggregated (confirm they're projections).

**Workflow**: enumerate every screen and automation → discover components → split multi-component screens into highlighted copies → use existing screen field mappings to define each read model → trace every field to event data → place projections upstream of consumers → connect sources and consumers → write per-read-model reasoning notes → verify each consumer individually → summarise a read-model catalog. Details in §8.

**Gate**: all screen data needs have projections; no read model spans multiple components.

### Step 6 — Apply Conway's Law

Map event/command ownership to team/system boundaries; confirm each boundary can be independently owned. Skip with explicit reason if organisational concerns are irrelevant. See §11.

### Step 7 — Elaborate scenarios

Specify every command and read model with GWT scenarios or storylines. See §9.

**Gate**: all applicable command scenario types written; ≥1 view specification per read model (including todo lists).

### Step 8 — Check completeness

Field-level origin/destination coverage across the whole model. See §12.3.

**Gate**: gaps resolved or explicitly accepted.

### Step 9 — Validate

Read-only structural + semantic review with a PASS / PASS WITH WARNINGS / FAIL verdict. See §12.4–12.5.

**Gate**: PASS (or PASS WITH WARNINGS with all critical issues resolved) before declaring implementation-ready. After FAIL: fix and rerun.

### Step 10 — Make slices explicit

- Walk the timeline column by column; define a slice for each command, read model and automation not yet covered; mark the existing column — never duplicate an element to create a slice.
- Skip columns whose only command/read model is a linked copy.
- When every element has its slice, stop — don't invent content to keep going.
- Team allocation, sprint sizing and estimation are separate concerns.

**Gate**: one matching slice per command/read model/automation, no duplicates.

### Step 11 — Document reasoning

- During any step, add a small note in a decision's own column when a future reader could misunderstand an assumption, rejected alternative, or non-obvious constraint — sparingly, for genuine "why" moments.
- At completion, write **one substantive reasoning note per chapter** (first column, notes lane), for a reader opening the model cold: scope, business process, entities and identity keys; assumptions beyond the brief and why; rules deliberately covered by scenarios instead of new events; sequencing/design corrections and causality rationale; read-model design/sharing rationale; integration gaps and viable resolutions; closing element counts and validation verdict. Simple chapters get brief notes — don't pad.

### Finished-model deliverables

Role Catalog with permissions; chronological timelines; role-based storyboards; actor-attributed commands; read-model designs; system/team boundaries (where relevant); scenarios; completeness evidence; validation verdict; slices; chapter reasoning notes. All steps completed or skipped with explicit reasons; every element placed; every automation has a todo list; every principal element has a slice; no unresolved traceability gaps.

Optional deeper passes at any time: refine causality; verify every entity timeline is anchored on one business identity (§10); model external translation whenever external signals enter.

---

## 6. Deep Dive: Automations and Todo Lists

### 6.1 The todo-list rule

**"Every AUTOMATION needs a todo-list read model — this is not optional, and there is no 'pure relay' exemption."** This includes a trivial relay and a todo that opens and closes within the same slice. Design the automation and its todo list **together**, wiring opening and closing events before moving on — never place the automation first and defer the list to output design.

- A todo list is a **queue of pending work items**, not a snapshot of entity state.
- Pattern: `opening event(s) → todo-list read model → automation → command → resulting event(s)`; completion events remove items.
- Any number of event types may open; any number may close; they need not match.
- Fields: enough to identify and act on the item (`customerId`, `email`, `notificationType`), each with explicit lineage.
- **No `status` field to mark items done.** Open state = membership in the list; a row exists while work is pending and is removed when done. If another consumer needs status history, give it a different read model.
- The todo list is **list-shaped**.
- "There is no such thing as an invisible or informal 'signal' — a trigger is always a real EVENT node."

**Processor semantics**: reactive — listen for events → add todo items → walk the list, check each item's condition → issue commands → produce events. Success produces a success event and closes the item; a business failure produces a failure event (and may mark it failed); a technical error leaves the item for retry. **Define failure/retry handling for every automation.**

### 6.2 Layout

- The todo list sits in the interaction lane **one column before** its automation (insert a column if that cell is occupied).
- Connect `READ MODEL → AUTOMATION` first; then opening events; then (ordinary workers only) closing events. A closing edge from a later event back to the earlier todo list is the sanctioned backward-arrow exception.
- Event→read-model connections from another system's swimlane are drawable; the restriction concerns which automation may *consume* external facts.

### 6.3 Workers vs. translations

| | Translation automation | Worker automation |
|---|---|---|
| Opened by | the **external** event (the only automation that may be) | **internal** events only |
| Closed by | **never** — it relays, it doesn't track "done"; no closing edge, not even from its own internal event | the event(s) marking the work complete, usually its own result |
| Decision | none — converts a foreign fact into a domain fact | a genuine business decision (invariant, choice, computing missing data) |

**When to add a worker after translation**: only if reacting to the internal event requires a **genuinely new decision** — checking an invariant, making a choice, or computing data the internal event doesn't carry. If the next event would have the same identity and data and adds no field, checks no invariant and makes no choice, it merely renames an already-decided fact: stop after translation and project state-views directly from the internal event. An `XSynced` event followed by another translation of an already-decided fact is a warning sign.

### 6.4 Per-automation verification

1. Incoming todo-list connection exists.
2. An external opening event exists only for a translation automation — otherwise split translation from worker.
3. A translation list has no closing event — remove any.
4. A following worker makes a real new decision — otherwise remove its list, automation and redundant event and project directly from the internal event.
5. A real worker has completion (closing) edge(s).
6. No status flag replaces list membership.

Check **every** automation, not just the obviously complex ones.

### 6.5 Example: welcome notification

`CustomerRegistered` opens a row in `NotificationsToSend` → `Send Welcome Notification` reads each row and issues `SendNotification` → `NotificationSent` removes the row. One row per pending notification — not a customer record with a "sent" flag.

### 6.6 Example: inventory reservation

`PaymentAuthorized` (order-123: reserve 2× P1) adds a todo "Reserve P1 qty 2" → `InventoryReserver` finds 5 available → reserves 2 → `InventoryReserved` → todo done. No availability → `InventoryFailed`, item failed. Technical error → item stays for retry.

### 6.7 Automation vs. long-running process

| Signal | Use |
|---|---|
| Single trigger → single command, no waiting | Plain automation |
| Multi-step: trigger → command → wait for event → another command | Long-running process (workflow) |
| Must wait for human approval or external confirmation | Workflow |
| Compensation: if step N fails, undo steps 1..N-1 | Workflow (saga) |
| Timer / scheduled delay | Workflow |
| Fan-out to many entities then wait for all | Workflow |
| Parent process spawns child and waits | Workflow (sub-process) |
| Scatter-gather | Workflow |

Workflow terminal states: started, completed, failed, cancelled, timed out. Patterns: compensating transaction, human-in-the-loop with escalation, fan-out/fan-in. Ask when classification is ambiguous.

---

## 7. Deep Dive: Translating External Events

### 7.1 The translation chain

An automation reacting to another system's event (an external system, or another team's timeline) needs translation first:

```
[external EVENT] → [todo-list READ MODEL] → [translation AUTOMATION + COMMAND + internal EVENT] → (worker's own todo list, only if a new decision is needed)
```

- **Three separate columns**, left to right; never compressed. One event per column still applies.
- Place the chain **immediately after the external event's narrative position**; don't move it to the start of the story. If the external event isn't modeled yet, introduce it first in its own system's swimlane.
- The internal event is the moment external data becomes a business fact in this domain's language.
- **Naming**: name the internal event for its business meaning; usually keep the external business name (external `CopyReserved` → internal `CopyReserved`; the swimlane distinguishes ownership). If the external name is technical, translate it to a domain name. Reject transport suffixes: `…SignalReceived`, `…RequestReceived`, `…Synced`. Prefer `RecordReservation`, not `RecordReservationSignal`.

### 7.2 Discovery

Interview when external systems are incompletely catalogued or rules unclear:

- Inventory each external source, all event types it supplies, a representative payload of each.
- Does each source include our entity identity or require correlation?
- Mapping complexity: direct mapping; aggregation of several events; dependence on data from another system. For multi-source cases: what context must be looked up, and what if the event arrives before that context exists?
- Mark high-risk multi-source integrations.

### 7.3 Field analysis

Don't accept external fields unchanged; look for opaque external ids, values needing unit/format conversion (cents → decimal), a status field that encodes a business fact, foreign ids not matching domain identity. Map every relevant source field to a business concept and identify required domain fields absent from the source. Classify each gap:

- **Enrich** — look up context in *our* system (not by asking the external source to define it).
- **Ignore** — irrelevant to this domain (e.g. precise latitude/longitude when we only care that the guest left).
- **Infer** — safe conclusion from the event itself.

Use sensible defaults or explicit failure; never silently assume.

### 7.4 Correlation

- Establish the correlation bridge **on our side when initiating the external action**: record the relationship between our entity identity and the external identity (e.g. an `OrderPaymentReference` pairing `orderId` with the payment reference), **or** send our identity with the request so the external system echoes it back.
- When the external fact arrives, recover our identity before recording a domain fact.
- Keep a **correlation inventory**: internal entity, external source, external identity, where the relationship is retained, how it is recovered.

### 7.5 Idempotency and failure

- Translation is **idempotent**: check whether the domain event already exists for that external identity; a repeated fact creates no second domain fact.
- Keep the external identity as a **deduplication/reconciliation reference** (`paymentGatewayRef`), never as the domain entity's primary identity.
- For each translation define: trigger, preconditions, ordered steps (extract → validate preconditions → enrich → record fact), observable success, and every failure: missing correlation, invalid state, repeated delivery, invalid/partial data, out-of-order arrival. Unhandled cases route to manual review.

### 7.6 Principles

**Correlation first** · **Translate intent, not just field names** · **No leakage** of foreign primary identities or foreign data shapes into the domain · **Idempotent** · **Validate always** · **Enrich from our source** · **Default gracefully**.

Reject: external payment id as internal primary key; translation without correlation; copying external representation into domain events; trusting unvalidated data; processing duplicates twice.

### 7.7 Translation patterns

| Pattern | Flow | Example |
|---|---|---|
| Simple mapping | notification → validate → map → record | gateway success → `PaymentAuthorized` |
| Correlation lookup | notification → extract reference → recover entity → enrich → record | location exit + guest identity + room → `GuestLeftHotel` |
| Periodic observation | scheduled check → obtain changes → extract facts → translate → record | inventory availability every five minutes |
| Missing-context | partial fact → extract → obtain missing context → enrich → record | fulfilment confirmation carrying only an order id |

### 7.8 Scenario coverage for translations

Verify: happy path produces the correct business event; absent correlation (including arrival before the entity exists); the same fact delivered twice; invalid data missing required fields; partial data; facts arriving out of order.

### 7.9 Translation write-up template

Sources and event types; supplied representation per event; field-to-domain mapping with notes; correlation method; produced business event and field sources; ordered translation steps; success/failure scenarios; duplicate handling; correlation inventory; failure detection and recovery.


---

## 8. Deep Dive: Read-Model Design

### 8.1 Consumer completeness

Canonical shapes: **READ MODEL → SCREEN** (pure view); **READ MODEL → SCREEN → COMMAND → EVENT** (input screens usually need prior state — a booking form shows availability, checkout shows the cart); **READ MODEL → AUTOMATION → COMMAND → EVENT**.

- Enumerate **every** screen and automation before designing projections.
- Every view screen needs ≥1 read model.
- Every input screen needs one **unless it is a genuinely blank creation form** with no prior state to show — rare, must be justified, never inferred from missing field definitions. "Session context" or "accepted debt" is not an exemption. Even a small identity/lookup model counts.
- Every automation has a todo list — never exempt.
- A consumer without an incoming projection is a gap; a read model without a consumer is an orphan (unless it is genuinely consumed by another purpose, e.g. internal or feeding another view — judge actual downstream purpose).
- Read models are tailor-made for one screen/component: default 1:1 read model ↔ consumer; a read model reused by several screens is rare and worth double-checking.

### 8.2 Components

**"One component in a screen resembles one read model."** A component is a group of fields perceived as a distinct area: stats tile, list, summary card, detail panel.

- Most screens have exactly one component — **don't force a split**. Split when a user would point at two areas and describe them as different things.
- A **homogeneous list/table is one component** even if rows depend on many event types — don't split by row or by source event.
- But don't let the list rule hide different **kinds of computation**: rarely-changing title/author (1–2 events) and live per-copy availability (repair, loss, reservation, return) are separate components even on one page.
- A screen with N components gets **N read models and N highlighted screen copies** — never one monolithic screen-wide projection ("god read model").
- Each copy keeps the **original screen title** (both are "Librarian Dashboard", not "Librarian Dashboard — Statistics"). Highlight that copy's component; dim/blur the rest. Each copy's field list covers only its highlighted component.
- Put each copy in its own column with the read model that feeds it, near that read model's source events. Independently changing components have different event drivers, update rates, ownership and release cadence; a monolithic projection couples them and invites backward arrows.

### 8.3 Fan-in heuristic (field-by-field)

When a read model is connected to **more than three events**, first assume it should become two or more narrower models; keeping wide fan-in bears the burden of proof. Perform both checks per field:

1. **Field-level minimality** — derive exactly which events each field needs; remove every connection no field's mapping uses.
2. **Kind-of-computation split** — fields fed by one or two simple events (identity, monotonic counter) differ fundamentally from a live-state field spanning the entity lifecycle. If both are bundled, isolate the wide field(s) into their own read model and screen copy.

A legitimate wide field never excuses narrow fields riding alongside it. If irreducible single-field fan-in remains, **document the specific field and why** (e.g. `CopyAvailabilityView.copyStatus` reflects the copy's full lifecycle) — a per-field justification, never a blanket "roll-up" exemption. Re-evaluate every time the read model is touched.

### 8.4 Defining read-model fields

- Use the **existing screen field mappings** as the specification: group screen fields by the read model named in `ReadModel.field` mappings — that gives the read model's title and field list. Mappings to commands, session or derived values are not, on their own, projection requirements.
- Every read model has fields; every field has a mapping (§2.10); every field traces to ≥1 connected source event, or a documented derived expression, or the missing field is added to the source event first.
- Mark the read model list-shaped where applicable; set field cardinality explicitly.
- Include only fields actually displayed or needed by the consumer.

### 8.5 Reasoning note per read model

Keep **one** note beside each read model recording every incoming event, which fields it sets or changes, and why. Extend it when sources are added; never create a competing second note.

> `OrderPlaced` creates the order and sets `orderId`, status "placed", `items`; `OrderShipped` changes status to "shipped" and supplies the only `trackingNumber`; `OrderCancelled` sets terminal status "cancelled".

### 8.6 Verification

Before declaring outputs complete, re-inspect every screen and automation (not the list from the start) and mark each **connected / exempt (blank form) / fixed**. Check: multi-component screens split; fan-in heuristic re-applied per field; notes cover all current sources; no sourceless read models; no multiple screens per column; no backward read-model→screen arrows; cancellation/compensation handled; error states shown.

### 8.7 Common projection patterns

| Pattern | Built from | Purpose |
|---|---|---|
| Status view | lifecycle events | current state |
| List view | create/update/delete-or-cancel | summaries for filter/sort/search |
| Timeline view | timestamped events | history and audit |
| Processor decision view | state-changing facts | current state an automation decides on |

### 8.8 Read-model catalog entry

Name, purpose, source events, fields, update logic per event, consuming screens/processors, freshness tier.

> **OrderStatusView** — purpose: current order status. Sources: `OrderCreated` (insert, Draft), `OrderConfirmed` (Confirmed + `confirmedAt`), `PaymentAuthorized` (Authorized + `paymentId`), `OrderShipped` (Shipped + `shipmentId`, carrier, `trackingNumber`), `DeliveryConfirmed` (Delivered), `OrderCancelled` (Cancelled). Consumers: Order Status screen, Customer Dashboard, shipment-eligibility processor.

---

## 9. Deep Dive: Specifications (GWT and Storylines)

### 9.1 Two forms

- **Given–When–Then (GWT)** — one isolated transition: precondition → action → outcome.
- **Storyline** — one use case narrated as ordered **beats**, revisiting the same element across states; a single GWT can't express a lifecycle.

**Commands always use GWT — never a command storyline.** A command checks one input against state and succeeds or rejects; it has no state progression of its own.

**Per read model, decide separately**: does replaying its connected events more than once create interesting accumulating/changing state? Yes → storyline; no → GWT only. Decide before drafting, and produce a visible decision list (read model → storyline / GWT-only + short reason). One reused schema for everything signals the judgment was skipped.

- A repeated single event type qualifies: `AccountFunded($40)` then `AccountFunded($70)` → balance $40 → $110.
- **Todo lists are prime storyline candidates**: `Todos` empty → `CustomerRegistered` → one "activate your account" entry → `CustomerActivated` → empty again.
- Storyline and GWT are complementary: the storyline narrates the lifecycle; add GWTs only for uncovered validation failures, cross-context sourcing, or transitions outside that flow. Delete GWTs that merely repeat a beat; fix/delete contradictory ones (e.g. claiming two entities coexist when one supersedes the other).

### 9.2 Formal grammar

| Spec type | Given | When | Then |
|---|---|---|---|
| State change | prior **events** (empty = no history / creation) | **at most one command** | resulting **events**, or an expected error |
| State view | source **events** | **empty** | **exactly one read model** (expected query result) |
| Automation | setup events first, **trigger event last** | — | the **command** dispatched, or NOTHING |
| Error case | events establishing the invalid state (none for pure input validation) | the command | empty, flagged as expected error with a short human-readable reason |

- Never mix events and a read model in one Then.
- All referenced elements belong to the same chapter.
- Each specification belongs to its command/read-model column; unique titles that express the business rule ("Late bid is rejected").

### 9.3 Quality of a scenario

- **Explicit givens**: "Order in Draft: `OrderCreated` present, no `OrderConfirmed`" — not "Given an order".
- **Clear action**: "customer confirms the order" — not "when stuff happens".
- **Verifiable then**: the produced event with concrete field values, or rejection with a precise reason — not "it works", "an event is produced", "there's an error".
- Business language, not technical jargon.
- **List-shaped outcomes** give one concrete example record per expected row; an empty list is **explicitly asserted** as intentionally empty (absent examples could mean "not filled in yet").
- **Rejection ≠ empty list.** Rejection is an error case; empty-list assertions belong only to list-shaped read-model outcomes.
- Distinguish a **rejected command** (no event) from a **recorded domain failure** (e.g. `PaymentFailed` with order, reason, timestamp after an external decline).

### 9.4 Command coverage — the seven questions

Never reduce a command to a good-case/bad-case pair. Review all seven for **every** command and write every applicable one; skip only when the situation genuinely cannot occur, documenting why.

| # | Type | Question |
|---|---|---|
| 1 | Happy path | What is the normal success case? |
| 2 | Validation failure | Which invalid or missing inputs must be rejected? |
| 3 | State violation | In which state is this command invalid? |
| 4 | Duplicate action | What happens if it is issued again after success? |
| 5 | Alternative path | What other valid outcomes depend on context? |
| 6 | External failure | What if an external system or scheduler fails? |
| 7 | Compensation | Can it be reversed/undone; what triggers cleanup? |

Every business rule yields at least one scenario: a happy path plus an error case if it can be violated. Use actual thresholds and test both sides (an eligibility limit of €2M tested just above and just below). Model only the defined part when an outcome depends on an unknown rule; record the gap.

### 9.5 Read-model coverage — independent mandatory pass

- **Every read model has ≥1 view specification** (GWT with empty When, or storyline), including todo lists. Many command scenarios with zero view scenarios is incomplete.
- Cover **population** (events → correct fields/rows) and, where applicable, **update/removal** (expiry, return, archival, status change), asserting explicitly empty output when a list empties.
- For a todo list, a later closing event is normal — add the missing source arrow (exception applies) rather than calling removal impossible.
- For a screen-only projection, later changes are specified against the forward-placed linked copy (§3.8).
- Omit a removal scenario only with a documented gap when the superseding event genuinely lives in another chapter.
- **Cross-chapter sources**: write the scenario with an empty Given and state the cross-chapter sourcing limitation in the title — don't omit it and don't fabricate local events.

### 9.6 Storyline beats

- Each beat references an actual model element (any type, including a resulting screen); the same element may recur with different example state.
- An error beat is an alternate branch off the previous beat.
- Beats carry concrete fields, row examples, or explicit empty-list intent.

### 9.7 Scenario discovery interview

Skip if coverage goals, edge cases and reviewers are known. Otherwise ask: coverage goal (happy + basic validation / all variations / comprehensive for production); critical rules and edge cases ("cancel within 24 hours", payment-decline recovery) — what demonstrates each and what happens when violated (edge cases expose missing events); purpose (automated tests need precision, documentation can be narrative); reviewers (product owner, tester, several roles — multi-role review catches business errors).

### 9.8 Worked scenarios (order domain)

| Title | Given | When | Then |
|---|---|---|---|
| Create order | customer cust-123 and products exist | CreateOrder(prod-1 ×2 @50, prod-2 ×1 @30) | `OrderCreated` (Draft, total 130) |
| Unknown customer | — | CreateOrder(unknown customer) | ✗ "Customer not found" |
| Empty order | — | CreateOrder(items = []) | ✗ "Order must contain items" |
| Incomplete address | — | CreateOrder(no city) | ✗ "Invalid shipping address" |
| Confirm draft | `OrderCreated` (order-456) | ConfirmOrder(card) | `OrderConfirmed`(orderId, card, confirmedAt) |
| Confirm twice | `OrderCreated`, `OrderConfirmed` | ConfirmOrder | ✗ "Order already confirmed" |
| Confirm cancelled | `OrderCreated`, `OrderCancelled` | ConfirmOrder | ✗ "Cannot confirm cancelled order" |
| Card declined | `OrderConfirmed`, payment initiated | gateway declines | `PaymentFailed`(orderId, "Card declined", timestamp) |
| Retry after failure | `PaymentFailed`, order still Confirmed | AuthorizePayment | accepted → `PaymentAuthorized` |
| Cancel draft | `OrderCreated` (order-555) | CancelOrder("Changed mind") | `OrderCancelled` |
| Cancel delivered | … `DeliveryConfirmed` | CancelOrder | ✗ "Cannot cancel delivered order" |
| Status view | `OrderCreated`(order-789, total 150) | — | OrderStatusView: Draft, $150.00, 3 products |
| View accumulates | + `OrderConfirmed`, + `PaymentAuthorized`(pay-123, AUTH-456) | — | Confirmed → Authorized, paymentId, authCode |
| Product list | `ProductCreated`(Shoes), `ProductCreated`(Clothing) | — | two rows with exact values |
| Last product deleted | … `ProductDeleted` (last) | — | **explicitly empty list** |

---

## 10. Deep Dive: Entity Timelines / Stream Boundaries

### 10.1 Purpose and golden question

Confirm each entity's history is anchored on **one natural business identity**, not an unbounded collection or a log disguised as an entity.

> **"Does this timeline actually have one business identity, or is it a collection/log wearing an entity's name?"**
> Every history must answer **"the history of exactly which entity?"** — "a category of things" and "everything" are wrong answers.

**Length alone is never a problem**: a bank account open for thirty years correctly has a long history. A boundary is wrong when events don't all belong to the same entity's lifecycle.

### 10.2 Review steps

1. Name the single entity identity explicitly — `orderId`, not "orders".
2. Check every event: did it happen to *this* entity (not a category, not the system)?
3. Classify and correct:

| Result | Meaning | Action |
|---|---|---|
| All events belong to one clear entity | Correct | Keep, regardless of length |
| Events describe a category / "all X" | Collection anti-pattern | Per-entity histories; the category becomes a read model |
| Users, orders, payments mixed | Event-log anti-pattern | One timeline per entity/concern |
| Active entity and historical record conflated | Missing split | Separate operational and archived histories (where lifecycles/consumers genuinely differ) |

### 10.3 Boundary patterns

1. **Single entity (most common)** — one timeline per business entity (Order/`orderId`: created, lines added, confirmed, paid, shipped, delivered). Everything about *this* order, nothing else.
2. **Composite entity** — a parent with a **small, bounded** set of children sharing its lifetime, created/destroyed together, changing as a unit (order lines, shipping address). Split a child only if it has an independent lifecycle.
3. **Collection (anti-pattern)** — `AllOrders` with an artificial identity, no natural end. Replace with per-order histories plus projections (orders by customer, by status).
4. **Event log (anti-pattern)** — `SystemLog` mixing logins, orders, payments, inventory. Unrelated facts produce no meaningful state. Split.
5. **Historical entity (good when needed)** — `ArchivedOrder` (own identity, immutable record with audit history, e.g. seven-year retention) separate from the operational Order.

### 10.4 Identity decision tree

- No natural business identity → not an entity: model as read model/report.
- Natural identity and every event belongs to it → correct.
- Natural identity but some facts concern another entity → too wide: split by the entity each event concerns (User → UserProfile + UserSessions; Order → Order + OrderLineItems **only if** line items live independently).

### 10.5 Red flags

- Continuous growth with no natural end *because the identity spans an unbounded population* (not because one entity keeps changing).
- Events with no shared business meaning (`SystemMetricRecorded` is operational observation, not a business history).
- Unrelated entities in one history.
- You can't state the single business question the timeline answers.

### 10.6 Domain reference (illustrative lifetimes)

| Entity | Identity | Lifetime | Guidance |
|---|---|---|---|
| Order | `orderId` | 1–3 yrs | ends delivered / cancelled / refunded |
| Cart | `cartId` (or `customerId` only if exactly one active cart) | 30 min–2 yrs | split abandoned vs. active if behavior diverges |
| User account | `userId` | 5–10+ yrs | split profile / preferences / sessions (different change rates) |
| Bank account | `accountId` | 10–50+ yrs | decades of events don't justify splitting |
| Bank transaction | `transactionId` | 1–2 months then archived | own short history, not folded into Account |
| Loan | `loanId` | 5–30 yrs | active/completed split only if consumers differ |
| Subscription | `subscriptionId` | 1–5+ yrs | created, upgraded, downgraded, cancelled |
| Workspace | `workspaceId` | 2–5+ yrs | member activity separate only if access patterns differ |

Boundaries are chosen by **entity identity**, never by category or time window. Durations are examples, not thresholds.

### 10.7 Consistency boundaries per rule

The set of prior facts a rule considers is **a property of the rule, not of the event type**: include each kind of fact only to the extent *this* decision needs it. Example (`SubscribeToCourse`, identity = email + courseId): "is this customer registered?" needs `CustomerRegistered` for that email only; "already subscribed to *this* course?" needs `SubscribedToCourse` for that email **and** that course — not all of the customer's subscriptions. Too wide a scope pulls in unrelated facts; too narrow silently drops facts the rule needed. The same event type can legitimately be scoped differently by a read-side question ("how many courses is this customer subscribed to?").

---

## 11. Deep Dive: Conway's Law and Ownership

**"System architecture mirrors team structure."** Separate teams ↔ separate systems; each system owns its events; communication is through events; boundaries align with organisational ownership. Benefits: team independence, clear responsibility, independent evolution, scaling and deployment.

### 11.1 Interview

Skip if team structure, responsibilities and autonomy goals are known. Otherwise: one team, domain teams, or functional teams (suggest domain organisation)? Desired autonomy — very high (strict event boundaries, minimal cross-team talk), moderate (event-mediated coordination), low (coupling acceptable — but ask why)? External integrations and who owns each?

### 11.2 Workflow

1. Identify each system/bounded context: what it owns, events produced, state machine it's responsible for.
2. Draw a time-ordered ownership analysis, one row per team, showing where coordination crosses rows — **an analysis device, not an instruction to create one modeling swimlane per team**.
3. Per team: commands handled, events produced, read models maintained, dependencies.
4. Per communicating pair: triggering event → consuming system's reaction/command → resulting event (at full detail, still via translation + todo lists, §6–7).
5. Interfaces: accepted commands and their sources; events/read models provided.
6. Each processor: explicit triggers, logic, command(s), owning system.

### 11.3 Ownership checklist

Every system has a clear owner and boundary; events map to systems; commands map to teams; cross-system communication documented; **no circular dependencies** (circular → redesign the boundary); every team has independent scope; processors have owning systems; external systems identified; interfaces clear.

### 11.4 Example

| Team | Commands | Events | Read models | Consumes |
|---|---|---|---|---|
| Order Management | CreateOrder, ConfirmOrder, CancelOrder | OrderCreated, OrderConfirmed, OrderCancelled | OrderStatusView, OrderListView | PaymentAuthorized, InventoryReserved |
| Payment | AuthorizePayment, ProcessPayment, RefundPayment | PaymentAuthorized, PaymentFailed, PaymentRefunded | PaymentStatusView, TransactionHistory | OrderConfirmed |
| Inventory | ReserveInventory, ReleaseReservation, AllocateStock | InventoryReserved, ReservationReleased, StockAllocated | InventoryLevelView, ReservationView | PaymentAuthorized |
| Fulfilment | CreateShipment, MarkShipped, ConfirmDelivery | ShipmentCreated, OrderShipped, DeliveryConfirmed | ShipmentTrackingView, DeliveryScheduleView | InventoryReserved |

Flow: `OrderCreated → OrderConfirmed → PaymentAuthorized → InventoryReserved → OrderShipped → DeliveryConfirmed`, each event owned by its producer and coordinating the next team's work.


---

## 12. Quality: Shapes, Completeness, Validation

### 12.1 Structural shapes

Four recurring connection shapes. Internal nicknames — **never use "bed", "left chair", "right chair", "shelf" with business stakeholders**; describe the concern in plain words.

| Shape | Definition | Status | Ask (plain language) |
|---|---|---|---|
| **The bed** | one SCREEN wired to more than one COMMAND | **Always an anti-pattern** — a screen is one committed decision; several commands hide where the choice is made | "This screen lets someone trigger more than one action from the same place — should this be separate steps so it's clear which one they're choosing?" |
| **Left chair** | one COMMAND producing more than two EVENTs | Candidate | "When this action succeeds, do all of these always happen together, or could some happen without the others?" |
| **Right chair** | one READ MODEL built from more than three EVENTs | Candidate | "Is this screen answering one question, or several bundled together?" |
| **Shelf** | one slice with noticeably more scenarios than others on the timeline (no fixed threshold) | Candidate | "This step has many more cases than its neighbours — is it really doing more, or covering something that should be its own step?" |

Candidates are flagged only after reasoning about the actual events/fields/scenarios shows several jobs; raw counts alone never suffice. Drop domain-justified candidates silently. Review shapes across the whole graph, not slice by slice.

### 12.2 Quick self-check (fast pass)

- [ ] Every event is past tense and a business fact
- [ ] Every command is imperative business intent, not a query
- [ ] Every read model is named for its data
- [ ] No event holds a computed/aggregated value
- [ ] Every command has exactly one issuer and traces to a screen or automation
- [ ] The timeline starts with a state view or an automation reacting to an event
- [ ] No state-change → state-change without a new trigger
- [ ] No screen wired to more than one command

### 12.3 Completeness (Step 8)

Field-level origin/destination coverage, from the actual model (not memory), across every timeline and connected context.

- For every **event field**: origin (command input, calculation, system generation) and all consumers (events, read models, external systems).
- Every **command input** is captured in the resulting event/state.
- Every **displayed read-model field** comes from a connected event; derived fields have traceable inputs. No "magic" data.
- Every command/read-model column has a slice (except linked copies).
- Walk the **whole scenario** from creation to terminal state, plus alternatives: cancellations, failures, compensations.
- Per system/context: non-overlapping event ownership; processors react only to events they are entitled to.
- Treat each step as a **contract**: explicit preconditions (usually the previous step's postcondition) and postconditions (resulting event and its fields) so teams can build against it in parallel.
- Build a whole-model **field matrix** (event / command / read model / processor).
- Before declaring a gap, check whether the data exists elsewhere. Attach required fixes as tasks on elements, genuine questions as comments.
- **Duplicates vs. linked copies**: same type and title is not evidence of duplication — check the copy relationship first; flag only independent, unlinked elements describing the same concept.
- Review every "calculated event" (fact vs. calculation) and classify processor outputs (§2.8).
- On gaps, return to the right modeling step, fix, rerun.

| Common gap | Fix |
|---|---|
| Missing failure event / cancellation flow | Add the missing fact / outcome modeling |
| View field absent from events | Add the field to the source event, or drop the view field |
| View needs a date nothing supplies | Add it to the event (e.g. `expectedShip` on `InventoryReserved`) |
| Unclear origin | Trace backward to the source |
| Circular dependency | Redesign the boundary |
| Calculation modeled as event | Move to a read model |
| False duplicate | Check linked-copy status |
| Missing slice | Define it on the original element's column |

**Completeness checklist**: every field has origin and destinations; every input captured; all read models sourced; scenarios have data sources; no magic data; logical end-to-end flow; no missing transitions; alternatives and errors covered; processors identified; boundaries clear; no circular dependencies; stakeholder needs met; slices present; step contracts explicit.

### 12.4 Validation (Step 9)

Read-only review: model elements don't change; only comments/tasks are added. Critical violations become required-fix tasks; warnings become comments.

**Structural pass** (per chapter) — necessary but not sufficient:

1. Unplaced elements.
2. Backward arrows (except the todo-list `EVENT → READ MODEL`).
3. Commands with zero or multiple issuers (keep the deliberate same-column issuer, remove stray ones).
4. Read models with no inbound event.
5. More than one screen in a column.
6. Command/read-model columns without scenarios.

**Semantic pass**:

- *Entities*: clear identity, ≥1 event type, an initial event, documented transitions.
- *Events*: past tense, facts only, immutable, unique semantics, no computed fields.
- *Read models*: deterministic, side-effect-free, regenerable, needed for a specific query.
- *Commands*: clear parameters; concrete preconditions ("only confirm if Draft", not "can sometimes confirm"); resulting events or documented rejection; no silent failures; failed-precondition behavior defined.
- *Transitions*: valid and invalid ones explicit (`Draft → Confirmed`, `Draft → Cancelled`, `Confirmed → Shipped`; `Confirmed → Draft` invalid).
- *Command field sources*: every command field sourced from a transitively connected read model, explicit generation, or scenarios.
- *Actors*: Role Catalog exists (missing = critical); every command attributed to a specific role; every human role has ≥1 command and ≥1 read model; permission boundaries respected.
- *Common findings*: missing cancellation outcomes; implicit preconditions; orphaned events consumed by nothing; undocumented state queried by commands; multi-issuer commands.

### 12.5 Structural validation checklist (13+ checks, seven phases)

Use after plotting (early gate) and again after validation (final pass), when reviewing an existing model, or whenever the structure feels suspicious. Re-run after fixes.

| Phase | Check |
|---|---|
| 1 Ownership | 1.1 each event belongs to exactly one entity/timeline · 1.2 each command has exactly one issuer |
| 2 Event quality | 2.1 facts, not calculations/aggregations · 2.2 immutable · 2.3 past tense, actually happened |
| 3 Read model vs. event | 3.1 a read model is not an event timeline · 3.2 every read model has a natural query pattern |
| 4 Business rules | 4.1 command preconditions documented · 4.2 event-related preconditions explicit (no "obviously can't ship unconfirmed orders") |
| 5 Traceability | 5.1 input → event → read model complete; nothing disappears, nothing appears from nowhere |
| 6 Event flow | 6.1 no impossible sequences/combinations · 6.2 no event owned by two timelines |
| 7 Shapes | 7.1 no screen → several commands · 7.2 inspect fan-out/fan-in/scenario outliers in context |

**Final questions (both must be YES)**: Could a modeler new to the domain understand the model in **15 minutes**? Could a read model's calculation change **without rewriting event history**?

**Verdict**: exactly **PASS / PASS WITH WARNINGS / FAIL**, with confidence %, PASS/FAIL per check with evidence; for each anti-pattern: name, exact element, why, failed checks, fix. **Targeted fixes** when failures are local; **redesign** when several phases fail, core assumptions are wrong, anti-patterns are systemic, or the core timeline must be rewritten.

---

## 13. Collaboration, Facilitation and Governance

### 13.1 Interview protocol

- Ask focused questions only when information needed for the current step is missing or ambiguous; never ask what is already known.
- **One question per turn**, the one that most advances discovery.
- When no one can answer (unattended work) or you were told not to ask: don't block — take the most reasonable assumption, state it **visibly with its reason**, and keep it correctable; never guess silently.
- Record questions/answers or assumptions per step; keep a trail of step, status, key outputs.

### 13.2 Open questions vs. decided failures

- **Open question** — genuinely undecided. A comment worded as a question on the relevant element; stays open until answered (resolving = answering, not deleting). Only these count as completeness gaps.
- **Decided failure** — a failure path whose behavior is already decided. If the command is simply refused because a precondition doesn't hold (e.g. "cannot confirm an already-confirmed order"), model a **rejection error scenario** (expected error + description, no event). If the failure is itself a business fact (e.g. "payment declined" → `PaymentFailed`), model the **failure event** and its scenario. Either way it is specified behavior — never a lingering question.
- Raise questions only for **real business gaps**; check existing open questions first and never repeat one. If any defensible interpretation exists, take it and say so rather than parking it as a question. Questions must be distinct, relevant, answerable in one line.
- Hotspots (pain points, disputes) are red notes next to the element, not events.

### 13.3 Business review ("what do you think?")

Review business logic, not code: flows, failure paths, edge cases, missing constraints, ownership, real-world messiness. Read the whole context (fields, scenarios, actors, automations, existing comments) first. Ask pointed questions only where genuinely unclear; zero questions is a valid outcome. One short sentence per comment, curious and direct ("What happens when X fails?").

**Speak business language** to stakeholders — avoid "command", "event", "read model", "slice", "GWT", "spec". Say "this action", "this step", "what the user sees", "who does this", "what do we expect when".

| Category | Ask (only with model evidence) |
|---|---|
| Failure | "Can this fail?" — skip if an error outcome already covers it; for external systems: what if they don't respond? |
| Duplicates/replay | Only with concrete evidence (natural key, uniqueness rule, repeatedly firing automation): could the user trigger it twice? could an automation process the same fact twice? |
| Preconditions | What must hold first; which states reject it ("can a shipped order be cancelled?"); implied lifecycle created → active → suspended → deleted |
| Missing views | Only gaps clearly implied by the current graph (an unwired action, a view feeding nothing) — don't infer missing screens from absence |
| Missing scenarios | Turn fields into questions ("What happens when a customer registers without a name?"); with none: 1 happy path + 1–2 field-grounded edges |
| Permissions | Who does this? Can one person act for another? Do team/company boundaries matter? |
| Time/order | Does order matter? Out-of-order arrival? Expiry, deadlines, payment windows, scheduled work? |
| Data | Missing fields only when a downstream element needs them; never flag infrastructure ids, timestamps, versions |

Place questions on the relevant element (whole-slice questions on its first event; shape concerns on the central element); add a relationship arrow only when a finding inherently concerns two elements.

### 13.4 Collaborative modeling etiquette

- Do **what was requested and nothing else**; mention neighbouring gaps instead of fixing them unasked.
- Use the collaborator's actual selection/focus to resolve "this/here"; an explicit named target wins.
- Answering a question about the model changes nothing.
- Distinguish proposals from authorisation; show before/after; an offer changes nothing. "ok, but only the scenarios" approves only the scenarios; "yes, but call it OrderSubmitted" approves the amended plan; "leave it" declines.
- Don't undo a human's model; unrequested deletions, renames, restructuring, reordering or status changes are proposals.
- Additive completion is welcome where evidence exists: missing examples, missing scenarios, a field missing along its chain, an empty screen, an obviously missing slice, one real question. Don't complete half-finished elements (placeholder name, no fields); don't manufacture work when there are no gaps.
- One owner per slice/chain at a time — never split concurrent editors across the same chain.
- Report briefly, using element names, leading with the result — and always state **what was not done** and why.

### 13.5 Slice status lifecycle

| Status | Meaning |
|---|---|
| Created | Exists, not started — **the only status freely editable in modeling** |
| Planned | Ready to build (build trigger) |
| Assigned | Assigned to someone |
| InProgress | Being implemented (claimed) |
| Review | Ready for review |
| Done | Completed |
| Blocked | Impossible to proceed without a human answer |
| Informational | Reference only |

Progress order: Created → Planned → Assigned → InProgress → Review → Done. Reopening = moving away from Done. A useful rework metric: share of slices reaching Done that never came back ("first-time-right rate").

### 13.6 Governance: the edit lock

- Only slices in **Created** (and elements in no slice) may be modified without explicit confirmation. Any other status means someone owns the work: read freely, but don't change, move, rename, delete, or add fields/examples/scenarios.
- Confirmation unlocks **only the named elements and proposed changes** — not other slices, not the board. An unclear answer is not confirmation. Explain that editing Done work reopens it.
- If a request partly touches locked work: do the unlocked part, state precisely what was left and why. If no one is available, change nothing locked and comment which status blocked it.
- A chain-wide edit touching a locked element is blocked as a whole.
- Moving a slice into the status it is already in is rejected — a concurrency guard meaning someone else claimed it; move on, don't retry.

### 13.7 Workshop facilitation

**Participants** (5–8 ideal): product owner/domain expert (rules, priorities), 2–3 developers (feasibility), 1–2 testers (coverage, edge cases), 1 facilitator (pace, shared understanding); optional UX, security, operations, real users.

**Preparation**: invite a week ahead with domain, objective, date, duration, prep prompts (workflows, candidate events, key state changes, questions). Physical: wall 8+ ft wide, colour stickies, markers, visible timer, camera. Remote: shared canvas, video, recording, side channel. Colour convention: **events green, commands blue, views orange**; hotspots red.

| Step | Time | Script |
|---|---|---|
| 1 Brainstorm | 15–20 min | 2 min framing ("imagine the system running for years — what important changes happen?"), 8–10 min free capture (no filtering), 5–7 min gentle filtering ("did state actually change?"). "Customer viewed page" → nothing changed; "added item" → `ItemAddedToCart`; checking inventory → no change; reserving it → `InventoryReserved` |
| 2 Plot | ~15 min | 5 min order ("what happens first?"), 5 min branches ("what if payment fails?"), 5 min parallel flows. Don't get stuck on exact timing |
| 3 Storyboard | 5–7 min/screen | choose screen, draw and label fields, trace data into event and next screen, check missing info |
| 4 Inputs | ~20 min | extract screen actions, identify automated actions, specify inputs and sources, record validations |
| 5 Outputs | ~15 min | events per command with fields, needed views and their shape, event → view updates |
| 6 Boundaries | ~17 min | who does what; internal vs. external; event owners; team assignment |
| 7 Scenarios | 5–7 min/command | happy path first, obvious failures, invalid states, alternatives |

**Scenario cycle per command (15–20 min, target 3–5 scenarios)**: happy path (product owner) → input failures (developer/tester) → state violations (domain expert) → alternatives (product owner) → external failures & retry (developer) → compensation (domain expert — often exposes missing events). Read each aloud, confirm or object, move on. Capture "What if…?" immediately; record *why* behavior was chosen. Avoid 30 minutes on one scenario, missing roles, technical language, vague givens, unspecified outcomes.

**Dynamics**: invite quiet participants directly; redirect dominant voices politely; take sceptics seriously; capture idea-generators and sort later. 5–7 min per item; breaks every 45–60 min (remote: 90-minute sessions, 10-minute break every 30 min, ideas added before discussion). On disagreement: clear answer → use it; reasonable disagreement → document both and continue; irrelevant now → defer to implementation; always record the decision.

**Sample multi-day agenda**: Day 1 (4h) steps 1–3; Day 2 (4h) steps 4–7 intro; Day 3 (3h) detailed scenarios, findings, next steps.

**Follow-through**: same day — photograph/digitise, share, add rationale, list unclear items; within 1–2 days — summary of coverage, decisions, questions; owners and next workshop.

**Good signals**: everyone participates, decisions recorded, artifacts shared, team understands the model, clear next steps. **Warning signs**: silent attendees, unclear decisions, missing artifacts, technology debates displacing fundamentals, fatigue.

---

## 14. Alternative Entry Points

### 14.1 From source documents (tenders, contracts, specifications)

- **"Faithfulness over fluency."** The source is authoritative; read all in-scope content — a missed deadline, exclusion or penalty is a defect. Never omit silently; make scope trade-offs explicit. Transcribe images before extracting flows.
- **State the perspective** (a tender from the bidder's side is intake → go/no-go → preparation → submission; from the issuer's side publication → evaluation → award). Infer, state the assumption, continue.
- Keep a **fact ledger**: id, kind (actor, process, event, deadline, rule, requirement, data, unknown), statement, source location, certainty (stated / implied / assumed). Conflicting passages become an *unknown* citing both. Preserve numbers, thresholds, dates verbatim ("≥ €2 million in each of the last 3 fiscal years", not "minimum turnover required"). Generic domain knowledge goes only into risks/questions.
- Plan chapters first (one coherent process/bounded context; split phases with distinct actors/rules/deadlines; ~6–15 columns per chapter).

| Source fact | Destination |
|---|---|
| Event / deadline passing | Past-tense event (deadlines via automations) |
| Human process step | screen → command → event |
| Rule | command precondition + error scenario, a derived read-model condition, or a separate decision |
| Requirement | tracker/checklist row and/or proof-providing command field |
| Data | command/event/read-model/screen fields |
| Unknown | question on the relevant element |

- Another organisation's facts are external events in their own swimlane, translated (publication, clarification answer, award announcement); add a worker only for a genuinely new decision.
- Per chapter: events & role catalog → screens per human decision point → commands & fields → translations/automation chains → views needed for decisions → scenarios/storylines → slices. Use real dates, weights and values in screens (overview, eligibility checklist, deadline calendar, requirement tracker, pricing sheet, submission checklist, scorecard, award notice).
- Reconcile every ledger fact against the model; add omissions or list them as deliberately not modeled.
- **Chapter summary note** (written after modeling): scope/actors/start/end; dates with source and consequence; verbatim rules with modeled location; mandatory vs. optional requirements; exchanged data; element counts and slice types; external parties; questions/risks; assumptions; omissions. The first chapter also carries the document-wide overview (perspective, at-a-glance, go/no-go criteria, scoring method, chapter table, suggested build order and first thin slice).
- On amended sources, update affected facts/chapters rather than rebuilding.

### 14.2 From existing code (reverse engineering)

**"The code gives you a hypothesis; the person gives you the truth."** Technical constructs are evidence, never element names.

**Four evidence lenses**: (1) entry points and callers — human writes/reads vs. jobs/listeners/external calls; (2) tests — vocabulary, GWT, failure rules, example data; (3) persisted writes — candidate events, aggregate boundaries, status/enum lifecycles, joined reads → views; (4) UI — forms/buttons → decisions, lists/details → views, navigation → flow and language. Entry points and persistence carry most signal; tests and UI confirm and name. Disagreements between lenses (unused entry point, never-written data, tests of removed behavior) are stakeholder questions.

| Evidence | Candidate model |
|---|---|
| Persisted insert/update/delete/status change | past-tense event (several writes may be one decision — ask) |
| Person-triggered write | screen → command |
| Person-triggered read | screen + read model |
| Job / listener / inbound external call | automation + command; external fact → todo list → translation → internal fact |
| Outbound external call | event-fed todo list → automation calling out → command recording outcome (`ConfirmationMailSent`, `PaymentFailed`) |
| Query/join | read model fed by the facts behind its data |
| Data read but never written locally | reference data from outside — ask its origin, never invent a creation event |

- **Chapters are user journeys, not endpoints/CRUD**. First map all chapters at high level; the stakeholder chooses which to detail; detail one chapter per pass, whole trigger-to-outcome.
- **Layers**: 0 — chapters and milestone slices only; 1 — actual command/event/view sequence, identifying + critical fields, one example per key element, happy path + 1–2 significant rules, screens only at decision points; 2+ — subflows, alternates, automations, full field sets, realistic examples, tested errors. **"Deeper never means more technical"** — it means more business decisions, rules, failure modes. Scenarios come only from business rules, not type validation.
- Ask only what sources can't settle (event order, unclear requirements), one question at a time with a best hypothesis. Stakeholder answers outrank code; record overrides.
- **Decision provenance**: record every derivation (construct → element, order, vocabulary translation, override, merge/split, omission, reference-data origin, assumption) in a per-chapter decisions lane: decision, elements, why, precise source reference, confirmed by (code / person / assumed). An unresolved *assumed* decision also gets an open question on its element. Keep an append-only chapter log (date, analysed revision, layer, scope, result).
- **Re-analysis** analyses only changed evidence — provided the previous baseline is trustworthy. An unavailable/untrustworthy prior revision or unrecorded modifications since require a broader or full re-analysis. Record a history row even for no-change checks.

### 14.3 From an existing UI (journey discovery)

- Systematically capture key journeys, not every page combination (default cap ~15 screens). Priority: primary navigation → primary calls to action → forms filled with plausible data and submitted → resulting state transitions.
- Per screen: what it shows, how the user got there, primary actions expressed as **intent** ("user can confirm the order"), not button labels.
- A navigation change or major content change (modal, submission result) is a new screen; cosmetic changes are not. Capture meaningful before/after states (empty vs. filled cart). By default skip external links, logout/destructive actions, admin areas, repeats and spinners — unless explicitly part of the requested journey.
- Group a linear journey as one chapter (3–12 screens); then add domain events and map actions to commands.

### 14.4 Detecting drift between model and implementation

- Compare intended model with implemented behavior per slice (matched by normalised business name). Without implementation or a defensible mapping, report "not comparable" — never fabricate.
- Apply the requested scope (model / context / chapter / slice) to **both** sides: implementation outside the scoped slices is not an "implementation-only slice"; report what was excluded.
- Exclude generated infrastructure identifiers, envelopes, helpers, and routes where no screen is intended; respect intentionally screenless internal slices.
- Existing structural model problems are not drift; report them separately.
- Report each underlying difference **once at its origin**, following the chain (a rename propagated command → event → view is one finding).

| Comparison | Finding |
|---|---|
| Model slice Done/Review with no implementation | Missing implementation (Created/Planned absence is expected) |
| Implemented workflow with no modeled slice | Implementation-only slice |
| Fields | one-sided, renamed, typo, type, identity, optional vs. required mismatch |
| Specifications | scenario without test; tested behavior without scenario; obsolete facts |
| Screens | modeled without counterpart; bound to elements absent from the model |
| Relationships | command → event, event → projection, view → screen, event → automation → command differences |

| Evidence | Reconciliation |
|---|---|
| Implementation changed, model equals prior snapshot | Update the model |
| Model changed, implementation equals prior snapshot | Rebuild implementation; reset slice to Planned |
| Both changed / no snapshot | Show both options; recommend the more specific side |
| Implementation-only slice | Model it and make the slice explicit |
| Done slice without implementation | Correct status to Planned |

Obvious typos and plainly wrong flags are fixed on the correct side directly. Diagnosis is read-only until the stakeholder selects fixes.

---

## 15. From Model to Software

This section keeps only the model-level invariants that govern how a model is turned into software; implementation mechanics are deliberately out of scope.

### 15.1 The model is the source of truth

- All fields, command/event names, business rules, filters and read-model shapes come **exclusively** from the slice definition, its descriptions and comments. "If a field is not in the model, it is not in the code." Never invent fields, events, mappings, filters, defaults or constraints.
- Read the **full** slice definition (fields, specifications, comments, context) before building; a summary is not proof a slice is empty.
- The screen mockup is the design: translate it 1:1, invent nothing, drop nothing. Same-titled screens across slices compose one page; a highlighted region on a shared screen copy is that slice's part of the page.
- If a derived artifact (spec, doc, generated requirement) is wrong, **the event model is wrong — fix it on the model**, never patch the derivative.
- Default for ambiguity: the most sensible interpretation supported by slice, specifications and surrounding model — record the assumption. Treat a slice as blocked only when nothing meaningful can be built (no elements/fields at all, contradictory requirements), and ask a specific question naming the slice, field/rule/scenario and what is missing.

### 15.2 Slice invariants

- **State change**: the command is checked against state **reconstructed from prior facts** about its subject — never against a read model. If its preconditions hold, it records new events; if they don't, it is **rejected and nothing is recorded**. Only rules traceable to the model are enforced. The subject's identity comes from the command's identity attributes (two co-equal identities ⇒ compound identity; a child with its own lifecycle is its own subject). Creation commands require the subject not to exist yet; follow-up commands require it to exist.
- **Decision state follows the scenarios, not the event shape**: the state a command needs is exactly the facts its scenarios branch on ("given no prior X / given already X" ⇒ whether X happened; a branch on a value ⇒ that value). The set of prior facts a rule considers is **a property of the rule** (§10.7).
- **State view**: projects every declared event into the modeled shape — nothing missed, nothing extra, no unmodeled filters or fields. It **never** handles commands or records events. A read model belongs to its slice; never reuse another slice's read model because the data looks similar.
- **Automation**: reacts to its trigger events (via its todo list) and issues its modeled command, which is then subject to that command's own rules exactly as if a person had issued it — it never records the target's events directly. Invent no trigger conditions or field mappings. Data missing from the trigger comes from the automation's own todo list/read model; one trigger may lead to several commands.
- **Translation**: external facts enter the domain **only through a translation chain** (§7) that records an internal event in the domain's language; a command issued from a screen is a user entry point, a command issued by an automation is not.
- **Events**: reuse existing event definitions; consumers require the events they consume to exist; an event's identity is its stable domain name.
- **Slices interact only via events.** Dependencies are stated as events consumed (§4.4).

### 15.3 Duplicate triggers

A trigger may be delivered more than once, so every automation must behave correctly when it reacts twice to the same fact. Prefer letting the **target command's own precondition** reject the duplicate (creation rejects "already exists"; an already-done rule rejects a repeat); if the command has no such rule, give it a stable business identity so a genuine duplicate is recognised. Treat only that specific "already handled" rejection as success — never ignore failures in general. Every automation has an idempotency scenario (same trigger twice). Translations are idempotent by external reference (§7.5).

### 15.4 Specifications must be executable

- **Every specification has an executable equivalent**; specifications are the primary acceptance source. "A slice is not complete if specifications are missing or can't be executed."

| Slice | Given | When | Then |
|---|---|---|---|
| State change | prior events (empty = creation) | command | exact events in order, or the specific rejection |
| State view | events, in order (none = empty result) | — | the complete expected result |
| Automation | setup events first, trigger last | — | command issued, or nothing |

- Automation cases to cover: condition met → command; not met → none; duplicate trigger → harmless; with lookup data: only matching entries, and only entries that existed when the trigger occurred.

**Storyline-derived checks** (supplementary; never fabricate a storyline):

- *Command beat*: given = all preceding event beats; when = the command beat; then = the immediately following event beats.
- *Two read-model beats with only events between*: given = all event beats from the start through those events; then = the later read-model beat (fields, examples, or explicit empty list).
- *Event beat followed by a command beat*: automation check.
- Screen or untraceable beats: skip deliberately — don't fabricate expectations.

### 15.5 Definition of Done per slice

- Behavior matches the complete definition; command/event/read-model fields agree exactly with the model; every specification is executable and passes; assumptions are recorded.
- A Done slice returning to Planned is re-checked **field by field** against the model (it may contain only new specifications) — never dismissed as "already implemented".
- Published contracts derive from the model only: exact fields and types, required vs. optional, modeled examples (never invented), modeled rejection outcomes, actual result shape.

### 15.6 Bridging to other specification/work-planning processes

- One section per slice, in timeline (chronological) order — that order is the intended build sequence.
- Primary user story: walk slices narrating screen → command → event → read model.
- Acceptance scenarios: one per specification, **verbatim**. Edge cases: rejection/negative/boundary specs.
- Functional requirements: one per command and per automation. Non-functional requirements only from explicit notes — never fabricated; an automation implying an unstated timing constraint is surfaced as a missing threshold.
- Quality gate: slices with empty specifications or TODO/TBD descriptions are gaps to surface, not skip.
- **One slice = exactly one work package** — never split, never merged. Too big? Split the slice on the model. Dependencies derive from event flow (consumer of an event depends on its producer).

---

## 16. Planning and Estimation

- **Flat cost curve**: explicit event contracts let each workflow step be built without effort rising because other workflows exist (traditional rising cost is attributed to coupling and debt). Illustration: traditional features 2w/2p → 4w/3p → 8w/5p; contract-based ≈ 2w/2p each.
- **Parallel development against contracts**: `CreateOrder` guarantees the `OrderCreated` schema, so `ConfirmOrder` can be built immediately against representative prerequisite events; `AuthorizePayment` against `OrderConfirmed`. State views can be built independently (their data appears once upstream events exist).
- **Estimate in workflow steps (slices), not story points.** Velocity = workflow steps completed per sprint (from history). Estimate = total steps ÷ velocity. Example: nine steps at ~3/sprint ≈ 3 sprints.
- Organisation velocity = sum of independent teams' velocities (3 + 2 + 3 = 8 steps/sprint).
- Complexity varies (illustrative: typical step ≈ 1 week/1 dev; complex ≈ 2 weeks; simple projection ≈ ½ week) — let empirical velocity absorb it (e.g. 2.5 steps/sprint ⇒ 9 steps ≈ 3.6 sprints).
- **Anti-patterns**: equal points for differently-sized features (count their steps); counting meetings/testing/deployment as steps (budget separately); dividing steps by teams without dependency analysis (identify parallel vs. dependent groups).
- **Metrics**: velocity (steps/sprint); step complexity (actual time ÷ one week); parallelisation rate (teams on independent steps ÷ total teams); estimation accuracy (planned ÷ completed). Retrospect on blocked integration (e.g. "C couldn't start until B was integrated → integrate earlier").
- Chain: scope → count steps → historical velocity → estimate → deliver. (Speed-up and accuracy figures in the sources are illustrative claims, not guarantees.)

---

## 17. Worked Reference Examples

### 17.1 Order lifecycle (design record)

| Command | Issuer | Inputs | Preconditions | Success | Rejections |
|---|---|---|---|---|---|
| CreateOrder | Customer (Order Entry screen) | customerId, items[] (productId, quantity), shippingAddress (street, city, state, zip) | stream does not exist; customer exists; items non-empty; quantities > 0; address complete | `OrderCreated` | Customer not found · Items invalid · Address incomplete |
| ConfirmOrder | Customer | orderId (context), paymentMethod (card \| transfer), conditional paymentDetails | `OrderCreated` exists; status Draft; method supported | `OrderConfirmed` | Order not found · Already confirmed · Method not supported |
| AuthorizePayment | Payment Gateway (processor) | orderId, paymentId, authorizationCode | order Confirmed; code valid | `PaymentAuthorized` | — |
| ShipOrder | Fulfilment | orderId, shipmentId | inventory reserved; payment authorized | `OrderShipped` | — |
| CancelOrder | Customer | orderId, reason | not delivered (policy-dependent) | `OrderCancelled` | Cannot cancel delivered order |

State machine: ∅ —CreateOrder→ Draft; Draft —ConfirmOrder→ Confirmed; Draft —CancelOrder→ Cancelled; Confirmed —ShipOrder→ Shipped (terminal in the minimal example); Confirmed → Draft invalid.

Lifecycle: `OrderCreated → OrderConfirmed → PaymentAuthorized → InventoryReserved → OrderShipped → DeliveryConfirmed`; alternatives: cancellation after creation; `PaymentFailed` → cancellation/refund.

### 17.2 Bike reservation (field lineage)

- **Reserve a Bike** screen: bikeId, stationId, startTime, endTime → `ReserveBike.*` (examples bike-17, stn-03, 09:00–17:00 on 2026-06-01); bikeCategory from `AvailableBikeView.category`; rate from `AvailableBikeView.ratePerMinute`.
- **ReserveBike** command: customerId ← `session:customerId`; bikeId, stationId, startTime, endTime ← user input.
- **BikeReserved** event: copies the command values; reservationId and reservedAt are **generated** (documented derivations).
- **ActiveReservationView**: reservationId, customerId, bikeId, stationId ← `BikeReserved`; expiresAt ← `ReservationConfirmed.expiresAt`; status ← `latest:ReservationConfirmed.status`.
- **Reservation Confirmed** screen: values from `ActiveReservationView`; estimated cost `derived:durationHours × ratePerMinute × 60`.

### 17.3 Payment translation

External "payment succeeded" (opaque reference, amount 15,000 cents, currency, external customer ref, status, time) → extract reference → recover `orderId` via `OrderPaymentReference` (or echoed order id) → verify order exists and is Confirmed → record `PaymentAuthorized`(orderId, paymentAmount 150.00, paymentCurrency, timestamp, paymentGatewayRef for dedup). Unknown reference → failure + manual review, no event. Order not Confirmed → failure, no event. Same fact at 10:00 and 10:05 → second does nothing.

### 17.4 Guest leaves hotel (enrichment)

External geofence exit (user id, area id, timestamp, lat/long) → require tracking consent, guest checked in, area = hotel front entrance → enrich guest name and room from our guest history; ignore coordinates → record `GuestLeftHotel`(guestId, timestamp). No consent / not checked in / unknown area → no event.

### 17.5 Library reservation (worker or not?)

- *Worker needed*: external reservation request → translate to internal request → worker checks copy availability (new invariant) → `ReserveCopy` → `CopyReserved`.
- *Worker redundant*: external `ReservationPlaced` already carries reservationId, copyId, memberId — upstream already chose the copy. Translate to internal `ReservationPlaced` and stop; a "reserved copies" view projects directly from it.

### 17.6 Order slices derived

Timeline: `PlaceOrder → OrderPlaced`, `ConfirmOrder → OrderConfirmed`, `AuthorizePayment → PaymentAuthorized`, `OrderDetailView` (from OrderPlaced, OrderConfirmed), `PaymentStatusView` (from PaymentAuthorized), `ReserveInventoryOnPayment` (consumes PaymentAuthorized, issues ReserveInventory). → Six slices: three state-change, two state-view, one automation. No combined "Order Management" slice. Dependencies stated as events consumed.

### 17.7 Commerce Role Catalog

| Role | Description | Can | Cannot |
|---|---|---|---|
| Customer | browses, buys, tracks | create/confirm/cancel order, submit review | manage inventory, refund, respond as seller |
| Seller | lists and fulfils | list products, confirm stock, respond to reviews, set prices | place orders, approve own reviews, process payments |
| Support Agent | escalations, overrides | override order status, refund, flag reviews | place orders for customers (unless impersonation allowed) |
| Payment Gateway (external) | payment facts | authorization, failure, refund confirmation | — |
| Inventory System (internal) | stock | reserve, release | — |

### 17.8 Tender (bidder perspective) chapters

1 Intake & Go/No-Go · 2 Clarification · 3 Bid Preparation · 4 Submission · 5 Evaluation & Award · 6 Contract & Delivery. Rule example: late submission → `SubmitBid` rejected given `SubmissionDeadlineReached` ("Late bid is rejected"). Adapt, don't force as a template.

### 17.9 Observed model size (one library round)

One chapter "Catalogue Management": 13 events, 11 commands, 3 automations, 15 read models, 13 screens, 55 scenarios/storylines, 26 slices; verdict PASS. Observations, not targets.

---

## Appendix A — Master Checklists

### A.1 Element & naming
- [ ] Events past tense, specific business facts, 2–4 words, no CRUD/UI/technical/calculated events
- [ ] Commands imperative business intent, not queries/UI actions
- [ ] Read models named for data; screens named as users would; automations named for what they do
- [ ] No implementation names in titles

### A.2 Structure
- [ ] One event per column; ≤1 screen per column; ≤1 of each command/read model/screen/automation per column
- [ ] All connections forward (except todo-list closing events)
- [ ] Every command: exactly one issuer, one catalog actor, same column as issuer and event
- [ ] Every read model: ≥1 source event, ≥1 consumer, placed upstream of/at its consumer
- [ ] Every automation: own todo list one column before it; workers only opened by internal events; translation lists never closed
- [ ] External facts in their own swimlane as single-column handovers; translated before domain work
- [ ] Reused elements are linked copies; originals never deleted
- [ ] Later updates to screen-fed views use forward linked copies + matching screens
- [ ] One actor lane per human role; automations in a shared lane; extra event swimlanes only for other systems
- [ ] No unplaced elements

### A.3 Data
- [ ] Every command/read-model/screen field has a mapping to a connected source
- [ ] Every command input reaches event data; every event field from command or documented derivation
- [ ] Cardinality explicit; list-shaped read models marked
- [ ] Examples realistic and consistent across chains

### A.4 Behavior
- [ ] Seven scenario types reviewed for every command; inapplicable ones justified
- [ ] ≥1 view spec per read model (incl. todo lists); storyline vs. GWT decided per read model
- [ ] Rejections as error scenarios with reasons; open questions only for truly undecided matters
- [ ] Preconditions and invalid transitions explicit

### A.5 Readiness
- [ ] Completeness: no unresolved traceability gaps
- [ ] Validation verdict PASS (or PASS WITH WARNINGS with criticals resolved); both final questions YES
- [ ] Slices explicit for every principal element; chapter reasoning notes written

---

## Appendix B — Glossary

| Term | Definition |
|---|---|
| Event | Immutable past-tense business fact |
| Command | Rejectable business intent issued by one screen or automation |
| Read model | Event-derived projection for one query; rebuildable |
| Screen | What a human sees and acts on |
| Automation / processor | Automated actor: todo list → decide → command |
| Todo list | List-shaped read model of pending work items; membership = open |
| Translation automation | Converts an external fact into an internal fact; its todo list is never closed |
| Worker automation | Makes a real business decision; opened by internal events, closed by completion events |
| Chapter / timeline | One coherent story/process, read left to right |
| Context | Bounded context grouping chapters |
| Lane | Row: actor, interaction, event swimlane, specification, notes |
| Column | One moment in time; one event max |
| Slice | One command, one read model or one automation — independently deployable |
| State change / state view / automation / translation | The four slice patterns |
| Linked copy | Reuse of the same command/event/read model elsewhere; no own slice |
| GWT | Given (events) / When (command) / Then (events, read model, or error) |
| Storyline | Ordered beats narrating one lifecycle across states |
| Hotspot | Red note marking a pain point / dispute — not an event |
| Role Catalog | Named human roles and system actors with can/cannot boundaries |
| Field lineage / mapping | Declared source of a field's value |
| Bed / left chair / right chair / shelf | Internal names for structural shapes (§12.1) |
| Modeling Mode / Critic Mode | Build vs. review posture — never mixed |

---

## Appendix C — Known Tensions in the Sources

The repository's sources disagree in places. The main text follows the operative rule; these remain open:

1. **Calculated values in events.** Core rules forbid computed event fields, yet several worked examples store an order `total` computed at creation in `OrderCreated`. The sources do not explicitly distinguish a value fixed at decision time from a continuously recalculated aggregate. *Operative*: never put values that recalculate as data changes into events; treat decision-time totals as an unresolved question for your domain.
2. **Errors as events vs. rejection without events.** Discovery asks "what event signals a rule violation?", while commands reject with no event. *Operative* (§2.2): a refused command → no event + error scenario; a failure that is itself a business fact (payment declined, reservation failed) → failure event. The sources give no universal test for which case applies; decide with the domain expert.
3. **"Automations are only triggered by internal events" vs. translation.** Reconciled as: worker automations only by internal events; translation automations are the single exception.
4. **Translation as "always-succeeding relay with no decision"** vs. translation guidance requiring validation, preconditions, correlation failures and manual review. Both are kept: the chain shape has no business decision, but the translation still validates and may fail.
5. **"No leakage of external ids"** vs. keeping `paymentGatewayRef` on the event. *Operative*: external ids may be carried as dedup/reconciliation references, never as primary identity.
6. **Fan-in thresholds.** Right chair and the split-first heuristic use *more than three* events; the structural checklist flags *three or more*. Left chair is *more than two* events; checklist says *two or more*.
7. **Read models "optional"** vs. mandatory for roles, view screens, non-blank input screens and automations.
8. **Four lanes per column** vs. multiple actor lanes (one per role) and a second event swimlane.
9. **Concurrent business facts** vs. one event per column — no explicit concurrency notation.
10. **Query in a state-view When** — one source allows an inline query; the formal rule says When is empty.
11. **Given contains events only** vs. workshop examples using prose state ("customer exists").
12. **Compensation examples** (event in When, command + event in Then) violate the formal one-command grammar; they illustrate lifecycle, not specification form.
13. **Slice naming** — exact element title vs. automation slices named after their command; one example names a `CreateOrder` slice "Place Order".
14. **Slice timing** — completeness (Step 8) checks slices, but slicing is Step 10.
15. **PASS vs. PASS WITH WARNINGS** as the readiness gate; "critical issues resolved" vs. "documented as known limitations".
16. **Checklist count** — described as 12 or 13 checks in six or seven phases; the enumeration has 14 items in seven phases.
17. **Read-only commands** are mentioned once as permissible but nowhere given placement/slice rules.
18. **Event field naming** — camelCase in the model vs. a snake_case request for row examples.
19. **Storyline policy** — mandatory for lifecycle read models in document-driven modeling, only on request in code reverse-engineering.
20. **Wireframes vs. rendered mockups** — rendered by default; some deeper-layer guidance suggests sketches where decisions need them.
21. **Commandless notification processors** appear in one ownership example ("info-only") despite the universal todo list → automation → command → event shape.
22. **Cross-system examples without translation** — ownership examples show other systems' events directly triggering worker commands; treat them as high-level flow summaries, not complete automation patterns.
23. **Planning arithmetic** — some illustrative planning tables don't add up; numbers are illustrations only.
24. **Chapter sequencing** — the full orchestration plots all timelines before storyboarding; document-driven modeling completes one chapter end to end before starting the next.
25. **One command per screen vs. "one command per screen/processor action".** The design workflow says one command per *action*, which could suggest several actions on one screen; core rules always flag a screen wired to several commands. *Operative*: one screen (state) → one command; several actions mean several screen states.
