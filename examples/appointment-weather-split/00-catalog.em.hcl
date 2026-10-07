actor "scheduler" {
  title         = "Scheduler"
  auth_required = true
}

actor "calendar_user" {
  title         = "Calendar user"
  auth_required = true
}

system "weather_provider" {
  title    = "Weather provider"
  external = true
}

bounded_context "appointments" {
  title = "Appointments"

  aggregate "appointment" {
  }

  field_type "appointment_id" {
    type         = "UUID"
    id_attribute = true
  }

  field_type "starts_at" {
    type = "DateTime"
  }

  event "appointment_added" {
    title     = "Appointment Added"
    aggregate = aggregate.appointment

    field "appointment_id" {
      type = field_type.appointment_id
    }

    field "starts_at" {
      type = field_type.starts_at
    }
  }
}

bounded_context "weather" {
  title = "Weather"

  aggregate "weather_forecast" {
  }

  field_type "forecast" {
    type = "String"
  }

  field_type "changed_at" {
    type = "DateTime"
  }

  event "weather_predicted_for_appointment" {
    title     = "Weather predicted for appointment"
    aggregate = aggregate.weather_forecast

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.forecast
    }
  }

  event "updated_weather_prediction" {
    title     = "Updated Weather Prediction"
    aggregate = aggregate.weather_forecast

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.forecast
    }
  }
}

bounded_context "weather_provider" {
  title    = "Weather Provider"
  owner    = system.weather_provider
  external = true

  event "weather_forecast_changed" {
    title = "Weather Forecast Changed"

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.weather.forecast
    }

    field "changed_at" {
      type = field_type.weather.changed_at
    }
  }
}
