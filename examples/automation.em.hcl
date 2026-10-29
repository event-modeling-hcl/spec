# An internal appointment fact causes a processor to request a notification.

board {
  workflows = [
    workflow.request_appointment_notification,
  ]
}

bounded_context "appointments" {
  title = "Appointments"

  event "appointment_added" {
    title = "Appointment Added"
  }
}

bounded_context "notifications" {
  title = "Notifications"

  event "appointment_notification_requested" {
    title = "Appointment Notification Requested"
  }
}

automation "request_appointment_notification" {
  title = "Request Appointment Notification"

  processor "notification_processor" {
    title = "Notification Processor"
    from  = [event.appointments.appointment_added]
    to    = [command.request_notification]
  }

  command "request_notification" {
    title = "Request Notification"
    to    = [event.notifications.appointment_notification_requested]
  }

  scenario "notification_is_requested" {
    title = "Notification Is Requested"

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
