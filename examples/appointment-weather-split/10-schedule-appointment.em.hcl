state_change "schedule_appointment" {
  title = "Schedule Appointment"

  screen "schedule_appointment_ui" {
    title = "UI"
    actor = actor.scheduler
    to    = [command.add_appointment]
  }

  screen "post_appointment" {
    title = "POST /appointment"
    to    = [command.add_appointment]
  }

  command "add_appointment" {
    title     = "Add Appointment"
    aggregate = aggregate.appointments.appointment
    to        = [event.appointments.appointment_added]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "starts_at" {
      type = field_type.appointments.starts_at
    }
  }
}
