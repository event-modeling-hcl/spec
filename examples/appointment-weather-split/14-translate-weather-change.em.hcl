translation "translate_weather_change" {
  title = "Translate Changed Weather"

  readmodel "changed_predictions" {
    title    = "Changed Predictions"
    question = "Which external weather predictions changed?"
    from     = [event.weather_provider.weather_forecast_changed]
    to       = [processor.translator]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.weather.forecast
    }
  }

  processor "translator" {
    title = "Translator"
    to    = [command.translate_changed_weather]
  }

  command "translate_changed_weather" {
    title     = "Translate Changed Weather"
    aggregate = aggregate.weather.weather_forecast
    to        = [event.weather.updated_weather_prediction]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.weather.forecast
    }
  }
}
