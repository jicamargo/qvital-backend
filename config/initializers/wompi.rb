# En producción el backend no arranca si Wompi está mal configurado, en vez de
# caer en silencio en los valores de sandbox (ver Wompi::Config).
Rails.application.config.after_initialize do
  next unless Rails.env.production?

  problems = Wompi::Config.production_problems
  raise "Configuración de Wompi incompleta: #{problems.join('; ')}" if problems.any?
end
