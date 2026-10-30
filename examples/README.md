# Examples

Each `.em.hcl` file directly in `examples/` is a complete v0.5.0 model that
validates independently. Each folder is one complete model that validates as a
whole. Read the smallest pattern examples first, then use the
appointment/weather model to see patterns composed in one domain.

| File | Pattern | Demonstrates |
| --- | --- | --- |
| `state-change.em.hcl` | State Change | Screen to command to event. |
| `state-view.em.hcl` | State View | Event to read model to screen, with a Given/Then scenario. |
| `automation.em.hcl` | Automation | Internal event to processor to command to event. |
| `translation.em.hcl` | Translation | An `automation` whose input event belongs to an external context, translated into an internal event. |
| `appointment-weather.em.hcl` | Combined | Appointment scheduling, calendar views, weather automation, and external translation. |
| `appointment-weather-split/` | Folder model | The combined example split into one folder: catalog, board and chapters, and one file per workflow. File names have no meaning; the `board` sets the story order. |

Format and validate any example with:

```text
emhcl fmt -w examples/<name>.em.hcl
emhcl validate examples/<name>.em.hcl
```

A folder is one model. Validate it with `emhcl validate examples/appointment-weather-split/`.
