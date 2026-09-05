# An internal appointment fact causes a processor to request a notification.

bounded_context "appointments" {
  event "appointment_added" {
  }
}

bounded_context "notifications" {
  event "appointment_notification_requested" {
  }
}

automation "request_appointment_notification" {
  processor "notification_processor" {
    from = [event.appointments.appointment_added]
    to   = [command.request_notification]
  }

  command "request_notification" {
    to = [event.notifications.appointment_notification_requested]
  }

  scenario "notification_is_requested" {
    given {
      event = event.appointments.appointment_added
    }

    when {
      processor = processor.notification_processor
    }

    then {
      event = event.notifications.appointment_notification_requested
    }
  }
}
