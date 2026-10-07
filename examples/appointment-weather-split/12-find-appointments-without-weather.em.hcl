state_view "find_appointments_without_weather" {
  title = "Appointments without weather forecast"

  readmodel "appointments_without_weather_forecast" {
    title    = "Appointments without weather forecast"
    question = "Which appointments do not have a weather forecast?"
    from     = [event.appointments.appointment_added]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "starts_at" {
      type = field_type.appointments.starts_at
    }
  }
}
