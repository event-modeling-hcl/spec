# RFC 0003: Hotspot Resolution

## Status

Proposed. Not part of Specification v0.4.0. The current implementation accepts
hotspot `status`, but does not accept `resolution`.

## 1. Summary and Motivation

Hotspots already support `status = "open"` and `status = "resolved"`.
The specification states the values but does not explain the omitted value.
The implementation treats an omitted status as open.

A status tells readers whether a question still needs attention. It does not
record the answer. Deleting a resolved hotspot loses the question and its
attachment. Putting its answer in `description` mixes background with the
outcome.

Add an optional `resolution` string for the latest recorded answer or decision.
Keep `status` as the sole authority for whether the hotspot is open.
This is a decision record, not a task tracker or a complete decision history.

## 2. Proposed Normative Language Changes

A `hotspot` retains its required `question` and existing optional `description`,
`on`, and `status` attributes. It gains optional `resolution`.

- `status` is a literal string: `"open"` or `"resolved"`. Omission means open.
- `resolution` is a literal string containing the latest recorded answer or
  decision. If present, it must contain at least one non-whitespace character.
- `resolution` is optional for both statuses. It never supplies or changes status.
- A resolved hotspot without a resolution remains valid. Authors are encouraged
  to record the answer, but its absence produces no new diagnostic.
- An open hotspot can retain a resolution after a question is reopened. In that
  case the text records the previous decision, not proof that the question is
  closed. Consumers must show that the hotspot is open.
- Reopening changes `status` to `"open"`; it does not require deleting the previous
  resolution. An author can explain why it was reopened in `description`.
- `description` remains background, context, or reasoning about the question.
  `resolution` records its answer or decision. Neither is executable model logic.
- The hotspot ID, question, and attachment survive resolution and reopening.
  No workflow, event, scenario, or reference changes as a side effect.

Consumers must not infer status from the presence, absence, or wording of
`resolution`. A consumer that displays a resolution must also distinguish an
open question from a resolved question.

## 3. Compatibility and Migration

This is an additive proposal. Every v0.4.0 model remains valid and retains its
meaning, including a resolved hotspot without an answer. No migration is
required for existing models.

An older implementation rejects `resolution` as unknown syntax. Authors need an
implementation of the future specification revision before using the field.
This RFC does not assign a release version or change the current language version.

Authors can move an answer from `description` into `resolution` when adopting
this field. Tools must not perform that move automatically: prose does not
reliably separate background from an answer.

## 4. Validation, Formatter, and Typed-IR Impact

### Validation

Add `resolution` to the hotspot attribute schema. Validate it as a literal string
and reject an empty or whitespace-only value with the existing applicable
attribute diagnostic. Do not allocate a new diagnostic code just for this field.

Keep `EM406` controlled only by effective status. An omitted or open status still
produces the open-hotspot diagnostic, even with a resolution. A resolved status
produces no `EM406`, even without a resolution. Profile severity stays unchanged.

### Formatter

Keep the existing relative order: `description`, `status`, `question`, then `on`.
Place `resolution` after `question` and before `on` in the semantic group.
Preserve its text under the existing string-formatting rules. Do not insert an
omitted status or resolution into source. Formatting stays idempotent.

### Typed IR and Consumers

The hotspot record owns the optional resolution string. Validation rejects blank
values, so absence remains distinguishable from a recorded answer. Loaders and
serializers preserve the value without interpreting it.

Status determines open-hotspot counts and diagnostics. Resolution supplies text
for hotspot details. It does not change causal edges, workflow status, chapter
membership, or event contracts. Downstream formats without a decision-record
field follow their existing loss-reporting policy; do not invent an event for it.

Implementation acceptance requires matching schema, validator, formatter, IR,
consumer, and regression-test changes. These changes are outside this
specification-only proposal.

## 5. Examples and Acceptance Tests

The following snippets demonstrate the proposal. They are not current v0.4.0
examples and are not supported by the current CLI.

### Record an answer

```hcl
hotspot "notification_channel" {
  description = "Clinic staff need a single agreed channel."
  status      = "resolved"
  question    = "Which channel sends appointment reminders?"
  resolution  = "Send reminders by email. SMS is outside this model."
}
```

### Reopen without losing the previous decision

```hcl
hotspot "notification_channel" {
  description = "Reopened because the clinic now requires SMS support."
  status      = "open"
  question    = "Which channel sends appointment reminders?"
  resolution  = "Send reminders by email. SMS is outside this model."
}
```

The second example remains an open hotspot and receives `EM406`. Its resolution
is the previous decision under review.

| Source condition | Required result |
| --- | --- |
| No status and no resolution | Valid syntax; effectively open; `EM406` applies. |
| `status = "open"`, no resolution | Open; `EM406` applies. |
| `status = "resolved"`, no resolution | Valid; no `EM406`; old models keep their meaning. |
| `status = "resolved"`, nonblank resolution | Valid; preserve and display the answer; no `EM406`. |
| `status = "open"`, nonblank resolution | Valid; preserve the previous decision; `EM406` still applies. |
| No status, nonblank resolution | Effectively open; resolution must not suppress `EM406`. |
| Empty or whitespace-only resolution | Attribute error, independent of status. |
| Non-string or nonliteral resolution | Attribute error under the existing literal-string rules. |
| Any status other than open or resolved | Existing enum-validation error. |
| Change only resolution text | Counts, diagnostics, workflow behavior, and attachment stay unchanged. |
| Resolve and reopen the same hotspot | ID, question, attachment, and resolution survive. |
| Format twice and reload | Identical second formatting output; resolution value survives. |

Apply the `EM406` cases under every profile: informational in `workshop`, warning
in `valid`, and error in `strict`. Include an old resolved-without-answer model
in compatibility tests.

## 6. Alternatives and Axiomatic Design Analysis

### Needs, Requirements, and Controls

The analysis covers the hotspot branch, not the whole language. The proposed
criteria below are design targets, not measured user-research results.

| Need | Functional requirement and acceptance criterion | Design parameter |
| --- | --- | --- |
| N1: Identify questions needing attention | FR1: Classify open versus resolved without reading answer prose; classification drives `EM406`. | DP1: Explicit two-value status, with omitted status treated as open. |
| N2: Preserve the answer for future readers | FR2: Retain a separately identifiable decision through wording edits, resolution, and reopening. | DP2: Optional resolution text, stored independently of status. |

Constraints: existing models stay valid; the question remains required; source
remains the authority; the design adds no executable business behavior or task
management lifecycle.

### Independence Axiom

Entries represent the material influence of changing a control on an outcome,
with the hotspot ID, question, and attachment held fixed.

| Functional requirement | DP1: Status | DP2: Resolution text |
| --- | --- | --- |
| FR1: Classify outstanding questions | X | 0 |
| FR2: Preserve a separately identifiable decision | 0 | X |

This mapping is locally uncoupled. Changing the answer does not close a question.
Changing status does not erase or require an answer. These are justified zeros
only if validation permits a resolution in either state and consumers never
infer closure from its text.

A rule that requires an answer when resolving creates an off-diagonal influence:
DP2 also controls whether FR1 can reach its resolved state. That design is
locally decoupled when the answer is written before status is changed, not
inherently invalid. However, it violates the compatibility constraint for
existing resolved hotspots without answers.

Inferring status from a nonempty resolution also makes answer edits change
closure. It cannot represent a reopened question while retaining its previous
answer. It therefore fails the proposed FR2 acceptance criterion.

Cross-boundary checks: the validator owns acceptance and `EM406`; the hotspot IR
owns stored state; consumers combine status and answer for display. Their
composition is an S junction: combine independently controlled outcomes. There
is no new update sequence or feedback loop. Profile policy still controls
severity, not status. This local matrix does not prove whole-system independence.

### Alternatives

| Alternative | Assessment against the same requirements |
| --- | --- |
| Status only | Already supported. Meets FR1, but does not give FR2 a dedicated answer record. |
| Put the answer in description | No new syntax, but readers and tools cannot distinguish context from the answer reliably. |
| Infer status from resolution | Reject. Editing or retaining an answer controls closure and prevents the reopening case. |
| Require resolution for resolved status | Stronger answer completeness, but breaks old models. Consider only with an explicit future migration requirement. |
| Permit resolution only when resolved | Reject for this scope. Reopening forces deletion or relocation of the previous answer. |
| Optional resolution independent of status | Recommended. Meets both criteria and preserves existing models. UI labeling must make reopening clear. |
| Structured decision log with authors and dates | Supports a fuller audit trail, but adds identities, ordering, and lifecycle rules not required here. Version control retains source history. |

### Information Axiom and Evidence Limits

There are no measured joint success probabilities for these alternatives.
Do not assign a numerical information score or treat fewer fields as lower
information content. The recommendation is provisional on usability evidence.

The main residual risk is that a reader mistakes the previous answer on an open
hotspot for the current accepted decision. Test the closed and reopened examples
with domain reviewers. Ask which question still needs attention and what answer
was previously agreed. Compare status-only, description-based, and separate-field
presentations against the same questions. Measure correct identification of both
outcomes together before claiming an information-axiom advantage.

No extra status values, answer inference, mandatory provenance, or automatic
business-model updates are proposed. Acceptance and a release version remain
language-governance decisions.
