# A user submits an appointment request and an appointment becomes a fact.

actor "scheduler" {
  auth_required = true
}

bounded_context "appointments" {
  aggregate "appointment" {
  }

  field_type "appointment_id" {
    type         = "UUID"
    id_attribute = true
  }

  event "appointment_added" {
    aggregate = aggregate.appointment

    field "appointment_id" {
      type = field_type.appointment_id
    }
  }
}

state_change "schedule_appointment" {
  screen "schedule_appointment" {
    actor = actor.scheduler
    to    = [command.add_appointment]
  }

  command "add_appointment" {
    aggregate = aggregate.appointments.appointment
    to        = [event.appointments.appointment_added]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }
  }

  scenario "appointment_is_scheduled" {
    when {
      command = command.add_appointment
    }

    then {
      event = event.appointments.appointment_added
    }
  }
}
