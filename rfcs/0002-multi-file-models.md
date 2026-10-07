# RFC 0002: Multi-file Models

## Status

Accepted for v0.4.0.

## 1. Summary and Motivation

A large model does not fit well in one file. A clinic with ten bounded
contexts and fifty workflows becomes a file of several thousand lines. People
cannot find things, and two people editing the model collide in the same file.

This RFC lets a model be a folder of `.em.hcl` files, like a Terraform module.
The folder is the model. There are no `include` or `import` blocks. Every file
adds its top-level blocks to one shared model. IDs and references stay global,
so a workflow in one file can use a bounded context from another file.

Nothing changes for one-file models. Every v0.3.0 document stays valid and
means the same thing.

The design rests on these decisions:

- A folder is the model. There are no include blocks.
- Only files directly in the folder count. Subfolders are ignored.
- A block never spans files. A bounded context lives in one file.
- One model per folder. There are no modules and no name spaces.
- Chapters set the board order. All chapters live in one file.
- A workflow outside every chapter gets a warning.
- The CLI commands that read a model accept a file or a folder. `fmt` accepts
  one file.

## 2. Proposed Normative Language Changes

The rules are numbered R1 to R15. Tests and implementation notes refer to
them by number.

### 2.1 Which files make a model

**R1. Model path.** A path to a file is a one-file model, exactly as in v0.3.0.
A path to a folder is a folder model.

**R2. Folder members.** A folder model uses every regular file directly in the
folder whose name ends in `.em.hcl` and does not start with `.`. A symlink to a
file counts. Subfolders and all other files are ignored.

**R3. File order.** Member files are sorted by file name, byte by byte. The
sort does not use the locale. Model order is file order, then source order
inside each file.

**R4. Empty folder.** A folder with no member file is error `EM001`. The
summary is `Failed to read model`. The detail is `folder <path> has no .em.hcl
files`.

**R5. One-file rule.** A folder with exactly one member file behaves exactly
like that file. Rules R8 to R11 apply only when a model has two or more files.

### 2.2 How files merge

**R6. Merge.** The model is the union of all top-level blocks of all files.
Every reference resolves across files. Every v0.3.0 check runs on the whole
model. Each file must parse on its own. A syntax error in one file is reported
with the name of that file, and the model is invalid.

**R7. Identity.** The same top-level ID in two files is error `EM002`. The
ID spaces are the same as in v0.3.0: one space for each catalog kind and one
space shared by all workflow kinds. The detail names the first declaration as
`file:line:column`. The same detail is used for a duplicate inside one file.

A block never spans files. A `bounded_context` with its events, aggregates, and
field types must be in one file. Two files cannot each add events to the same
context, because the second declaration is a duplicate ID.

### 2.3 Board order and chapters

A multi-file model has no single source order, so the board order needs its
own rule. Chapters give that order. Rules R8 to R11 apply only to models with
two or more files.

**R8. Chapters in one file.** If chapter blocks appear in two or more files, the
model has error `EM013` (`Chapters in several files`). It is reported at each
chapter outside the first file that declares a chapter.

**R9. One chapter per workflow.** A workflow listed by two chapters is error
`EM014` (`Workflow in several chapters`). It is reported on the later chapter.

**R10. Chapter order.** The workflow order is the order of the chapters in their
file, then the order of each chapter's `workflows` list. The v0.3.0 `EM006`
contiguous source-order check does not apply to multi-file models.

**R11. Unchaptered workflows.** A workflow in no chapter is warning `EM407`
(`Workflow outside every chapter`). It goes after all chaptered workflows, in
model order (R3). The profiles map the diagnostic like this:

| Profile | Severity of `EM407` |
| --- | --- |
| `workshop` | info |
| `valid` | warning |
| `strict` | error |

A multi-file model with no chapters at all gets `EM407` on every workflow. The
workflows follow file name order. Renaming a file can move only unchaptered
workflows. This is why the diagnostic exists.

### 2.4 Typed IR, diagnostics, and formatting

**R12. Typed IR.** `Workflows` follows the R10 and R11 order for multi-file
models and source order for one-file models. Catalog items, chapters, and
hotspots follow model order (R3). Downstream output follows `Workflows`. This
covers the diagram slice order and the export slice index.

**R13. Diagnostics.** Every diagnostic that points at source names its own
file. The CLI prints `file:line:column: Severity EMxxx: Summary: Detail`. A file
name prints as the folder path joined with the file name.

**R14. Formatting stays per file.** `fmt` formats one file. It never moves
blocks between files.

### 2.5 Non-goals

**R15. Not in v0.4.0.** This version does not define:

- `include` or `import` blocks.
- Subfolders as part of a model.
- Modules or name spaces.
- Splitting one block across files.
- Multi-file `import` output. `import` still writes one file.
- A multi-file browser playground.

### 2.6 Command line

`validate`, `diagram`, `serve`, and `export` accept a path to a `.em.hcl` file
or to a folder. Any other path is the error `model path must be a .em.hcl file
or a folder`. `fmt` accepts one `.em.hcl` file. A folder gives the error `fmt
formats one .em.hcl file at a time`.

Grammar:

```text
model_path = file_path '.em.hcl' | folder_path
```

The document grammar is unchanged. The model is the concatenation of the
documents of the member files in R3 order.

## 3. Compatibility and Migration

Nothing breaks. A path to a file means what it meant in v0.3.0. A folder
with one member file means the same as that file (R5). The new codes `EM013`,
`EM014`, and `EM407` can only appear in models with two or more files, so no
v0.3.0 document can gain them.

The only change to existing behavior is the error text for a path that is not a
`.em.hcl` file or a folder. This is a message change, not a language change.

To split an existing model, move whole top-level blocks into new files in the
same folder. Keep every chapter in one file. Then run `validate` on the folder.
The result must be the same as before, apart from `EM407` for any workflow that
no chapter lists. To keep the old board order, list every workflow in a chapter.

## 4. Validation, Formatter, and Typed-IR Impact

**Validation.**

- `EM001` is also used for an empty folder (R4).
- `EM002` detail now names the first declaration with `file:line:column` (R7).
- `EM006` runs only for one-file models (R10).
- New structural error `EM013` for chapters in several files (R8).
- New structural error `EM014` for a workflow in several chapters (R9).
- New judgment diagnostic `EM407` for a workflow outside every chapter (R11).
  It is info in `workshop`, a warning in `valid`, and an error in `strict`.
- Syntax errors name the file they come from (R6, R13).

**Formatter.** No change to the canonical form. `fmt` formats one file at a
time (R14). A folder path is an error.

**Typed IR.** No shape change. The order of `Workflows`, catalog items,
chapters, and hotspots follows R12. Tools that read the IR do not need to know
that the model came from a folder.

## 5. Examples and Acceptance Tests

### 5.1 A clinic folder

```text
clinic/
  catalog.em.hcl
  chapters.em.hcl
  directory.em.hcl
  register.em.hcl
```

`catalog.em.hcl` holds one bounded context and one actor:

```hcl
actor "clinic_staff" {
  auth_required = true
}

bounded_context "clinic" {
  aggregate "pet" {
  }

  field_type "pet_id" {
    type         = "UUID"
    id_attribute = true
  }

  event "pet_registered" {
    aggregate = aggregate.pet

    field "pet_id" {
    }
  }
}
```

`chapters.em.hcl` holds the only chapter. It lists workflows from two other
files:

```hcl
chapter "pet_registration" {
  workflows = [
    workflow.register_pet,
    workflow.pet_directory,
  ]
}
```

`register.em.hcl` holds a workflow that uses the context from `catalog.em.hcl`:

```hcl
state_change "register_pet" {
  screen "register_pet" {
    actor = actor.clinic_staff
    to    = [command.register_pet]

    field "pet_id" {
    }
  }

  command "register_pet" {
    aggregate = aggregate.clinic.pet
    to        = [event.clinic.pet_registered]

    field "pet_id" {
    }
  }

  scenario "pet_is_registered" {
    when {
      command = command.register_pet
    }

    then {
      event = event.clinic.pet_registered
    }
  }
}
```

`directory.em.hcl` holds a second workflow:

```hcl
state_view "pet_directory" {
  readmodel "pets" {
    question = "Which pets are registered?"
    from     = [event.clinic.pet_registered]
    to       = [screen.pet_list]
  }

  screen "pet_list" {
    actor = actor.clinic_staff
  }

  scenario "pets_are_listed" {
    given {
      event = event.clinic.pet_registered
    }

    then {
      readmodel = readmodel.pets
    }
  }
}
```

The command line:

```text
eventmodeling-hcl validate clinic/
```

The files sort as `catalog`, `chapters`, `directory`, `register`. The chapter
sets the workflow order to `register_pet`, then `pet_directory`. File name
order does not matter here, because both workflows are in the chapter. If the
chapter listed only `register_pet`, then `pet_directory` would follow it and
`directory.em.hcl` would get `EM407`.

### 5.2 Acceptance tests

Each rule has at least one test. Unless a test says otherwise, the model has
two or more files.

| Rule | Test | Expected result |
| --- | --- | --- |
| R1 | Validate a path to one `.em.hcl` file. | Same result as v0.3.0. |
| R1 | Validate a path to a folder. | The folder is read as one model. |
| R2 | Folder holds `a.em.hcl`, `.b.em.hcl`, `c.txt`, and `sub/d.em.hcl`. | Only `a.em.hcl` is used. |
| R2 | Folder holds a symlink to a `.em.hcl` file. | The linked file is used. |
| R3 | Files `b.em.hcl` and `B.em.hcl` with unchaptered workflows. | `B.em.hcl` comes first (byte order). |
| R4 | Validate a folder with no `.em.hcl` file. | `EM001`, detail `folder <path> has no .em.hcl files`. |
| R5 | Folder with one file that has non-contiguous chapters. | `EM006`, same as the file alone. |
| R6 | A workflow in one file uses a context from another file. | No reference error. |
| R6 | One file has a syntax error. | Error names that file. The model is invalid. |
| R7 | Two files declare `bounded_context "clinic"`. | `EM002` on the second, detail names `file:line:column` of the first. |
| R7 | One file declares the same workflow ID twice. | `EM002`, detail names the first line. |
| R8 | Chapters in two files. | `EM013` on each chapter outside the first file. |
| R9 | Two chapters list the same workflow. | `EM014` on the later chapter. |
| R10 | Chapter lists workflows in non-contiguous order across files. | No `EM006`. Workflow order follows the chapter list. |
| R11 | A workflow is in no chapter. | `EM407` warning. The workflow follows all chaptered workflows. |
| R11 | Same model with `--profile workshop` and `--profile strict`. | Info, then error. |
| R11 | Multi-file model with no chapter. | `EM407` on every workflow, in file order. |
| R12 | Export a multi-file model. | Slice index follows the R10 and R11 order. |
| R12 | Export a one-file model. | Slice index follows source order. |
| R13 | Error in the second of three files. | Output line starts with `<folder>/<file>:line:column:`. |
| R14 | Run `fmt` on one file of a folder. | Only that file changes. |
| R14 | Run `fmt` on a folder path. | Error `fmt formats one .em.hcl file at a time`. |
| R15 | Put a model file in a subfolder. | The file is ignored (R2). |

## 6. Alternatives and Unresolved Questions

**Alternatives**

- *Explicit `include` blocks.* Not chosen. A folder is the model, like a
  Terraform module. A list of includes is a second place to keep in sync with
  the files on disk, and a forgotten entry would silently drop a file.
- *Subfolders.* Not chosen. Only files directly in the folder count. A recursive
  walk needs a rule for order across folders, and the simple byte sort of one
  folder is easy to explain. Subfolders can hold notes, images, or old copies
  without changing the model.
- *Root-file order.* Not chosen. A root file that lists the order of the other
  files is an include list in disguise. Chapters already set the board order.
- *An `order` attribute on workflows.* Not chosen. It would repeat what a chapter
  already says and force people to renumber after an insert. Chapters set the
  order, and file name order covers the rest.
- *Splitting one context across files.* Not chosen. A block never spans files.
  A context with its events, aggregates, and field types must be readable in
  one place, and the same ID in two files is then always a mistake.
- *Modules with name spaces.* Not chosen. One model per folder keeps IDs
  global, so every reference form from v0.3.0 stays valid. Modules would need
  new reference syntax and a migration for every existing document.

**Open questions**

- Should a later version let `import` write one file per bounded context?
- Should a later version let a folder choose its board order without a chapter,
  for example through a file that lists the order?
- Should `fmt` accept a folder and format every member file?
