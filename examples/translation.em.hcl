# An external provider's weather fact is translated into an internal contract.

system "weather_provider" {
  external = true
}

bounded_context "weather_provider" {
  owner    = system.weather_provider
  external = true

  event "weather_forecast_changed" {
  }
}

bounded_context "weather" {
  event "weather_prediction_updated" {
  }
}

translation "translate_weather_forecast" {
  processor "weather_translator" {
    from = [event.weather_provider.weather_forecast_changed]
    to   = [command.update_weather_prediction]
  }

  command "update_weather_prediction" {
    to = [event.weather.weather_prediction_updated]
  }

  scenario "weather_change_is_translated" {
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
