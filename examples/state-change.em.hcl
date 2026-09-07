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

  field_type "requested_time" {
    type = "DateTime"
  }

  event "appointment_added" {
    aggregate = aggregate.appointment

    field "appointment_id" {
    }

    field "requested_time" {
    }
  }
}

state_change "schedule_appointment" {
  screen "schedule_appointment" {
    actor  = actor.scheduler
    fields = [field_type.appointments.requested_time]
    to     = [command.add_appointment]

    field "appointment_id" {
    }
  }

  command "add_appointment" {
    aggregate = aggregate.appointments.appointment
    to        = [event.appointments.appointment_added]

    field "appointment_id" {
    }

    field "requested_time" {
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
