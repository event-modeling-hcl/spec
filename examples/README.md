# Examples

Each `.em.hcl` file directly in `examples/` is a complete document that validates
independently. Each folder is one complete model that validates as a whole. Read the
smallest pattern examples first, then use the appointment/weather model to see patterns
composed in one domain.

| File | Pattern | Demonstrates |
| --- | --- | --- |
| `state-change.em.hcl` | State Change | Screen to command to event. |
| `state-view.em.hcl` | State View | Event to read model to screen, with a Given/Then scenario. |
| `automation.em.hcl` | Automation | Internal event to processor to command to event. |
| `translation.em.hcl` | Translation | External event translated into an internal event. |
| `appointment-weather.em.hcl` | Combined | Appointment scheduling, calendar views, weather automation, and external translation. |
| `appointment-weather-split/` | Multi-file model | The combined example split into one folder: catalog, chapters, and one file per workflow. |

Format and validate any example with:

```text
eventmodeling-hcl fmt -w examples/<name>.em.hcl
eventmodeling-hcl validate examples/<name>.em.hcl
```

A folder is one model. Validate it with `eventmodeling-hcl validate examples/appointment-weather-split/`.
