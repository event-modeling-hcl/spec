# Migrating to v0.5.0

v0.5.0 is a breaking revision. It gives each authoring concern its own control.
A `board` block sets the story order. Chapters only group workflows. Every field
states its type. Titles are never derived. File layout has no meaning. The
`translation` keyword merges into `automation`. The validation profile never
decides whether tools receive a model. A v0.4.0 model does not load under v0.5.0
rules, and the loader does not mix revisions. See
[RFC 0004](../rfcs/0004-uncoupled-authoring-controls.md) for the reasons.

## 1. Run the Migrator

`migrate` reads a v0.4.0-valid model, a file or a folder, and rewrites it
without changing its meaning. First run it without `-w`. It prints the result
and changes no file:

```bash
eventmodeling-hcl migrate path/to/model.em.hcl
```

Review the output. When it is correct, run it again with `-w`. It rewrites the
changed files:

```bash
eventmodeling-hcl migrate -w path/to/model.em.hcl
eventmodeling-hcl fmt -w path/to/model.em.hcl
eventmodeling-hcl validate path/to/model.em.hcl
```

For a folder model, give the folder path to `migrate` and `validate`, and run
`fmt -w` on each changed member file.

## 2. What the Migrator Changes

1. It adds one `board` block that lists every workflow in the v0.4.0 effective
   order. The block goes at the start of the file, or at the start of the
   byte-first member file of a folder. No workflow becomes off-board. The
   position of the block has no meaning.
2. It writes the v0.4.0 resolved type of every typeless `field` and `subfield`
   as a qualified traversal, such as `field_type.orders.order_id`.
3. It writes every v0.4.0 derived title as an explicit `title`. Each display
   name stays the same.
4. It keeps chapter lists as written. Their order no longer has meaning.
5. It rewrites every `translation` block as `automation`. The block body does
   not change. The old rules make sure that each former translation keeps at
   least one external edge.

The migrator validates its output under v0.5.0 rules before it prints or
writes anything.

## 3. When the Migrator Stops

The migrator stops with diagnostics and writes nothing in these cases. Fix the
input under v0.4.0 rules, then run it again.

- **The input does not parse or is not v0.4.0-valid.** Fix the reported errors
  with the v0.4.0 tools first.
- **A typeless field is ambiguous.** v0.4.0 could not resolve its type to one
  `field_type`, for example because two bounded contexts declare a field type
  with that name. The migrator never guesses. Add an explicit `type` to that
  field under v0.4.0, then migrate.
- **The model already has a `board` block.** The model is not a v0.4.0 model.
  If a partial migration added the board, remove it and run the migrator on
  the original v0.4.0 model.
- **A workflow breaks the v0.4.0 translation rules.** A `translation` that
  consumes no external event, or an `automation` that consumes one, was
  invalid in v0.4.0 (`EM011`, `EM012`). Fix the keyword or the `external` flag
  under v0.4.0 first.

## 4. Diagnostics That Disappear

These codes are retired. They disappear by design and are never reassigned:

- `EM006`: non-contiguous chapter in a one-file model.
- `EM011`: `translation` without an external input event.
- `EM012`: `automation` with an external input event.
- `EM013`: chapters in several files of a folder model.
- `EM407`: workflow in no chapter of a folder model.

Two new core errors can appear when you edit the model later: `EM015` (no
`board` block, or more than one) and `EM016` (a workflow listed twice on the
board). A field without `type` is `EM009`.

## 5. Behavior Changes to Expect

- **Off-board workflows.** A workflow that you add later and do not list on the
  board is off-board. It is part of the model and passes every rule, but it is
  not in the story sequence. No profile reports it. Add it to `board` when it
  belongs in the story.
- **Chapters are unordered.** A chapter only groups workflows. Its list order,
  its file, and its position never change the story order. Chapters may live in
  any file, and a workflow may be in no chapter without a diagnostic.
- **File layout has no meaning.** Renaming member files or moving whole blocks
  between them does not change the model. Number prefixes on file names are no
  longer needed.
- **The `strict` profile no longer hides diagrams.** Core errors still prevent
  the typed IR in every profile. A judgment signal with error severity, such as
  an open hotspot under `strict`, still makes `validate` fail. But a tool that
  renders or exports still receives the typed IR and reports the policy
  rejection separately.
- **Absent titles.** A block without `title` has no title. The typed model does
  not make one from the label. A tool shows the identity separately.
- **Explicit types.** A new field needs `type`, even when its name matches a
  `field_type`.
- **Translation is an automation.** Write new translations with the
  `automation` keyword. The typed IR marks each edge that starts at an event of
  an external bounded context; tools derive the translation view from those
  marks.

## 6. Manual Cleanup

The migrator keeps every display name, so it writes many titles that only
restate the label, such as `title = "Payment Captured"` on
`event "payment_captured"`. You may delete those titles. A consumer then shows
the identity instead of a title. Keep a title when its wording adds meaning.

You may also move the `board` block, chapters, and other blocks to any file that
reads well. This changes only source locations.

## 7. Example

Before (v0.4.0):

```hcl
bounded_context "payments" {
  external = true

  event "payment_captured" {}
}

bounded_context "orders" {
  field_type "order_id" {
    type = "UUID"
  }

  event "order_confirmed" {
    field "order_id" {}
  }
}

translation "confirm_paid_order" {
  processor "payment_listener" {
    from = [event.payments.payment_captured]
    to   = [command.confirm_order]
  }

  command "confirm_order" {
    to = [event.orders.order_confirmed]

    field "order_id" {}
  }
}

chapter "checkout" {
  workflows = [workflow.confirm_paid_order]
}
```

After `migrate -w` and `fmt -w` (v0.5.0):

```hcl
board {
  workflows = [
    workflow.confirm_paid_order,
  ]
}

bounded_context "payments" {
  title    = "Payments"
  external = true

  event "payment_captured" {
    title = "Payment Captured"
  }
}

bounded_context "orders" {
  title = "Orders"

  field_type "order_id" {
    type = "UUID"
  }

  event "order_confirmed" {
    title = "Order Confirmed"

    field "order_id" {
      type = field_type.orders.order_id
    }
  }
}

automation "confirm_paid_order" {
  title = "Confirm Paid Order"

  processor "payment_listener" {
    title = "Payment Listener"
    from  = [event.payments.payment_captured]
    to    = [command.confirm_order]
  }

  command "confirm_order" {
    title = "Confirm Order"
    to    = [event.orders.order_confirmed]

    field "order_id" {
      type = field_type.orders.order_id
    }
  }
}

chapter "checkout" {
  title     = "Checkout"
  workflows = [workflow.confirm_paid_order]
}
```

After the optional cleanup in section 6, every `title` above can go, because
each one only restates its label.
