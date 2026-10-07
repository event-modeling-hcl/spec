state_view "view_calendar" {
  title = "View Calendar"

  readmodel "calendar" {
    title    = "Calendar"
    question = "Which appointments are on the calendar?"
    from     = [event.appointments.appointment_added]
    to       = [screen.calendar_ui, screen.get_calendar]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "starts_at" {
      type = field_type.appointments.starts_at
    }
  }

  screen "calendar_ui" {
    title = "UI"
    actor = actor.calendar_user
  }

  screen "get_calendar" {
    title = "GET /calendar"
  }
}
