# ADR 0004: Encode Native Workflows and Event Modeling Practice

## Status

Accepted for the v0.2.0-rc.1 release candidate.

## Context

The v0.2 language established context-owned contracts but retained transitional
constructs such as `event_ref`, `field_ref`, string relationship lists, and the
generic `specification` shape. Those constructs duplicated information HCL can
express through block kinds and traversals. They also failed to preserve useful
workshop information from the Event Modeling cheat sheet: explicit translation,
the question answered by a read model, actors, ownership, chapters, hotspots,
and scenario targets.

Some Event Modeling advice is objective enough to validate, while visual
anti-patterns such as bed, left chair, right chair, and shelf require domain
judgment. Treating every heuristic as an error would make exploratory modeling
unnecessarily rigid.

## Decision

- Use unquoted, typed HCL traversals for every resolvable relationship.
- Derive event participation from flow and scenario references; remove
  `event_ref`.
- Use one `field` block whose `type` is either a built-in string or a
  `field_type` traversal; remove `field_ref`.
- Use workflow-local `scenario` blocks with typed Given/When/Then targets.
- Require each read model to state its `question`.
- Add `translation` as a first-class workflow kind. It must consume an event
  from an external bounded context; internal automation must not.
- Declare actors, teams, and systems once and reference them from screens or
  ownership attributes.
- Preserve durable workshop structure with `chapter` and `hotspot` blocks.
- Use source order for workflow and scenario order and lower-snake-case labels
  for traversable identities.
- Enforce structural, reference, typing, and pattern rules as errors. Report
  judgment-dependent modeling smells and commands without a visible reason as
  warnings.

## Consequences

- Relationships are concise, navigable, target-kind checked, and cannot become
  stale copies of titles or kinds.
- Workflows read closer to the four Event Modeling patterns and retain enough
  information for diagrams and automated review.
- Local element IDs can be reused in separate workflows; top-level hotspots use
  a workflow-qualified element address when targeting one.
- Models written for v0.1 require migration because the transitional reference
  and specification constructs are rejected.
- The warning set is intentionally conservative. It highlights review points
  without claiming that a shape is wrong for every domain.
