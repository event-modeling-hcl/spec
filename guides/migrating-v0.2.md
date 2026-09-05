# Migrating to the v0.2.0 Draft

v0.2.0 is a breaking, HCL-native revision. Migrate a model as one complete
document; the validator does not accept old and new syntax together.

## 1. Normalize Identities

Change every labeled identity to lower snake case. Remove duplicated `id`,
`name`, `index`, `spec_row`, and `slice_name` metadata.

## 2. Extract Domain Contracts

Create a `bounded_context` for each domain language. Move events into their
owning context, promote aggregate strings to `aggregate` blocks, and extract
repeated domain fields to `field_type` blocks.

```hcl
bounded_context "clinic" {
  title = "Clinic"
  aggregate "pet" {}
  field_type "pet_id" { type = "UUID" }
  event "pet_registered" {
    title = "Pet Registered"
    field "pet_id" { type = field_type.pet_id }
  }
}
```

Replace `field_ref` with `field`; set `type` to a local or qualified field-type
traversal.

## 3. Replace Generic Slices

Replace `slice` plus `slice_type` with `state_change`, `state_view`, or
`automation`. Use `translation` for an automation that consumes an event from
an external bounded context.

## 4. Replace Relationship Syntax

Remove `event_ref` blocks. Replace string `inbound`/`outbound` lists with typed
`from`/`to` traversal lists on workflow elements. Event participation is
derived from those references.

```hcl
screen "form" {
  title = "Registration form"
  to    = [command.register_pet]
}

command "register_pet" {
  title = "Register pet"
  to    = [event.clinic.pet_registered]
}
```

## 5. Migrate Specifications

Replace `specification` with workflow-local `scenario`. Remove `linked_id` and
step `type`; give each step one typed target. State Views express the event that
establishes the view followed by the read-model result; they do not use `when`
or `query`.

```hcl
scenario "registration_succeeds" {
  title = "Registration succeeds"
  when  { command = command.register_pet }
  then  { event = event.clinic.pet_registered }
}
```

```hcl
state_view "pet_directory" {
  readmodel "pets" {
    question = "Which pets are registered?"
    from     = [event.clinic.pet_registered]
  }

  scenario "pets_are_listed" {
    given { event = event.clinic.pet_registered }
    then  { readmodel = readmodel.pets }
  }
}
```

State Views require one or more event `given` steps, no `when`, and one or
more `then` steps.

## 6. Canonicalize Flow

Write each edge once in its v0.2 canonical form. The source element uses `to`;
catalog events remain sources through the receiving element's `from`.

```hcl
# Do not retain these v0.1 reverse forms.
command "register_pet" { from = [screen.form] }
screen "summary" { from = [readmodel.pets] }
processor "notify" { from = [readmodel.pending] }
command "send" { from = [processor.notify] }

# Write the canonical forms instead.
screen "form" { to = [command.register_pet] }
readmodel "pets" { to = [screen.summary] }
readmodel "pending" { to = [processor.notify] }
processor "notify" { to = [command.send] }
```

## 7. Omit Derivable Titles

When a label is sufficient, remove the matching `title`; the typed model derives
the human title. Keep explicit titles for intentional wording or capitalization.

```hcl
event "pet_registered" {}
```

## 8. Add Practice Metadata

- Add `question` to every read model.
- Give every command an incoming flow, `api_endpoint`, or
  `external_trigger = true`.
- Declare actors once and reference them from screens.
- Add team/system ownership, contiguous chapters, and hotspots where they
  preserve useful workshop decisions.

## 9. Format and Validate

Run the validator after each workflow is migrated:

```bash
eventmodeling-hcl validate path/to/model.em.hcl
eventmodeling-hcl fmt -w path/to/model.em.hcl
eventmodeling-hcl validate --profile strict path/to/model.em.hcl
```

Errors identify invalid syntax or model invariants. Warnings identify review
points and do not make the command fail.
