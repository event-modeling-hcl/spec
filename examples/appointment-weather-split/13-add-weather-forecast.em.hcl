automation "add_weather_forecast" {
  title = "Add Weather Forecast"

  readmodel "appointments_without_weather_forecast_feed" {
    title    = "Appointments without weather forecast feed"
    question = "Which appointments still need a weather forecast?"
    from     = [event.appointments.appointment_added]
    to       = [processor.weather_processor]
  }

  processor "weather_processor" {
    title = "Weather Processor"
    to    = [command.add_weather_forecast_command]
  }

  command "add_weather_forecast_command" {
    title     = "Add Weather Forecast"
    aggregate = aggregate.weather.weather_forecast
    to        = [event.weather.weather_predicted_for_appointment]

    field "appointment_id" {
      type = field_type.appointments.appointment_id
    }

    field "forecast" {
      type = field_type.weather.forecast
    }
  }
}
