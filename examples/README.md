# Examples

Every `.em.hcl` file here is a complete document that validates independently
with the v0.3.0 CLI. Read the smallest pattern examples first, then use the
appointment/weather model to see patterns composed in one domain.

| File | Pattern | Demonstrates |
| --- | --- | --- |
| `state-change.em.hcl` | State Change | Screen to command to event. |
| `state-view.em.hcl` | State View | Event to read model to screen, with a Given/Then scenario. |
| `automation.em.hcl` | Automation | Internal event to processor to command to event. |
| `translation.em.hcl` | Translation | External event translated into an internal event. |
| `appointment-weather.em.hcl` | Combined | Appointment scheduling, calendar views, weather automation, and external translation. |

Format and validate any example with:

```text
eventmodeling-hcl fmt -w examples/<name>.em.hcl
eventmodeling-hcl validate examples/<name>.em.hcl
```
