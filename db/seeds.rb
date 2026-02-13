# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed de niveles de cliente
levels_data = [
  { name: "Cliente", priority: 1 },
  { name: "Cliente VIP", priority: 2 },
  { name: "Distribuidor", priority: 3 },
  { name: "Distrib VIP", priority: 4 },
  { name: "Constructor del Éxito", priority: 5 },
  { name: "Mayorista", priority: 6 }
]

levels_data.each do |level_attrs|
  level = Level.find_or_initialize_by(name: level_attrs[:name])
  level.priority = level_attrs[:priority]
  level.save!
end

puts "✅ Niveles creados exitosamente: #{Level.count} niveles"
