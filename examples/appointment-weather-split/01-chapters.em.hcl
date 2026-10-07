chapter "scheduling" {
  title     = "Scheduling"
  workflows = [workflow.schedule_appointment, workflow.view_calendar, workflow.find_appointments_without_weather]
}

chapter "weather" {
  title     = "Weather"
  workflows = [workflow.add_weather_forecast, workflow.translate_weather_change]
}
