# An appointment fact establishes a calendar read model for a calendar user.

board {
  workflows = [
    workflow.view_calendar,
  ]
}

actor "calendar_user" {
  title         = "Calendar User"
  auth_required = true
}

bounded_context "appointments" {
  title = "Appointments"

  event "appointment_added" {
    title = "Appointment Added"
  }
}

state_view "view_calendar" {
  title = "View Calendar"

  readmodel "calendar" {
    title    = "Calendar"
    question = "Which appointments are on the calendar?"
    from     = [event.appointments.appointment_added]
    to       = [screen.calendar]
  }

  screen "calendar" {
    title = "Calendar"
    actor = actor.calendar_user
  }

  scenario "calendar_shows_appointment" {
    title = "Calendar Shows Appointment"

    given {
      event = event.appointments.appointment_added
    }

    then {
      readmodel = readmodel.calendar
    }
  }
}
