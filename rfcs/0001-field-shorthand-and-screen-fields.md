# RFC 0001: Field Shorthand and Screen Fields

## Status

Proposed.

## 1. Summary and Motivation

Writing fields by hand is repetitive. Most fields have the same name as their
field type, so you write the name twice:

```hcl
field "student_id" { type = field_type.student_id }
field "name"       { type = field_type.name }
```

Also, a `screen` collects and shows data, but the spec only mentions `field`
blocks on events. The validator already accepts fields on any workflow element;
it just isn't written down, so nobody uses it.

This RFC lets you drop the repeated `type`, adds a one-line list form for
several fields at once, and says plainly that screens and other elements can
carry fields. Every existing document stays valid.

## 2. Proposed Normative Language Changes

### 2.1 `type` becomes optional on a `field` block

If a `field` block has no `type`, its type is the field type with the same
name:

```hcl
field "student_id" {}           # same as type = field_type.student_id
field "name" { pii = true }      # you can still set other attributes
```

Which field type it means:

- A field inside an `event` or a `subfield` uses its own bounded context.
- A field on a workflow element (`command`, `readmodel`, `screen`,
  `processor`), a `table`, or a scenario step uses the field type of that name
  from whichever context defines it. If no context defines it, or more than
  one does, that is an error — write the `type` yourself.

You still need an explicit `type` when the field name and the field-type name
differ:

```hcl
field "student" { type = field_type.person_id }
```

A `field_type` declaration still needs a real built-in type. Only `field`
blocks get the shorthand.

### 2.2 A `fields` list

To add several plain fields at once, list their field types:

```hcl
fields = [field_type.clinic.student_id, field_type.clinic.name]
```

Each entry becomes one field named after the last part of the reference. Use a
`field` block instead when you need `id_attribute`, `example`, `cardinality`,
and so on.

If an element has both a `fields` list and `field` blocks, the list fields come
first (in list order), then the blocks (in source order). A name cannot appear
in both.

### 2.3 Fields on screens and other elements

`screen`, `command`, `readmodel`, `processor`, `table`, and scenario steps take
`field` blocks and a `fields` list, exactly like an `event`. A screen has no
context of its own, so its shorthand fields resolve by unique name (2.1).

Grammar:

```text
field_list = 'fields' '=' '[' field_type_ref { ',' field_type_ref } ']'
```

## 3. Compatibility and Migration

Nothing breaks. Making `type` optional cannot invalidate a document that
already has it. `fields` is new and optional. Element fields already worked.
There is no migration step; adopt the shorthand whenever you like.

## 4. Validation, Formatter, and Typed-IR Impact

**Validation.** Reuses existing codes — no new ones:

- `field_type` with no type — `EM009`.
- Typeless `field` whose name matches no field type — `EM009`.
- Typeless `field` on an element whose name matches field types in two
  contexts — `EM009` (write an explicit `type`).
- A `fields` entry that does not resolve — `EM101`/`EM102`.
- The same field name in a `fields` list and a `field` block — `EM002`.

**Formatter.** `fields` sorts with the semantic attributes, just before `from`
and `to`. Empty `field` blocks and `fields` lists are left as written; `fmt`
never expands them. Output stays idempotent.

**Typed IR.** No shape change. A shorthand field gets the same `Type` string an
explicit `type` would produce, so nothing downstream can tell them apart. List
fields decode like block fields. Element fields already land in
`Element.Fields`.

## 5. Examples and Acceptance Tests

### 5.1 Shorthand in an event

```hcl
bounded_context "course_subscriptions" {
  field_type "student_id" { type = "String" id_attribute = true }
  field_type "name"       { type = "String" }

  event "student_registered" {
    field "student_id" {}
    field "name" {}
  }
}
```

Both fields resolve to `field_type.course_subscriptions.<name>`.

### 5.2 Shorthand and list form on a screen

```hcl
bounded_context "clinic" {
  field_type "pet_id"   { type = "UUID" id_attribute = true }
  field_type "pet_name" { type = "String" }
}

state_change "register_pet" {
  screen "pet_screen" {
    actor  = actor.clinic_staff
    fields = [field_type.clinic.pet_name]
    to     = [command.register_pet]

    field "pet_id" {}
  }

  command "register_pet" {
    external_trigger = true
    to               = [event.clinic.pet_registered]
  }
}
```

`pet_screen` has fields `[pet_name, pet_id]`; `pet_id` resolves to
`field_type.clinic.pet_id` and keeps its `id_attribute` badge.

### 5.3 Rejections

- `field_type "pet_id" {}` — `EM009`.
- `field "mystery_id" {}` with no such field type — `EM009`.
- `field "shared_id" {}` when two contexts define `shared_id` — `EM009`.
- `fields = [field_type.clinic.pet_id]` plus `field "pet_id" {}` — `EM002`.

## 6. Alternatives and Unresolved Questions

**Alternatives**

- *Drop `field_type` entirely and infer `String` from the name.* No — that
  throws away the ID, PII, example, and cardinality contract the catalog
  exists for.
- *Resolve element fields through the context of the element's aggregate.*
  No — screens and read models have no aggregate, so the rule would not apply
  everywhere. Unique name is one rule for every element.
- *List form only, no empty block.* No — the block form is needed for
  overrides, and people expect `field "x" {}` to work once `type` is optional.
- *Expand the shorthand on `fmt`.* No — the shorthand is the point; the
  formatter keeps what you wrote, as it already does for derived titles.

**Open questions**

- When a name is defined in both an internal and an `external` context, should
  the internal one win instead of being ambiguous?
- Should `field "x" { pii = true }` be allowed to extend a `fields` entry of
  the same name, rather than being rejected as a duplicate?
- Should `subfield` get the same shorthand, or always stay explicit?
