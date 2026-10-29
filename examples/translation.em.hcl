# An external provider's weather fact is translated into an internal contract.

board {
  workflows = [
    workflow.translate_weather_forecast,
  ]
}

system "weather_provider" {
  title    = "Weather Provider"
  external = true
}

bounded_context "weather_provider" {
  title    = "Weather Provider"
  owner    = system.weather_provider
  external = true

  event "weather_forecast_changed" {
    title = "Weather Forecast Changed"
  }
}

bounded_context "weather" {
  title = "Weather"

  event "weather_prediction_updated" {
    title = "Weather Prediction Updated"
  }
}

automation "translate_weather_forecast" {
  title = "Translate Weather Forecast"

  processor "weather_translator" {
    title = "Weather Translator"
    from  = [event.weather_provider.weather_forecast_changed]
    to    = [command.update_weather_prediction]
  }

  command "update_weather_prediction" {
    title = "Update Weather Prediction"
    to    = [event.weather.weather_prediction_updated]
  }

  scenario "weather_change_is_translated" {
    title = "Weather Change Is Translated"

    given {
      event = event.weather_provider.weather_forecast_changed
    }

    when {
      processor = processor.weather_translator
    }

    then {
      event = event.weather.weather_prediction_updated
    }
  }
}
