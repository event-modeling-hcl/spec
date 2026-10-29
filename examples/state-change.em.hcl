# A user submits an appointment request and an appointment becomes a fact.

board {
  workflows = [
    workflow.schedule_appointment,
  ]
}

actor "scheduler" {
  title         = "Scheduler"
  auth_required = true
}

bounded_context "appointments" {
  title = "Appointments"

  aggregate "appointment" {
    title = "Appointment"
  }

  field_type "appointment_id" {
    type         = "UUID"
    id_attribute = true
  }

  field_type "requested_time" {
    type = "DateTime"
  }

  event "appointment_added" {
    title     = "Appointment Added"
    aggregate = aggregate.appointment

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "requested_time" {
      type = field_type.appointments.requested_time
    }
  }
}

state_change "schedule_appointment" {
  title = "Schedule Appointment"

  screen "schedule_appointment" {
    title  = "Schedule Appointment"
    actor  = actor.scheduler
    fields = [field_type.appointments.requested_time]
    to     = [command.add_appointment]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }
  }

  command "add_appointment" {
    title     = "Add Appointment"
    aggregate = aggregate.appointments.appointment
    to        = [event.appointments.appointment_added]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "requested_time" {
      type = field_type.appointments.requested_time
    }
  }

  scenario "appointment_is_scheduled" {
    title = "Appointment Is Scheduled"

    when {
      command = command.add_appointment
    }

    then {
      event = event.appointments.appointment_added
    }
  }
}
