# An appointment fact establishes a calendar read model for a calendar user.

actor "calendar_user" {
  auth_required = true
}

bounded_context "appointments" {
  event "appointment_added" {
  }
}

state_view "view_calendar" {
  readmodel "calendar" {
    question = "Which appointments are on the calendar?"
    from     = [event.appointments.appointment_added]
    to       = [screen.calendar]
  }

  screen "calendar" {
    actor = actor.calendar_user
  }

  scenario "calendar_shows_appointment" {
    given {
      event = event.appointments.appointment_added
    }

    then {
      readmodel = readmodel.calendar
    }
  }
}
